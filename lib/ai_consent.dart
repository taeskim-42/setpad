import 'package:flutter/cupertino.dart';

import 'health_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'share.dart';

/// AI 도움(DeepSeek)을 처음 쓰기 전에 한 번 묻는다. 이미 골랐으면 묻지 않고 그 답이다.
///
/// 고르지 않고 닫으면 이번만 끈다 — 다음에 다시 묻는다. '나중에' 도 막다른 길이
/// 아니다: 친 글·적은 kcal·이름 찾기는 기기 안에서 그대로 되고, 설정의 AI 도움
/// 줄에서 언제든 켠다. [again] 은 그 줄에서 켤 때다 — 전에 '나중에' 를 골랐어도
/// 무엇을 보내는지 다시 보여 주고 묻는다.
Future<bool> askAiConsent(
  BuildContext context,
  NotesStore store, {
  bool again = false,
}) {
  final decided = store.aiConsent;
  if (!again && decided != null) return Future.value(decided);
  // 끼니 어림과 한 줄 설정이 한꺼번에 와도 시트는 하나다.
  return _asking ??= _show(context, store).whenComplete(() => _asking = null);
}

Future<bool>? _asking;

Future<bool> _show(BuildContext context, NotesStore store) async {
  if (!context.mounted) return false;
  final choice = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (_) => const AiConsentSheet(),
  );
  if (choice != null) store.setAiConsent(choice);
  return choice ?? false;
}

/// 무엇을, 누구에게, 어디를 거쳐 보내는지. 문구는 lib/record_ai.dart 의 요청과
/// 같아야 한다 — 보내는 것이 바뀌면 여기와 개인정보 처리방침을 같이 고친다.
class AiConsentSheet extends StatelessWidget {
  const AiConsentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    Widget line(String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
    );
    return CupertinoActionSheet(
      title: Text(l.aiConsentTitle),
      message: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(l.aiConsentBody),
          line(l.aiConsentSent),
          line(l.aiConsentLater),
          CupertinoButton(
            key: const ValueKey('ai-consent-privacy'),
            padding: const EdgeInsets.only(top: 8),
            minimumSize: const Size(44, 36),
            onPressed: () => openUrl(HealthDataPage.privacyUrl),
            child: Text(
              l.healthDataPrivacy,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          key: const ValueKey('ai-consent-agree'),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.aiConsentAgree),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        key: const ValueKey('ai-consent-later'),
        onPressed: () => Navigator.pop(context, false),
        child: Text(l.aiConsentNotNow),
      ),
    );
  }
}
