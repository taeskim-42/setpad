abstract class TimingAudio {
  void Function()? onInterrupted;
  Future<void> configure({required bool active, int? bpm, String? cue});
  Future<void> dispose();
}
