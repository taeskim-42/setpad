import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show showLicensePage;

import 'account.dart';
import 'body_page.dart';
import 'booking_entry.dart';
import 'health_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'palette.dart';
import 'paywall.dart';
import 'rest_alarm.dart';
import 'purchases.dart';
import 'trainer.dart';

/// 설정.
///
/// **액션시트가 아니라 화면이다.** 예전에는 무게 단위·박자·체육관·이용권·
/// 예약·복원·로그인이 팝업 한 장에 줄로 쌓여 있었다. 줄이 늘수록 무엇을
/// 파는지가 안 보였고, 실제로 이용권도 그 줄 중 하나였다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store, this.account});
  final NotesStore store;
  final Account? account;

  /// 공동 루틴 목록을 연다. 홈 화면에서 뺀 뒤로 목록에 가는 길은 여기다 —
  /// 없으면 이미 만들었거나 초대받은 루틴을 다시 열 수 없다.

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final a = account;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.settingsTitle)),
      child: SafeArea(
        // **둘 다 듣는다.** 계정만 듣던 때는 무게 단위와 박자를 바꿔도 화면이
        // 그대로였다 — 그 값들은 저장소에 있다. 나갔다 들어와야 바뀌었다.
        child: ListenableBuilder(
          listenable: a == null ? store : Listenable.merge([store, a]),
          builder: (context, _) => ListView(
            children: [
              _Section(title: l.settingsRecording),
              _Choice(
                label: l.weightUnitSetting,
                value: store.weightUnit,
                onTap: () => _pickUnit(context),
              ),
              _Toggle(
                label: l.countAloud,
                value: store.countAloud,
                onChanged: (v) => store.setCountAloud(v),
              ),
              // 기본은 켜짐. 끄면 모델로 가는 것이 모두 멈추고 기기 안에서만 한다.
              _Toggle(
                key: const ValueKey('settings-ai'),
                label: l.aiSetting,
                value: store.aiOn,
                onChanged: store.setAiOn,
              ),
              // 디버그 빌드에만: 휴식 경보가 워치로 넘어가는지 실기기로 재는 단추.
              // 누르고 5초 안에 폰을 내려놓고 워치의 운동 앱을 앞에 둔다.
              if (kDebugMode)
                _Row(
                  key: const ValueKey('settings-rest-alarm-test'),
                  label: '휴식 경보 시험 (5초 뒤)',
                  onTap: () async {
                    if (!await authorizeRestAlarm()) return;
                    await Future<void>.delayed(const Duration(seconds: 5));
                    await ringRestAlarm('다음 라운드 — 시험');
                  },
                ),
              // 기초대사량 셈에 쓰는 키·몸무게·나이·성별. 기기 안에만 둔다.
              _Row(
                key: const ValueKey('settings-body'),
                label: l.bodyTitle,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => BodyPage(store: store),
                  ),
                ),
              ),
              // 건강 앱과 무엇을 왜 주고받는지 — 심박으로 휴식을 끊는 것까지.
              _Row(
                key: const ValueKey('settings-health'),
                label: l.healthDataTitle,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const HealthDataPage(),
                  ),
                ),
              ),

              // **이용권은 그 자체로 한 칸이다.** 무엇을 사는지 한 줄로는
              // 알 수 없으므로 누르면 파는 화면이 열린다.
              //
              // 팔지 않을 때는 아예 안 그린다. 다만 이미 가진 사람에게는
              // 보여 준다 — 무엇을 샀는지 확인할 자리가 없으면 안 된다.
              if (a != null) ...[
                if (a.selling || a.paid) ...[
                  _Section(title: l.proTitle),
                  _Row(
                    label: a.paid
                        ? l.proOwned
                        : l.proPaid(proPlatesPerMonth, proInputPerDay),
                    detail: switch (a.plan) {
                      Plan.yearly => l.planYearly,
                      Plan.monthly => l.planMonthly,
                      null => null,
                    },
                    accent: !a.paid,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => Paywall(account: a),
                      ),
                    ),
                  ),
                ],

                // 다니는 곳이 없으면 무엇을 하면 생기는지 적는다. 아무것도
                // 안 그리면 이 앱에 그런 기능이 있는 줄을 모른다.
                _Section(title: l.settingsGym),
                if (a.gyms.isEmpty)
                  _Note(l.settingsNoGym)
                else ...[
                  for (final gym in a.gyms)
                    _Row(
                      label: gym.trainer == null
                          ? l.gymOnly(gym.name)
                          : l.gymMember(gym.name, gym.trainer!),
                    ),
                  _Row(
                    label: l.bookingNew,
                    accent: true,
                    onTap: () => openBooking(context, a),
                  ),
                ],
                // 직원이면 에이전트 보고서로 가는 길. 목록 위 입구와 같은 곳이다.
                // 회원용 '다니는 체육관' 밖에 따로 둔다 — 그 안이면 직원만인
                // 사람이 '스티커에 폰을 대면…' 안내와 한 묶음으로 읽는다.
                if (a.staff.isNotEmpty) ...[
                  _Section(title: l.settingsTrainer),
                  _Row(
                    label: l.trainerReport,
                    accent: true,
                    onTap: () => openTrainer(context, a),
                  ),
                ],

                _Section(title: l.settingsAccount),
                // **누구인지 보여주는 줄과 나가는 줄을 가른다.** 하나로 묶여
                // 있을 때는 자기 이름을 눌러본 사람이 그대로 로그아웃됐다.
                if (a.signedIn)
                  _Row(label: a.nickname)
                else
                  _Row(
                    label: l.accountSignIn,
                    // 서버가 막았으면 그렇다고 적는다. 눌러도 아무 일이 없는
                    // 것처럼 보이면 사람은 앱이 고장 난 줄 안다.
                    detail: a.signInRefused ? l.signInFailed : null,
                    onTap: a.signIn,
                  ),
                // 원판은 로그인 전에도 있다 — 그때는 이 기기의 지갑이다.
                if (a.plates case final plates?)
                  _Row(
                    key: const ValueKey('settings-plates'),
                    label: l.platesBalance(plates),
                  ),
                if (a.selling || a.paid)
                  _Row(label: l.restorePurchases, onTap: a.restore),
                // **계정을 만들 수 있으면 앱 안에서 지울 수도 있어야 한다.**
                // 웹으로 보내는 것은 그 답이 아니다.
                if (a.signedIn) ...[
                  _Row(label: l.accountSignOut, onTap: a.signOut),
                  _Row(
                    label: l.accountDelete,
                    onTap: () => _confirmDelete(context, a),
                  ),
                ],
              ],
              // 쓰는 오픈소스의 고지문. 몸 그림 그림(MIT)의 조건이 고지문을 싣는 것이다.
              _Row(
                key: const ValueKey('settings-licenses'),
                label: l.openSourceLicenses,
                onTap: () => showLicensePage(context: context),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 탈퇴는 한 번 더 묻는다. 되돌릴 수 없고 옆에 로그아웃이 있다.
  Future<void> _confirmDelete(BuildContext context, Account account) async {
    final l = L.of(context);
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.accountDelete),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l.accountDeleteAsk, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.accountDeleteDo),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    final problem = await account.deleteAccount();
    if (problem == null || !context.mounted) return;
    // 서버가 왜 막았는지 말해 준다. 빈 문자열이면 서버에 닿지 못한 것이다.
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            problem.isEmpty ? L.of(ctx).accountDeleteFailed : problem,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.of(ctx).ok),
          ),
        ],
      ),
    );
  }

  Future<void> _pickUnit(BuildContext context) async {
    final l = L.of(context);
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.weightUnitSetting),
        message: Text(l.weightUnitHelp),
        actions: [
          for (final unit in ['kg', 'lb'])
            CupertinoActionSheetAction(
              isDefaultAction: unit == store.weightUnit,
              onPressed: () => Navigator.pop(ctx, unit),
              child: Text('${unit == store.weightUnit ? '✓ ' : ''}$unit'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
    if (choice != null) store.setWeightUnit(choice);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.label,
    this.detail,
    this.accent = false,
    this.onTap,
  });
  final String label;
  final String? detail;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
                color: accent
                    ? seal.resolveFrom(context)
                    : CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 15,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
        ],
      ),
    );
    return onTap == null
        ? body
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: body,
          );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      _Row(label: label, detail: value, onTap: onTap);
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}
