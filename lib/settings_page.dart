import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show showLicensePage;

import 'account.dart';
import 'sign_in.dart';
import 'sign_in_sheet.dart';
import 'body_page.dart';
import 'booking_entry.dart';
import 'gym.dart' show refusalMessage;
import 'gym_page.dart';
import 'health_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'paywall.dart';
import 'record_ai.dart';
import 'rest_alarm.dart';
import 'purchases.dart';
import 'settings_list.dart';
import 'trainer.dart';
import 'workout_import.dart';
import 'workout_timing.dart' show timerClock;
import 'timer_sheet.dart' show ValueSheet;

/// 설정.
///
/// **액션시트가 아니라 화면이다.** 예전에는 무게 단위·박자·체육관·이용권·
/// 예약·복원·로그인이 팝업 한 장에 줄로 쌓여 있었다. 줄이 늘수록 무엇을
/// 파는지가 안 보였고, 실제로 이용권도 그 줄 중 하나였다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store, this.account});
  final NotesStore store;
  final Account? account;

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
            padding: const EdgeInsets.only(top: 8),
            // 머리글 없는 묶음은 꼬리글이 설명하는 켜고 끄기 한 줄(AI 도움·끼니 보내기)과
            // 맨 끝 라이선스 한 줄뿐이다. 나머지 줄은 모두 머리글 아래에 둔다 — 머리글 없는
            // 여러 줄 묶음이 섞여 머리글이 들쭉날쭉했다.
            children: [
              SettingsSection(
                title: l.settingsRecording,
                children: [
                  SettingsRow(
                    label: l.weightUnitSetting,
                    detail: store.weightUnit,
                    onTap: () => _pickUnit(context),
                  ),
                  SettingsToggle(
                    label: l.countAloud,
                    value: store.countAloud,
                    onChanged: (v) => store.setCountAloud(v),
                  ),
                  SettingsRow(
                    key: const ValueKey('settings-voice'),
                    label: l.voiceSetting,
                    detail: store.voice == 'w' ? l.voiceFemale : l.voiceMale,
                    onTap: () => _pickVoice(context),
                  ),
                  SettingsToggle(
                    key: const ValueKey('settings-voice-cues'),
                    label: l.voiceCuesSetting,
                    value: store.voiceCues,
                    onChanged: store.setVoiceCues,
                  ),
                  SettingsToggle(
                    key: const ValueKey('settings-haptics'),
                    label: l.timerHapticsSetting,
                    value: store.hapticsOn,
                    onChanged: store.setHapticsOn,
                  ),
                  SettingsRow(
                    key: const ValueKey('settings-rest'),
                    label: l.focusRestDefault,
                    detail: timerClock(store.restSeconds),
                    onTap: () => _pickRest(context),
                  ),
                  SettingsRow(
                    key: const ValueKey('settings-workout-import'),
                    label: l.workoutImportTitle,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => WorkoutImportPage(
                          store: store,
                          ai:
                              account?.ai ??
                              RecordAi(
                                deviceId: store.deviceId,
                                enabled: () => store.aiOn,
                              ),
                        ),
                      ),
                    ),
                  ),
                  // 디버그 빌드에만: 휴식 경보가 워치로 넘어가는지 실기기로 재는 단추.
                  // 누르고 5초 안에 폰을 내려놓고 워치의 운동 앱을 앞에 둔다.
                  if (kDebugMode)
                    SettingsRow(
                      key: const ValueKey('settings-rest-alarm-test'),
                      label: '휴식 경보 시험 (5초 뒤)',
                      onTap: () async {
                        if (!await authorizeRestAlarm()) return;
                        await Future<void>.delayed(const Duration(seconds: 5));
                        await ringRestAlarm('다음 라운드 — 시험');
                      },
                    ),
                ],
              ),
              // 기본은 켜짐. 끄면 모델로 가는 것이 모두 멈추고 기기 안에서만 한다.
              // 무엇이 나가고 끄면 무엇이 멈추는지를 바로 아래에 적는다.
              SettingsSection(
                footer: l.aiSettingNote,
                children: [
                  SettingsToggle(
                    key: const ValueKey('settings-ai'),
                    label: l.aiSetting,
                    value: store.aiOn,
                    onChanged: store.setAiOn,
                  ),
                ],
              ),
              SettingsSection(
                title: l.settingsBodyHealth,
                children: [
                  // 기초대사량 셈에 쓰는 키·몸무게·나이·성별. 기기 안에만 둔다.
                  SettingsRow(
                    key: const ValueKey('settings-body'),
                    label: l.bodyTitle,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => BodyPage(store: store, ai: account?.ai),
                      ),
                    ),
                  ),
                  // 건강 앱과 무엇을 왜 주고받는지 — 심박으로 휴식을 끊는 것까지.
                  SettingsRow(
                    key: const ValueKey('settings-health'),
                    label: l.healthDataTitle,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const HealthDataPage(),
                      ),
                    ),
                  ),
                ],
              ),

              // **이용권은 그 자체로 한 칸이다.** 무엇을 사는지 한 줄로는
              // 알 수 없으므로 누르면 파는 화면이 열린다.
              //
              // 팔지 않을 때는 아예 안 그린다. 다만 이미 가진 사람에게는
              // 보여 준다 — 무엇을 샀는지 확인할 자리가 없으면 안 된다.
              if (a != null) ...[
                if (a.selling || a.paid)
                  SettingsSection(
                    title: l.proTitle,
                    children: [
                      SettingsRow(
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
                  ),

                // 다니는 곳이 없으면 무엇을 하면 생기는지 적는다. 아무것도
                // 안 그리면 이 앱에 그런 기능이 있는 줄을 모른다. 행이 없으면
                // 이 안내가 흐린 행 하나로 묶음 안에 선다(빈 묶음처럼 보이지 않게).
                SettingsSection(
                  title: l.settingsGym,
                  footer: a.gyms.isEmpty ? l.settingsNoGym : null,
                  children: [
                    // 도장이 보낸 초대. 받아야 회원이 된다.
                    for (final invite in a.invites)
                      SettingsRow(
                        label: l.inviteFrom(invite.gymName),
                        detail: invite.verified ? null : l.gymUnverified,
                        accent: true,
                        onTap: () => answerGymInvite(context, a, invite),
                      ),
                    if (a.gyms.isNotEmpty) ...[
                      // 누르면 그 도장 — 공지·이용권·수업 예약·나가기.
                      for (final gym in a.gyms)
                        SettingsRow(
                          key: ValueKey('settings-gym-${gym.id}'),
                          label: gym.trainer == null
                              ? l.gymOnly(gym.name)
                              : l.gymMember(gym.name, gym.trainer!),
                          onTap: () => openGym(context, a, store, gym.id),
                        ),
                      SettingsRow(
                        label: l.bookingNew,
                        accent: true,
                        onTap: () => openBooking(context, a, store: store),
                      ),
                    ],
                  ],
                ),
                // 끼니는 건강 정보라 회원이 켜야 간다(기본 꺼짐). 켜는 것은 도장이
                // 하나일 때만 — 여럿이면 어디로 보낼지 앱이 고르지 않는다. 켠 것은
                // 도장이 늘어도 끌 수 있어야 한다. 안내는 켤 때 고른 그 도장을 말한다.
                if (a.gyms.isNotEmpty &&
                    (store.sharesMeals || a.gyms.length == 1))
                  SettingsSection(
                    footer: [
                      for (final gym in a.gyms)
                        if (gym.id == (store.shareMealsGym ?? a.gyms.single.id))
                          l.shareMealsNote(gym.name),
                    ].firstOrNull,
                    children: [
                      SettingsToggle(
                        key: const ValueKey('settings-share-meals'),
                        label: l.shareMealsSetting,
                        value: store.sharesMeals,
                        onChanged: (on) =>
                            store.setShareMeals(on ? a.gyms.single.id : null),
                      ),
                    ],
                  ),
                // 직원이면 에이전트 보고서로 가는 길. 목록 위 입구와 같은 곳이다.
                // 회원용 '다니는 체육관' 밖에 따로 둔다 — 그 안이면 직원만인
                // 사람이 '스티커에 폰을 대면…' 안내와 한 묶음으로 읽는다.
                if (a.staff.isNotEmpty)
                  SettingsSection(
                    title: l.settingsTrainer,
                    children: [
                      SettingsRow(
                        label: l.trainerReport,
                        accent: true,
                        onTap: () => openTrainer(context, a),
                      ),
                    ],
                  ),

                SettingsSection(
                  title: l.settingsAccount,
                  children: [
                    // **누구인지 보여주는 줄과 나가는 줄을 가른다.** 하나로 묶여
                    // 있을 때는 자기 이름을 눌러본 사람이 그대로 로그아웃됐다.
                    if (a.signedIn) ...[
                      // 로그인하면 제공자의 이름(대개 실명)이 그대로 닉네임이 된다. 바꿀 수
                      // 있어야 한다 — 이름과 바꾸는 길이 한 줄이다(›).
                      SettingsRow(
                        key: const ValueKey('settings-nickname'),
                        label: l.nicknameLabel,
                        detail: a.nickname,
                        onTap: () => _changeNickname(context, a),
                      ),
                      // 웹에서 쓰던 수단을 여기 붙이면 그쪽 기록·루틴이 같은 사람 것이
                      // 된다. 어느 수단이 붙었는지는 서버가 알려 줘야 안다.
                      if (a.providers.isNotEmpty)
                        for (final method in signInMethods)
                          if (!a.providers.contains(method.name))
                            SettingsRow(
                              key: ValueKey('settings-link-${method.name}'),
                              label: l.linkSignIn(providerName(l, method)),
                              // 실패 문구는 방금 시도한 수단의 줄에만 붙인다.
                              note: a.lastSignIn != method
                                  ? null
                                  : a.signInTaken
                                  ? l.signInTaken
                                  : a.signInRefused
                                  ? l.signInFailed
                                  : null,
                              onTap: () => a.signIn(method: method),
                            ),
                    ] else
                      SettingsRow(
                        label: l.accountSignIn,
                        // 서버가 막았으면 그렇다고 적는다. 눌러도 아무 일이 없는
                        // 것처럼 보이면 사람은 앱이 고장 난 줄 안다.
                        note: a.signInRefused ? l.signInFailed : null,
                        onTap: () => askSignIn(context, a),
                      ),
                    // 원판은 로그인 전에도 있다 — 그때는 이 기기의 지갑이다.
                    if (a.plates case final plates?)
                      SettingsRow(
                        key: const ValueKey('settings-plates'),
                        label: l.platesBalance(plates),
                      ),
                    if (a.selling || a.paid)
                      SettingsRow(label: l.restorePurchases, onTap: a.restore),
                    // **계정을 만들 수 있으면 앱 안에서 지울 수도 있어야 한다.**
                    // 웹으로 보내는 것은 그 답이 아니다.
                    if (a.signedIn) ...[
                      SettingsRow(label: l.accountSignOut, onTap: a.signOut),
                      // 잃어버린 폰·웹에 남은 로그인을 서버에서 끊는다. 이 폰은 남는다.
                      SettingsRow(
                        key: const ValueKey('settings-sign-out-everywhere'),
                        label: l.accountSignOutEverywhere,
                        onTap: () => _confirmSignOutEverywhere(context, a),
                      ),
                      SettingsRow(
                        label: l.accountDelete,
                        onTap: () => _confirmDelete(context, a),
                      ),
                    ],
                  ],
                ),
              ],
              // 쓰는 오픈소스의 고지문. 몸 그림 그림(MIT)의 조건이 고지문을 싣는 것이다.
              SettingsSection(
                children: [
                  SettingsRow(
                    key: const ValueKey('settings-licenses'),
                    label: l.openSourceLicenses,
                    onTap: () => showLicensePage(context: context),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 모든 기기에서 로그아웃. 한 번 묻고, 끊었는지 말한다 — 못 끊었는데 조용하면
  /// 잃어버린 폰이 끊긴 줄 안다.
  Future<void> _confirmSignOutEverywhere(
    BuildContext context,
    Account account,
  ) async {
    final l = L.of(context);
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.accountSignOutEverywhere),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l.accountSignOutEverywhereAsk,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            key: const ValueKey('sign-out-everywhere-confirm'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.accountSignOutEverywhere),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    final done = await account.signOutEverywhere();
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            done
                ? l.accountSignOutEverywhereDone
                : l.accountSignOutEverywhereFailed,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _changeNickname(BuildContext context, Account account) async {
    final l = L.of(context);
    final wanted = await showCupertinoDialog<String>(
      context: context,
      builder: (_) => _NicknameDialog(current: account.nickname),
    );
    if (wanted == null || !context.mounted) return;
    final problem = await account.changeNickname(wanted);
    if (problem == null || !context.mounted) return;
    await tellAgent(context, switch (problem) {
      'nicknameTaken' => l.nicknameTaken,
      'invalidNickname' => l.nicknameHelp,
      _ => l.partnerErrNetwork,
    });
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
          child: Text(l.accountDeleteAsk, style: const TextStyle(fontSize: 13)),
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
    // 서버가 왜 막았는지 말해 준다. 아무 말이 없으면 서버에 닿지 못한 것이다.
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            refusalMessage(
              L.of(ctx),
              problem,
              fallback: L.of(ctx).accountDeleteFailed,
            ),
            style: const TextStyle(fontSize: 13),
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

  /// The default rest between sets (15 s – 10 min), on a wheel — no
  /// keyboard. Each exercise's own rest, set on the stage, stays.
  Future<void> _pickRest(BuildContext context) => showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => ValueSheet(
      title: L.of(context).focusRestTitle,
      value: store.restSeconds,
      values: [for (var s = 15; s <= 600; s += 15) s],
      presets: const [60, 90, 120, 180],
      label: timerClock,
      onChanged: store.setRestSeconds,
    ),
  );

  /// The recorded voice of the counts and workout cues (English in every
  /// app language).
  Future<void> _pickVoice(BuildContext context) async {
    final l = L.of(context);
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.voiceSetting),
        message: Text(l.voiceSettingHelp),
        actions: [
          for (final (v, label) in [('m', l.voiceMale), ('w', l.voiceFemale)])
            CupertinoActionSheetAction(
              key: ValueKey('voice-$v'),
              isDefaultAction: v == store.voice,
              onPressed: () => Navigator.pop(ctx, v),
              child: Text('${v == store.voice ? '✓ ' : ''}$label'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
      ),
    );
    if (choice != null) store.setVoice(choice);
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

/// 닉네임 창. 처음 값은 그리기 전에 넣는다 — 치는 동안에는 칸에 손대지 않는다(IME).
class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.current});
  final String current;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final _field = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoAlertDialog(
      title: Text(l.nicknameChange),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l.nicknameHelp, style: const TextStyle(fontSize: 13)),
          ),
          CupertinoTextField(
            key: const ValueKey('nickname-field'),
            controller: _field,
            autofocus: true,
            maxLength: 20,
            onSubmitted: (text) => Navigator.pop(context, text),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          key: const ValueKey('nickname-save'),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, _field.text),
          child: Text(l.save),
        ),
      ],
    );
  }
}
