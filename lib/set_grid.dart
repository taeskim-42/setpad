import 'package:flutter/cupertino.dart';

import 'editor.dart';
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'parser.dart';
import 'units.dart';

/// 이 운동의 칸들이 함께 쓰는 단위. 제목 줄에 한 번만 적고 칸에서는 뺀다 —
/// 칸마다 "kg" 를 붙이면 한 줄에 다섯 세트가 안 들어간다.
///
/// 무게와 횟수가 같이 있는 첫 세트의 단위다. 그런 세트가 없으면 null 이고
/// 칸들이 제 단위를 그대로 적는다("5km", "30초").
String? sharedUnit(ExerciseBlock block) => block.sets
    .where((s) => s.value != null && s.reps != null)
    .firstOrNull
    ?.unit;

/// 표의 한 칸. "60×10", 맨몸은 "8회", 거리·시간은 "5km".
String cellLabel(
  LoggedSet set, {
  required String? shared,
  required String Function(int) formatReps,
}) {
  final value = set.value, reps = set.reps;
  if (value == null) return reps == null ? '–' : formatReps(reps);
  if (reps == null) return formatValue(value, set.unit);
  return '${set.unit == shared ? formatNumber(value) : formatValue(value, set.unit)}×$reps';
}

/// 한 운동의 세트 전부를 종이 운동일지처럼 칸으로 늘어놓는다.
///
/// 세트마다 한 칸이다 — 값이 같아도 합치지 않는다. 칸 폭이 같아서 운동끼리
/// 열이 맞고, 세트가 한 줄을 넘으면 다음 줄로 흐른다. 화면 밖으로 숨는 세트는
/// 없다. 글자 크기 설정을 따라 칸 폭도 커진다.
class SetGrid extends StatelessWidget {
  const SetGrid({
    super.key,
    required this.block,
    this.onTapSet,
    this.editingSet,
  });

