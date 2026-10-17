/// Colors of the run stage. The stage is always dark, in light mode too
/// (spec 1.8 §1.5): the phase fill is read from across the room, and a fill
/// over a white ground loses that. Cards and sheets keep the app palette.
///
/// Text over a fill is [onFill] (dark): white on the three fills is only
/// 3.24 / 1.82 / 1.61:1, the dark ink 5.69 / 10.14 / 11.47:1 — the reason the
/// stage draws its text twice (light on the empty part, dark on the fill).
library;

import 'package:flutter/painting.dart';

abstract final class StagePalette {
  static const bg = Color(0xFF141414);
  static const text = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8B8B8);
  static const outline = Color(0xFF6A6A6A);
  static const surface2 = Color(0xFF2E2E2E);
  static const fillPrep = Color(0xFFFFC24D);
  static const fillWork = Color(0xFFFF4F51);
  static const fillRest = Color(0xFF7CC8FF);
  static const onFill = Color(0xFF141414);

  /// Paused is grey, so a frozen level reads as "stopped" from afar.
  static const paused = textSecondary;
}
