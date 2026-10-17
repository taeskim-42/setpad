#!/usr/bin/env python3
"""Generates the beat counts "One" .. "One hundred"
(assets/voice/count/en/<m|w>/<n>.m4a) with ElevenLabs in the two voices of
Tempo's spoken cues (healthopia tool/make_voices.py), then trims silence,
normalises loudness and encodes to AAC with afconvert (macOS), the same way.

  python3 tool/make_count_voices.py --dry-run     # count characters
  python3 tool/make_count_voices.py               # everything missing
  python3 tool/make_count_voices.py --lengths     # only rewrite LENGTHS

Existing files are skipped, so a run can be repeated. The API key is read
from ~/.config/elevenlabs/api_key and never printed. --lengths needs no key,
no network and nothing outside the standard library.

Every run ends by writing lib/count_voice_lengths.dart: the length of each
recording as the file declares it (MP4 'mdhd', encoder priming included, so
never shorter than what plays). The engine picks how many counts it can say
from it; test/count_voice_lengths_test.dart keeps it equal to the files.

Silence is not trimmed again here: polish() already cut at -40 dBFS with a
30 ms / 50 ms pad, and measured at -45 dBFS a 15 ms / 40 ms trim would save
6 ms on average and 15 ms at most per file (2026-10-17), not worth a second
lossy AAC encode.
"""
import argparse
import glob
import json
import math
import os
import struct
import subprocess
import sys
import tempfile
import urllib.request
import wave

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'assets', 'voice', 'count', 'en')
PHRASES = os.path.join(ROOT, 'assets', 'voice', 'en')  # Tempo's, read only
LENGTHS = os.path.join(ROOT, 'lib', 'count_voice_lengths.dart')
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
    import numpy as np
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


def mdhd_ms(path):
    """The track length the MP4 'mdhd' box declares, in ms (rounded up)."""
    with open(path, 'rb') as f:
        b = f.read()

    def find(names, i, end):
        while i + 8 <= end:
            size, kind = struct.unpack('>I4s', b[i:i + 8])
            if kind.decode('latin-1') == names[0]:
                return i if len(names) == 1 else find(names[1:], i + 8, i + size)
            i += size
        raise ValueError(f'{path}: no {names[0]}')

    i = find(['moov', 'trak', 'mdia', 'mdhd'], 0, len(b))
    if b[i + 8] == 1:
        scale, length = struct.unpack('>IQ', b[i + 28:i + 40])
    else:
        scale, length = struct.unpack('>II', b[i + 20:i + 28])
    return math.ceil(length * 1000 / scale)


def write_lengths():
    counts = {sex: [mdhd_ms(os.path.join(OUT, sex, f'{n}.m4a')) for n in range(1, 101)]
              for sex in VOICES}
    phrases = {sex: {os.path.basename(p)[:-4]: mdhd_ms(p)
                     for p in sorted(glob.glob(os.path.join(PHRASES, sex, '*.m4a')))}
               for sex in VOICES}
    out = ['// Generated by tool/make_count_voices.py (--lengths). Do not edit.',
           '// test/count_voice_lengths_test.dart checks it against the files.',
           '// dart format off',
           '',
           '/// Length in ms of each recorded count, by voice: [n - 1] is "n" (1..100),',
           '/// as the file declares it (encoder priming included).',
           'const countVoiceMs = <String, List<int>>{']
    for sex, ms in counts.items():
        out.append(f"  '{sex}': [")
        out += ['    ' + ', '.join(map(str, ms[i:i + 10])) + ',' for i in range(0, 100, 10)]
        out.append('  ],')
    out += ['};', '',
            "/// Length in ms of each phrase recording (assets/voice/en), by voice and key.",
            'const phraseVoiceMs = <String, Map<String, int>>{']
    for sex, ms in phrases.items():
        out.append(f"  '{sex}': {{")
        out += [f"    '{k}': {v}," for k, v in ms.items()]
        out.append('  },')
    out.append('};')
    with open(LENGTHS, 'w') as f:
        f.write('\n'.join(out) + '\n')
    print(f'wrote {os.path.relpath(LENGTHS, ROOT)}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--counts', default='1-100', help='e.g. 1-100 or 1,2,21')
    ap.add_argument('--voices', default='m,w')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--lengths', action='store_true',
                    help='only rewrite lib/count_voice_lengths.dart (no API)')
    a = ap.parse_args()
    if a.lengths:
        write_lengths()
        return 0
    lo, _, hi = a.counts.partition('-')
    counts = range(int(lo), int(hi) + 1) if hi else [int(c) for c in a.counts.split(',')]
    jobs = [(sex, n, words(n), os.path.join(OUT, sex, f'{n}.m4a'))
            for sex in a.voices.split(',') for n in counts]
    jobs = [j for j in jobs if not os.path.exists(j[3])]
    chars = sum(len(j[2]) for j in jobs)
    print(f'{len(jobs)} files, {chars} characters')
    if a.dry_run:
        return 0
    if not jobs:
        write_lengths()
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
    write_lengths()
    return 0


if __name__ == '__main__':
    sys.exit(main())
