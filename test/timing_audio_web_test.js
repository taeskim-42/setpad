const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const test = require('node:test');

function harness() {
  const timers = new Map(), spoken = [], starts = [];
  let id = 0;
  class AudioContext {
    currentTime = 0;
    sampleRate = 22050;
    async resume() {}
    async suspend() {}
    createBuffer(channels, frames, rate) {
      return { duration: frames / rate, getChannelData: () => new Float32Array(frames) };
    }
    createBufferSource() { return { connect() {}, start(when, offset) { starts.push(offset); }, stop() {} }; }
  }
  const speech = { speaking: false, pending: false,
    cancel() { this.speaking = false; }, speak(u) { spoken.push(u.text); this.last = u; } };
  const context = vm.createContext({ AudioContext,
    SpeechSynthesisUtterance: class { constructor(text) { this.text = text; } },
    navigator: {}, document: { addEventListener() {} },
    setTimeout(fn, delay) { timers.set(++id, { fn, delay }); return id; },
    clearTimeout(id) { timers.delete(id); },
    speechSynthesis: speech, addEventListener() {},
  });
  context.window = context;
  vm.runInContext(fs.readFileSync('web/timing_audio.js', 'utf8'), context);
  return { audio: context.setpadTiming, timers, spoken, speech, starts };
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

test('click loop starts at the timer\'s phase inside the beat, and counts follow that grid', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '', 0.3);
  assert.deepEqual(h.starts, [0.3]);
  h.audio.speak('하나', 'ko');
  // Half a beat (0.5 s) after the click, 0.3 s of which has already passed.
  assert.equal([...h.timers.values()][0].delay, 205);
  const late = harness();
  await late.audio.configure(true, 60, '', 5);
  assert.ok(late.starts[0] < 1, 'phase is clamped inside the one-beat buffer');
});

test('speak uses the rate it is given, 1.2 when none', async () => {
  const h = harness();
  await h.audio.configure(true, 0, 'ready');
  h.audio.speak('하나', 'ko', 1.15);
  [...h.timers.values()][0].fn();
  assert.equal(h.speech.last.rate, 1.15);
  h.timers.clear();
  h.audio.speak('둘', 'ko');
  [...h.timers.values()][0].fn();
  assert.equal(h.speech.last.rate, 1.2);
});

test('complete stops the click but not the last count; pause cuts it', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '');
  h.audio.speak('서른', 'ko');
  let cancelled = 0;
  h.speech.cancel = () => { cancelled++; };
  await h.audio.configure(false, 0, 'complete');
  assert.equal(h.timers.size, 1, 'the waiting count survives the complete cue');
  assert.equal(cancelled, 0);
  [...h.timers.values()][0].fn();
  assert.deepEqual(h.spoken, ['서른']);
  h.timers.clear();
  await h.audio.configure(true, 60, '');
  h.audio.speak('하나', 'ko');
  await h.audio.configure(false, 0, '');
  assert.equal(h.timers.size, 0);
  assert.equal(cancelled, 1);
});
