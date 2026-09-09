abstract class TimingAudio {
  void Function()? onInterrupted;
  Future<void> configure({required bool active, int? bpm, String? cue});

  /// Read after the current click, offset by half a beat (at most one second).
  /// Skip overlapping speech; cancel pending counts when playback stops.
  Future<void> speak(String text, String locale);

  Future<void> dispose();
}
