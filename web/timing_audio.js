(() => {
  let context, beat, tempo, wake, beatStartedAt = 0, cueEndsAt = 0, pendingSpeech;
  const cancelSpeech = () => {
    clearTimeout(pendingSpeech); pendingSpeech = null;
    window.speechSynthesis?.cancel();
  };
  const stop = () => { cancelSpeech(); if (beat) { beat.stop(); beat = null; } tempo = null; if (wake) { wake.release(); wake = null; } };
  window.setpadTiming = { configure: async (active, bpm, cue) => {
    if (!active && !cue) { stop(); if (context) await context.suspend(); return; }
    context ??= new AudioContext();
    await context.resume();
    if (!active) stop();
    if (bpm !== tempo) {
      cancelSpeech();
      if (beat) { beat.stop(); beat = null; }
      tempo = bpm;
      if (active && bpm >= 20 && bpm <= 300) {
        const rate = context.sampleRate, buffer = context.createBuffer(1, Math.round(rate * 60 / bpm), rate);
        const samples = buffer.getChannelData(0), duration = rate * 0.035;
        for (let i = 0; i < duration; i++) samples[i] = Math.sin(i * 1100 * 2 * Math.PI / rate) * Math.min(1, i / 40) * (1 - i / duration) * 0.3;
        beat = context.createBufferSource(); beat.buffer = buffer; beat.loop = true; beat.connect(context.destination); beatStartedAt = context.currentTime; beat.start(beatStartedAt);
      }
    }
    if (cue) {
      const oscillator = context.createOscillator(), gain = context.createGain(), at = context.currentTime, length = cue === 'complete' ? 0.5 : cue === 'ready' ? 0.1 : 0.35;
      cueEndsAt = at + length;
      oscillator.frequency.value = cue === 'rest' ? 520 : cue === 'ready' ? 760 : 1320;
      gain.gain.setValueAtTime(0.3, at); gain.gain.exponentialRampToValueAtTime(0.001, at + length);
      oscillator.connect(gain); gain.connect(context.destination); oscillator.start(at); oscillator.stop(at + length);
      oscillator.onended = () => { oscillator.disconnect(); gain.disconnect(); };
    }
    if (active && !wake && navigator.wakeLock) { try { wake = await navigator.wakeLock.request('screen'); } catch (_) {} }
  }};
  // Match Tempo: read half a beat after the click, capped at one second.
  setpadTiming.speak = (text, locale) => {
    const speech = window.speechSynthesis;
    if (!beat || !text || !speech || speech.speaking || speech.pending || pendingSpeech != null) return;
    const at = context.currentTime;
    const into = (at - beatStartedAt) % beat.buffer.duration;
    const delay = Math.max(0, Math.min(30 / tempo, 1) - into, cueEndsAt - at);
    pendingSpeech = setTimeout(() => {
      pendingSpeech = null;
      if (!beat || speech.speaking || speech.pending) return;
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = locale;
      utterance.rate = 1.2;
      speech.speak(utterance);
    }, delay > 0 ? delay * 1000 + 5 : 0);
  };
  document.addEventListener('visibilitychange', () => { if (document.hidden) { stop(); if (context) context.suspend(); } });
  window.addEventListener('pagehide', stop);
})();

