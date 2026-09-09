abstract class TimingAudio {
  void Function()? onInterrupted;
  Future<void> configure({required bool active, int? bpm, String? cue});

  /// 세는 말을 소리 내어 읽는다.
  ///
  /// **앞의 말이 아직 안 끝났으면 그 박자는 건너뛴다.** 겹쳐서 뭉개지는 것보다
  /// 한 박자를 거르는 편이 낫다 — 빠른 박자에서는 "서른일곱"(약 730ms)이
  /// 박자 간격(120bpm 이면 500ms)보다 길어서 반드시 겹친다.
  Future<void> speak(String text, String locale);

  Future<void> dispose();
}
