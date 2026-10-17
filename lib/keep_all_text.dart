import 'package:flutter/widgets.dart';

/// Flutter has no CSS `word-break: keep-all`, so Korean wraps between any two
/// syllables ('여기/서'). A joiner between the characters of a word leaves
/// spaces as the only break points. Only the painted string gets it: the
/// screen reader reads the sentence as written. A word wider than its line
/// still breaks anywhere. (Tempo's keep_all_text.dart, but Tempo's word joiner
/// U+2060 measured short on the system fonts — the iOS simulator cut the last
/// syllable of a line in half; the zero width joiner U+200D does not.)
String keepAll(String s) => s
    .split(' ')
    .map((w) => _hangul.hasMatch(w) ? w.characters.join('\u200D') : w)
    .join(' ');

// Latin words ('AI', 'BPM') already break only at spaces; leave them be.
final _hangul = RegExp('[\uAC00-\uD7A3]');

/// A [Text] for a sentence that wraps: Korean breaks between words.
class KeepAllText extends StatelessWidget {
  const KeepAllText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
    keepAll(data),
    semanticsLabel: data,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
  );
}
