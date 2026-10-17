abstract class TimingAudio {
  void Function()? onInterrupted;

  /// The interruption that paused the timer is over and the system says play
  /// may resume (iOS interruption ended with shouldResume).
  void Function()? onResumed;

  /// Builds the cue players and loads the first recorded words ahead of time,
  /// silently. Safe to call any number of times.
  Future<void> warmUp() async {}

  /// [phase]: how far into the current beat the timer is, in seconds. The
  /// click loop starts there, so after a pause or a re-sync the clicks stay on
  /// the timer's beat grid instead of restarting from wherever play() lands.
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  });

  /// Plays a recorded word, a Flutter asset path ([countVoice],
  /// [phraseVoice]). [onBeat] (a count): half a beat after the click it
  /// belongs to (at most one second); a newer count replaces one still
  /// waiting, and if the previous word is still sounding it waits briefly,
  /// then gives up. Otherwise (a phrase) once the cue and the word still
  /// sounding are over; a count never cuts in on it. Pausing or stopping
  /// cuts both; finishing (the complete cue) does not.
  Future<void> playVoice(String asset, {bool onBeat = false}) async {}

  /// Whether a timer that sounds (a workout run or a set rest) is running,
  /// as opposed to `active`, which the set stage alone also holds to keep
  /// the screen on. Android runs its foreground service and wake lock only
  /// while this is on. [linger]: it went off with a finishing cue, so the
  /// last sound and the words queued behind it still play with the screen
  /// off.
  Future<void> keepAlive(bool on, {bool linger = false}) async {}

  Future<void> dispose();
}
