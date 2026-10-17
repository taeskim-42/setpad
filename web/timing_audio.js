(() => {
  let context, beat, tempo, wake, beatStartedAt = 0, cueEndsAt = 0, pendingSpeech;
  // Pitch, partials, length and loudness measured from Tempo's cue recordings
  // (bpm.mp3, prebpm.mp3, end_3s.mp3), so the two apps sound like one.
  const ding = [[1787, 1], [2664, .38], [1010, .29]];
  const TONES = {
    click: { p: [[655, 1], [1965, .1]], s: .12, decay: true, g: .45 },
    ready: { p: [[523, 1], [1568, .25]], s: .08, g: .5 },
    work: { p: [[1046, 1], [3138, .18]], s: .22, g: .5 },
    rest: { p: ding, s: .35, g: .25 },
    complete: { p: ding, s: .7, g: .3 },
  };
  const rendered = new Map(); // buffers are built once and replayed
  const render = (tone, length = tone.s) => {
    const rate = context.sampleRate, buffer = context.createBuffer(1, Math.round(rate * length), rate), out = buffer.getChannelData(0);
    const sounding = Math.round(rate * tone.s), scale = tone.p.reduce((a, [, w]) => a + w, 0);
    for (let i = 0; i < sounding; i++) {
      const t = i / rate, env = tone.decay ? Math.exp(-t / (tone.s / 4)) : Math.min(1, t / .004, (tone.s - t) / .004);
      out[i] = tone.p.reduce((a, [f, w]) => a + Math.sin(t * f * 2 * Math.PI) * w, 0) / scale * env * tone.g;
    }
    return buffer;
  };
  const dropPending = () => { clearTimeout(pendingSpeech); pendingSpeech = null; };
  const cancelSpeech = () => { dropPending(); window.speechSynthesis?.cancel(); };
  const silence = () => { if (beat) { beat.stop(); beat = null; } tempo = null; if (wake) { wake.release(); wake = null; } };
  const stop = () => { cancelSpeech(); silence(); };
  window.setpadTiming = { configure: async (active, bpm, cue, phase = 0) => {
    // Pausing or stopping cuts the voice.
    if (!active && !cue) { stop(); if (context) await context.suspend(); return; }
    context ??= new AudioContext();
    await context.resume();
    // Finishing (the complete cue) stops the click but lets the last number finish.
    if (!active) silence();
    if (bpm !== tempo) {
      // A tempo change while running only drops a count still waiting.
      if (active) dropPending();
      if (beat) { beat.stop(); beat = null; }
      tempo = bpm;
      // The app allows 10 BPM; anything slower than this range is a typo.
      if (active && bpm >= 10 && bpm <= 300) {
        beat = context.createBufferSource(); beat.buffer = render(TONES.click, 60 / bpm); beat.loop = true; beat.connect(context.destination);
        // Start where the timer is inside its beat, not at a fresh click: after a
        // pause or a re-sync the clicks stay on the timer's beat grid.
        const offset = Math.min(Math.max(0, phase || 0), beat.buffer.duration - .001);
        beatStartedAt = context.currentTime - offset; beat.start(context.currentTime, offset);
      }
    }
    if (cue) {
      const source = context.createBufferSource();
      if (!rendered.has(cue)) rendered.set(cue, render(TONES[cue] || TONES.rest));
      source.buffer = rendered.get(cue);
      cueEndsAt = context.currentTime + source.buffer.duration;
      source.connect(context.destination); source.start();
      source.onended = () => source.disconnect();
    }
    if (active && !wake && navigator.wakeLock) { try { wake = await navigator.wakeLock.request('screen'); } catch (_) {} }
  }};
  // Match Tempo: read half a beat after the click, capped at one second.
  setpadTiming.speak = (text, locale, rate) => {
    const speech = window.speechSynthesis;
    if (!context || !text || !speech || speech.speaking || speech.pending || pendingSpeech != null) return;
    const at = context.currentTime;
    // A Tabata with no BPM still announces its rounds, so there may be no beat to wait for.
    const into = beat ? (at - beatStartedAt) % beat.buffer.duration : 0;
    const delay = beat
      ? Math.max(0, Math.min(30 / tempo, 1) - into, cueEndsAt - at)
      : Math.max(0, cueEndsAt - at);
    pendingSpeech = setTimeout(() => {
      pendingSpeech = null;
      if (speech.speaking || speech.pending) return;
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = locale;
      utterance.rate = rate || 1.2;
      speech.speak(utterance);
    }, delay > 0 ? delay * 1000 + 5 : 0);
  };
  document.addEventListener('visibilitychange', () => { if (document.hidden) { stop(); if (context) context.suspend(); } });
  window.addEventListener('pagehide', stop);
})();

