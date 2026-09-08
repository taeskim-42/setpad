(() => {
  let context, beat, tempo, wake;
  const stop = () => { if (beat) { beat.stop(); beat = null; } tempo = null; if (wake) { wake.release(); wake = null; } };
  window.setpadTiming = { configure: async (active, bpm, cue) => {
    if (!active && !cue) { stop(); if (context) await context.suspend(); return; }
    context ??= new AudioContext();
    await context.resume();
    if (!active) stop();
    if (bpm !== tempo) {
      if (beat) { beat.stop(); beat = null; }
      tempo = bpm;
      if (active && bpm >= 20 && bpm <= 300) {
        const rate = context.sampleRate, buffer = context.createBuffer(1, Math.round(rate * 60 / bpm), rate);
        const samples = buffer.getChannelData(0), duration = rate * 0.035;
        for (let i = 0; i < duration; i++) samples[i] = Math.sin(i * 1100 * 2 * Math.PI / rate) * Math.min(1, i / 40) * (1 - i / duration) * 0.3;
        beat = context.createBufferSource(); beat.buffer = buffer; beat.loop = true; beat.connect(context.destination); beat.start();
      }
    }
    if (cue) {
      const oscillator = context.createOscillator(), gain = context.createGain(), at = context.currentTime, length = cue === 'complete' ? 0.4 : 0.1;
      oscillator.frequency.value = cue === 'rest' ? 520 : cue === 'ready' ? 760 : 1320;
      gain.gain.setValueAtTime(0.3, at); gain.gain.exponentialRampToValueAtTime(0.001, at + length);
      oscillator.connect(gain); gain.connect(context.destination); oscillator.start(at); oscillator.stop(at + length);
      oscillator.onended = () => { oscillator.disconnect(); gain.disconnect(); };
    }
    if (active && !wake && navigator.wakeLock) { try { wake = await navigator.wakeLock.request('screen'); } catch (_) {} }
  }};
  document.addEventListener('visibilitychange', () => { if (document.hidden) { stop(); if (context) context.suspend(); } });
  window.addEventListener('pagehide', stop);
})();