  final ExerciseBlock block;
  final ValueChanged<int>? onTapSet;
  final int? editingSet;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final shared = sharedUnit(block);
    final scaler = MediaQuery.textScalerOf(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final faint = CupertinoColors.tertiaryLabel.resolveFrom(context);
    // 폭을 재는 글과 그리는 글이 같은 서체여야 한다 — 화면 기본 글꼴에 얹는다.
    final style = DefaultTextStyle.of(context).style.copyWith(
      fontSize: 15,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: label,
    );
    InlineSpan span(int i, LoggedSet set) => TextSpan(
      children: [
        // 몇 번째 세트인지. 해내지 않은 세트는 빈 동그라미가 붙고 흐리다 —
        // 계획과 수행이 섞여 보이면 안 된다.
        TextSpan(
          text: set.done ? '${i + 1} ' : '${i + 1}○ ',
          style: TextStyle(fontSize: 10, color: faint),
        ),
        TextSpan(
          text: cellLabel(set, shared: shared, formatReps: l.repsCount),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final columns = (box.maxWidth / (62 * scaler.scale(1))).floor().clamp(
          2,
          8,
        );
        final width = box.maxWidth / columns;
        // 글이 한 열보다 넓으면("102.5×10") 두 열을 차지한다. 제 폭대로 두면
        // 옆 칸과 붙고 아래위 열이 어긋난다.
        final needs = [
          for (final (i, set) in block.sets.indexed)
            () {
              final painter = TextPainter(
                text: TextSpan(style: style, children: [span(i, set)]),
                textDirection: TextDirection.ltr,
                textScaler: scaler,
                maxLines: 1,
              )..layout();
              final need = painter.width + 5;
              painter.dispose();
              return need;
            }(),
        ];
        // 넓은 값 때문에 줄이 하나 늘 바에는, 제 폭대로 한 줄에 다 들어가면
        // 그렇게 둔다 — 이 운동만 열이 어긋나지만 한 줄(30pt)을 아낀다. 남는
        // 폭은 고르게 나눠 준다.
        final total = needs.fold(0.0, (a, b) => a + b);
        final spanned = needs.fold(0, (n, w) => n + (w / width).ceil());
        final oneRow =
            spanned > columns &&
            needs.length <= columns &&
            total <= box.maxWidth;
        final slack = oneRow ? (box.maxWidth - total) / needs.length : 0.0;
        double cell(int i, LoggedSet set) => oneRow
            ? needs[i] + slack
            : (needs[i] / width).ceil().clamp(1, columns) * width;

        return Wrap(
          children: [
            for (final (i, set) in block.sets.indexed)
              Semantics(
                button: onTapSet != null,
                label:
                    '${l.setOrdinal(i + 1)} ${setLabel(value: set.value, unit: set.unit, reps: set.reps, formatReps: l.repsCount)}',
                excludeSemantics: true,
                child: GestureDetector(
                  key: ValueKey('set-cell-$i'),
                  onTap: onTapSet == null ? null : () => onTapSet!(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    // 열 폭의 합이 반올림으로 줄 폭을 넘지 않게 조금 덜 준다.
                    width: cell(i, set) - 0.01,
                    constraints: const BoxConstraints(minHeight: 30),
                    alignment: Alignment.centerLeft,
                    color: i == editingSet
                        ? sealTint.resolveFrom(context)
                        : null,
                    child: Text.rich(
                      span(i, set),
                      maxLines: 1,
                      softWrap: false,
                      style: style.copyWith(color: set.done ? label : faint),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 운동 이름 한 줄과 그 아래의 칸들. 읽기 전용 자리(같은 날의 다른 기록,
/// 전체 보기)가 쓴다 — 편집 화면은 같은 [SetGrid] 위에 제 입력 줄을 얹는다.
class BlockSummary extends StatelessWidget {
  const BlockSummary({super.key, required this.block});
  final ExerciseBlock block;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final unit = sharedUnit(block);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                  ),
                ),
              ),
              if (unit != null)
                Text(
                  unitById[unit]?.label ?? unit,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
            ],
          ),
          SetGrid(block: block),
          for (final (i, set) in block.sets.indexed)
            for (final note in set.notes)
              Text(
                '${i + 1}  $note',
                style: TextStyle(fontSize: 13, height: 1.35, color: muted),
              ),
        ],
      ),
    );
  }
}

/// 전체 보기 — 그날 기록 전부를 한 화면에 맞춰 줄여 놓고, 두 손가락으로
/// 키우고 끌어서 읽는다. 기본 화면이 이미 다 보여 주므로 이것은 기록이 한
/// 화면을 넘는 날을 위한 보조다. 유한한 화면에 기록이 끝없이 읽히게 담기지는
/// 않는다 — 줄어든 글씨는 키워서 읽는다.
/// 오늘 한 장 — 운동 종이 한 장처럼, 그날 한 세트 전부와 먹은 것과 섭취−운동을
/// 한 화면에 놓는다. [energy] 는 문서 머리의 한 줄이고, [meals] 는 그날 끼니들이다.
Future<void> showFitAll(
  BuildContext context,
  List<({String caption, List<ExerciseBlock> blocks})> documents, {
  String? energy,
  List<({String text, String kcal})> meals = const [],
}) => Navigator.of(context).push(
  CupertinoPageRoute<void>(
    fullscreenDialog: true,
    builder: (context) => CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(L.of(context).fitAll),
        border: null,
      ),
      child: SafeArea(
        child: InteractiveViewer(
          maxScale: 6,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (energy != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            energy,
                            key: const ValueKey('sheet-energy'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      for (final d in documents) ...[
                        if (documents.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              d.caption,
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        for (final b in d.blocks) BlockSummary(block: b),
                      ],
                      if (meals.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 4),
                          child: Text(
                            L.of(context).mealsTitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                        for (final m in meals)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  m.kcal,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
