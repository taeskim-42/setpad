abstract class TimingAudio {
  void Function()? onInterrupted;

  /// [phase]: how far into the current beat the timer is, in seconds. The
  /// click loop starts there, so after a pause or a re-sync the clicks stay on
  /// the timer's beat grid instead of restarting from wherever play() lands.
  Future<void> configure({
    required bool active,
    int? bpm,
    String? cue,
    double? phase,
  });

  /// Read half a beat after the click this count belongs to (at most one
  /// second). [rate] multiplies the platform's default speech rate. A newer
  /// count replaces one still waiting; if the previous word is still sounding,
  /// wait briefly rather than cut it off, then give up.
  /// Cancel pending counts when playback stops.
  Future<void> speak(String text, String locale, {double rate = 1.15});

  Future<void> dispose();
}
