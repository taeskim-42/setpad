const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const test = require('node:test');

function harness() {
  const timers = new Map(), spoken = [];
  let id = 0;
  class AudioContext {
    currentTime = 0;
    sampleRate = 22050;
    async resume() {}
    async suspend() {}
    createBuffer(channels, frames, rate) {
      return { duration: frames / rate, getChannelData: () => new Float32Array(frames) };
    }
    createBufferSource() { return { connect() {}, start() {}, stop() {} }; }
  }
  const speech = { speaking: false, pending: false,
    cancel() { this.speaking = false; }, speak(u) { spoken.push(u.text); } };
  const context = vm.createContext({ AudioContext,
    SpeechSynthesisUtterance: class { constructor(text) { this.text = text; } },
    navigator: {}, document: { addEventListener() {} },
    setTimeout(fn, delay) { timers.set(++id, { fn, delay }); return id; },
    clearTimeout(id) { timers.delete(id); },
    speechSynthesis: speech, addEventListener() {},
  });
  context.window = context;
  vm.runInContext(fs.readFileSync('web/timing_audio.js', 'utf8'), context);
  return { audio: context.setpadTiming, timers, spoken, speech };
}

test('Tempo timing: click precedes count by half a beat, capped at one second', async () => {
  for (const [bpm, expectedDelay] of [[60, 505], [120, 255], [20, 1005]]) {
    const h = harness();
    await h.audio.configure(true, bpm, '');
    h.audio.speak('하나', 'ko');
    assert.equal(h.spoken.length, 0);
    assert.equal(h.timers.size, 1);
    const pending = [...h.timers.values()][0];
    assert.equal(pending.delay, expectedDelay);
    pending.fn();
    assert.deepEqual(h.spoken, ['하나']);
  }
});

test('stop removes a pending count, and tempo changes cancel old scheduling', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '');
  h.audio.speak('하나', 'ko');
  await h.audio.configure(false, 0, '');
  assert.equal(h.timers.size, 0);
  assert.deepEqual(h.spoken, []);
  await h.audio.configure(true, 60, '');
  h.audio.speak('둘', 'ko');
  await h.audio.configure(true, 120, '');
  assert.equal(h.timers.size, 0);
});

test('pending or speaking counts are never stacked', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '');
  h.audio.speak('하나', 'ko');
  h.audio.speak('둘', 'ko');
  assert.equal(h.timers.size, 1);
  await h.audio.configure(false, 0, '');
  await h.audio.configure(true, 60, '');
  h.speech.speaking = true;
  h.audio.speak('셋', 'ko');
  assert.equal(h.timers.size, 0);
});
