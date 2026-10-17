const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const test = require('node:test');

function harness() {
  const timers = new Map(), played = [], starts = [];
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
  // A recorded word: plays until the test ends it.
  class Audio {
    constructor(src) { this.src = src; this.paused = true; this.ended = false; this.duration = 0.8; this.currentTime = 0; }
    play() { this.paused = false; played.push(this.src); return Promise.resolve(); }
    pause() { this.paused = true; }
  }
  const context = vm.createContext({ AudioContext, Audio,
    navigator: {}, document: { addEventListener() {} },
    setTimeout(fn, delay) { timers.set(++id, { fn, delay }); return id; },
    clearTimeout(id) { timers.delete(id); },
    addEventListener() {},
  });
  context.window = context;
  vm.runInContext(fs.readFileSync('web/timing_audio.js', 'utf8'), context);
  const fire = () => { const [k, t] = [...timers.entries()][0]; timers.delete(k); t.fn(); return t.delay; };
  return { audio: context.setpadTiming, timers, played, starts, fire };
}

const one = 'voice/count/en/m/1.m4a', two = 'voice/count/en/m/2.m4a';

test('Tempo timing: click precedes count by half a beat, capped at one second', async () => {
  for (const [bpm, expectedDelay] of [[60, 505], [120, 255], [20, 1005]]) {
    const h = harness();
    await h.audio.configure(true, bpm, '');
    h.audio.voice(one, true);
    assert.equal(h.played.length, 0);
    assert.equal(h.timers.size, 1);
    assert.equal(h.fire(), expectedDelay);
    assert.deepEqual(h.played, ['assets/' + one], 'Flutter web serves assets under assets/');
  }
});

test('stop removes a pending count, and tempo changes cancel old scheduling', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '');
  h.audio.voice(one, true);
  await h.audio.configure(false, 0, '');
  assert.equal(h.timers.size, 0);
  assert.deepEqual(h.played, []);
  await h.audio.configure(true, 60, '');
  h.audio.voice(two, true);
  await h.audio.configure(true, 120, '');
  assert.equal(h.timers.size, 0);
});

test('a newer count replaces one waiting; a count is dropped while the word before sounds', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '');
  h.audio.voice(one, true);
  h.audio.voice(two, true);
  assert.equal(h.timers.size, 1);
  h.fire();
  assert.deepEqual(h.played, ['assets/' + two]);
  h.audio.voice(one, true);
  h.fire(); // "Two" is still sounding
  assert.deepEqual(h.played, ['assets/' + two]);
});

test('click loop starts at the timer\'s phase inside the beat, and counts follow that grid', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '', 0.3);
  assert.deepEqual(h.starts, [0.3]);
  h.audio.voice(one, true);
  // Half a beat (0.5 s) after the click, 0.3 s of which has already passed.
  assert.equal([...h.timers.values()][0].delay, 205);
  const late = harness();
  await late.audio.configure(true, 60, '', 5);
  assert.ok(late.starts[0] < 1, 'phase is clamped inside the one-beat buffer');
});

test('complete stops the click but not the last count; pause cuts it', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '');
  h.audio.voice(one, true);
  await h.audio.configure(false, 0, 'complete');
  assert.equal(h.timers.size, 1, 'the waiting count survives the complete cue');
  h.fire();
  assert.deepEqual(h.played, ['assets/' + one]);
  await h.audio.configure(true, 60, '');
  h.audio.voice(two, true);
  await h.audio.configure(false, 0, '');
  assert.equal(h.timers.size, 0);
  assert.equal(h.played.length, 1);
});

test('a phrase waits for the cue and the word sounding; counts wait it out', async () => {
  const h = harness();
  await h.audio.configure(true, 60, '');
  h.audio.voice(one, true);
  h.fire();
  await h.audio.configure(false, 0, 'complete'); // 0.7 s of ding
  h.audio.voice('voice/en/m/done.m4a', false);
  assert.equal([...h.timers.values()][0].delay, 805, '"One" has 0.8 s left');
  h.audio.voice(two, true);
  assert.equal(h.timers.size, 1, 'no count over a waiting phrase');
  h.fire();
  assert.deepEqual(h.played, ['assets/' + one, 'assets/voice/en/m/done.m4a']);
});
