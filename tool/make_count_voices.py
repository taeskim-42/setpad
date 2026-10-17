#!/usr/bin/env python3
"""Generates the beat counts "One" .. "One hundred"
(assets/voice/count/en/<m|w>/<n>.m4a) with ElevenLabs in the two voices of
Tempo's spoken cues (healthopia tool/make_voices.py), then trims silence,
normalises loudness and encodes to AAC with afconvert (macOS), the same way.

  python3 tool/make_count_voices.py --dry-run     # count characters
  python3 tool/make_count_voices.py               # everything missing

Existing files are skipped, so a run can be repeated. The API key is read
from ~/.config/elevenlabs/api_key and never printed.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import urllib.request
import wave

import numpy as np

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'assets', 'voice', 'count', 'en')
KEY_FILE = os.path.expanduser('~/.config/elevenlabs/api_key')
BASE = 'https://api.elevenlabs.io/v1'
MODEL = 'eleven_v4'
VOICES = {'m': 'TX3LPaxmHKxFdv7VOQHJ',   # Liam
          'w': 'FGY2WhTYpPnrIDTdsKH5'}   # Laura

# A count has to fit inside a beat: no emotion tags and no punctuation (both
# stretch the word), and steadier than Tempo's cues (stability 0.0 there).
VOICE_SETTINGS = {'stability': 0.5, 'similarity_boost': 0.8, 'use_speaker_boost': True}

ONES = ['', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
        'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen',
        'eighteen', 'nineteen']
TENS = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety']


def words(n):
    """1 -> 'One', 21 -> 'Twenty-one', 100 -> 'One hundred'."""
    if n == 100:
        return 'One hundred'
    w = ONES[n] if n < 20 else TENS[n // 10] + (f'-{ONES[n % 10]}' if n % 10 else '')
    return w.capitalize()


def key():
    with open(KEY_FILE) as f:
        return f.read().strip()


def api(path, data=None, accept='application/json'):
    req = urllib.request.Request(BASE + path, data=data, method='POST' if data else 'GET',
                                 headers={'xi-api-key': key(), 'accept': accept,
                                          'content-type': 'application/json'})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def used_chars():
    d = json.loads(api('/user/subscription'))
    return d['character_count'], d['character_limit']


def tts(voice, text, path):
    body = json.dumps({'text': text, 'model_id': MODEL,
                       'voice_settings': VOICE_SETTINGS}).encode()
    with open(path, 'wb') as f:
        f.write(api(f'/text-to-speech/{voice}?output_format=mp3_44100_128', body, 'audio/mpeg'))


def afconvert(src, dst, *args):
    subprocess.run(['afconvert', *args, src, dst], check=True, capture_output=True)


def polish(mp3, m4a):
    """mp3 -> trimmed, normalised AAC. Target: RMS -11 dBFS, peak <= -1.
    The tail after the last loud sample is 0.05 s (0.15 s in Tempo's cues): a
    count that is still playing holds back the next one."""
    with tempfile.TemporaryDirectory() as d:
        raw = os.path.join(d, 'raw.wav')
        afconvert(mp3, raw, '-f', 'WAVE', '-d', 'LEI16@44100', '-c', '1')
        with wave.open(raw) as w:
            sr = w.getframerate()
            x = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2') / 32768.0
        loud = np.flatnonzero(np.abs(x) > 10 ** (-40 / 20))
        if len(loud) == 0:
            raise RuntimeError(f'{mp3}: silent')
        a = max(0, loud[0] - int(0.03 * sr))
        b = min(len(x), loud[-1] + int(0.05 * sr))
        x = x[a:b].copy()
        fade = int(0.01 * sr)
        x[:fade] *= np.linspace(0, 1, fade)
        x[-fade:] *= np.linspace(1, 0, fade)
        rms = np.sqrt(np.mean(x ** 2))
        g = min(10 ** (-11 / 20) / rms, 10 ** (-1 / 20) / np.max(np.abs(x)))
        x = np.clip(x * g, -1, 1)
        cut = os.path.join(d, 'cut.wav')
        with wave.open(cut, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(sr)
            w.writeframes((x * 32767).astype('<i2').tobytes())
        afconvert(cut, m4a, '-f', 'm4af', '-d', 'aac', '-b', '48000')
        return len(x) / sr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--counts', default='1-100', help='e.g. 1-100 or 1,2,21')
    ap.add_argument('--voices', default='m,w')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()
    lo, _, hi = a.counts.partition('-')
    counts = range(int(lo), int(hi) + 1) if hi else [int(c) for c in a.counts.split(',')]
    jobs = [(sex, n, words(n), os.path.join(OUT, sex, f'{n}.m4a'))
            for sex in a.voices.split(',') for n in counts]
    jobs = [j for j in jobs if not os.path.exists(j[3])]
    chars = sum(len(j[2]) for j in jobs)
    print(f'{len(jobs)} files, {chars} characters')
    if a.dry_run or not jobs:
        return 0
    before, limit = used_chars()
    print(f'quota used {before}/{limit} (left {limit - before})')
    if before + chars > limit:
        print('not enough characters left', file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory() as d:
        for i, (sex, n, text, dst) in enumerate(jobs, 1):
            mp3 = os.path.join(d, 'v.mp3')
            tts(VOICES[sex], text, mp3)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            secs = polish(mp3, dst)
            print(f'[{i}/{len(jobs)}] {sex}/{n} "{text}" {secs:.2f}s')
    after, _ = used_chars()
    print(f'spent {after - before} characters, left {limit - after}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
