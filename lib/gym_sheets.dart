import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'account.dart';
import 'l10n/generated/app_localizations.dart';
import 'nearby.dart';
import 'palette.dart';
import 'partner.dart';
import 'set_grid.dart';

String partnerErrorText(L l, PartnerError error) => switch (error) {
  PartnerError.signInRequired => l.partnerSignIn,
  PartnerError.invalidFormat => l.partnerErrFormat,
  PartnerError.invalidCode => l.partnerErrInvalid,
  PartnerError.expired => l.partnerErrExpired,
  PartnerError.ended => l.partnerErrEnded,
  PartnerError.ownInvite => l.partnerErrOwn,
  PartnerError.tooManyTries => l.partnerErrTries,
  PartnerError.network => l.partnerErrNetwork,
  PartnerError.server => l.partnerErrServer,
};

/// 같이 하기.
///
/// **코드를 쓰는 이유는 짝이 계속 바뀌기 때문이다.** 헬스장에서는 그날 옆에
/// 있는 사람이 봐준다. 사람끼리 관계로 묶으면 끊는 일이 생기는데, 그날로
/// 끝나면 그럴 일이 없다.
///
/// 이 창은 상태를 **보여 주기만** 한다. 닫아도 세션은 그대로이고, 다시 열면
/// 같은 상태가 나온다 — 연결이 알림창과 함께 사라지던 구조를 없앴다.
Future<void> showPartnerSheet(
  BuildContext context,
  Account account,
  PartnerSync sync, {
  VoidCallback? onWriteFor,
}) => showCupertinoModalPopup<void>(
  context: context,
  builder: (_) =>
      _PartnerSheet(account: account, sync: sync, onWriteFor: onWriteFor),
);

class _PartnerSheet extends StatefulWidget {
  const _PartnerSheet({
    required this.account,
    required this.sync,
    this.onWriteFor,
  });
  final Account account;
  final PartnerSync sync;

  /// 상대의 세트를 대신 적기 시작한다. 같이 하기로 연결하지 않았어도 된다 —
  /// 폰을 사물함에 둔 사람의 것을 적어 두었다가 링크로 건넬 수 있다.
  final VoidCallback? onWriteFor;
  @override
  State<_PartnerSheet> createState() => _PartnerSheetState();
}

class _PartnerSheetState extends State<_PartnerSheet> {
  final _code = TextEditingController();
  bool _typing = false;
  Timer? _tick;
  bool _nearby = false;
  String? _offered;

  /// 기다리는 초대가 있으면 가까이 대서 건넬 수 있게 걸어 두고, 없어지면 거둔다.
  void _syncNearby() {
    final session = sync.session;
    final token = session?.state == PartnerState.waiting
        ? session!.token
        : null;
    if (token == _offered) return;
    _offered = token;
    token == null
        ? Nearby.instance.clear()
        : Nearby.instance.offer(
            kind: 'session',
            token: token,
            title: widget.account.nickname,
          );
  }

  PartnerSync get sync => widget.sync;
  void _changed() {
    _syncNearby();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    sync.addListener(_changed);
    widget.account.addListener(_changed);
    Nearby.instance.supported.then((ok) {
      if (!mounted) return;
      setState(() => _nearby = ok);
      _syncNearby();
    });
    // 남은 시간을 1초마다 다시 그린다.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _changed());
  }

  @override
  void dispose() {
    _tick?.cancel();
    Nearby.instance.clear();
    sync.removeListener(_changed);
    widget.account.removeListener(_changed);
    // 창을 닫는 것은 취소가 아니다. 보낸 요청은 끝까지 가고, 결과는 문서 위의
    // 상태 줄에 나타난다. 그만두려면 "취소" 를 누른다.
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final session = sync.session;
    final error = sync.error;
    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.partnerInvite,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (!widget.account.signedIn) ...[
                Text(l.partnerSignIn, style: TextStyle(color: muted)),
                CupertinoButton.filled(
                  // 로그인하고 나면 이 창이 그대로 다음 단계를 보여 준다.
                  onPressed: () => widget.account.signIn(),
                  child: Text(l.partnerSignInAction),
                ),
              ] else if (session?.state == PartnerState.active)
                ..._active(l, session!, muted)
              else if (session?.state == PartnerState.waiting && session!.host)
                ..._waiting(l, session, muted)
              else
                ..._start(l, session, muted),
              if (error != null && widget.account.signedIn)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    partnerErrorText(l, error),
                    key: const ValueKey('partner-error'),
                    style: TextStyle(
                      fontSize: 13,
                      color: seal.resolveFrom(context),
                    ),
                  ),
                ),
              if (widget.onWriteFor != null && widget.account.signedIn)
                CupertinoButton(
                  key: const ValueKey('sheet-write-for'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onWriteFor!();
                  },
                  child: Text(
                    L.of(context).proxyWrite,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              if (sync.busy)
                CupertinoButton(
                  key: const ValueKey('partner-cancel'),
                  onPressed: sync.cancel,
                  child: Text(l.cancel),
                ),
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.ok),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 아직 아무와도 잇지 않았다(또는 끝났다, 만료됐다).
  List<Widget> _start(L l, PartnerSession? session, Color muted) => [
    if (session?.state == PartnerState.ended)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          session!.endedByMe ?? true
              ? l.partnerEndedByMe
              : l.partnerEndedByThem(session.partnerName ?? ''),
          style: TextStyle(fontSize: 13, color: muted),
        ),
      ),
    if (session?.state == PartnerState.expired)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          l.partnerExpired,
          style: TextStyle(fontSize: 13, color: muted),
        ),
      ),
    if (_typing) ...[
      CupertinoTextField(
        key: const ValueKey('partner-code'),
        controller: _code,
        autofocus: true,
        // 헬스장에서 불러 주는 코드다. 자판을 오래 두드릴 자리가 아니다.
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        maxLength: 8,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, letterSpacing: 5),
        onSubmitted: (_) => sync.joinWithCode(_code.text),
      ),
      const SizedBox(height: 8),
      CupertinoButton.filled(
        onPressed: sync.busy ? null : () => sync.joinWithCode(_code.text),
        child: sync.busy
            ? const CupertinoActivityIndicator()
            : Text(
                sync.error == PartnerError.network ||
                        sync.error == PartnerError.server
                    ? l.partnerRetry
                    : l.partnerEnter,
              ),
      ),
    ] else ...[
      CupertinoButton.filled(
        onPressed: sync.busy ? null : () => sync.invite(),
        child: sync.busy
            ? const CupertinoActivityIndicator()
            : Text(l.partnerMakeCode),
      ),
      const SizedBox(height: 8),
      CupertinoButton(
        onPressed: () => setState(() => _typing = true),
        child: Text(l.partnerEnter),
      ),
    ],
  ];

  /// 코드를 띄우고 상대를 기다린다. 상대가 들어오면 이 화면이 저절로 바뀐다.
  List<Widget> _waiting(L l, PartnerSession session, Color muted) {
    final left = session.expiresAt?.difference(DateTime.now());
    final over = left == null || left.isNegative;
    String two(int n) => n.toString().padLeft(2, '0');
    return [
      Text(l.partnerCode, style: TextStyle(fontSize: 13, color: muted)),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            session.code ?? '',
            key: const ValueKey('partner-code-shown'),
            style: const TextStyle(
              fontSize: 34,
              letterSpacing: 6,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 12),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: session.code ?? '')),
            child: Icon(
              CupertinoIcons.doc_on_doc,
              size: 20,
              semanticLabel: l.partnerCopy,
            ),
          ),
        ],
      ),
      Text(
        over
            ? l.partnerExpired
            : l.partnerExpiresIn(
                '${left.inMinutes}:${two(left.inSeconds % 60)}',
              ),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: muted),
      ),
      if (!sync.reachable)
        Text(
          l.partnerReconnecting,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: muted),
        ),
      // 되는 아이폰에서만 말한다. 안 되는 기기에 "맞대세요" 라고 하지 않는다.
      if (_nearby)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l.nearbyHint,
            key: const ValueKey('nearby-hint'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted),
          ),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            onPressed: sync.busy ? null : () => sync.invite(renew: true),
            child: Text(l.partnerNewCode),
          ),
          CupertinoButton(
            onPressed: sync.busy ? null : sync.end,
            child: Text(l.partnerStopWaiting),
          ),
        ],
      ),
    ];
  }

  /// 같이 운동 중. 상대의 기록을 **읽기만** 한다.
  List<Widget> _active(L l, PartnerSession session, Color muted) => [
    Text(
      l.partnerWith(session.partnerName ?? ''),
      style: const TextStyle(fontSize: 15),
    ),
    if (!sync.reachable)
      Text(l.partnerReconnecting, style: TextStyle(fontSize: 13, color: muted)),
    if (sync.conflict != null) ...[
      Text(
        l.partnerConflict,
        style: TextStyle(fontSize: 13, color: seal.resolveFrom(context)),
      ),
      CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: sync.shareThisDevice,
        child: Text(
          l.partnerShareThisDevice,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ],
    // 초대가 살아 있고 자리가 있으면 한 명 더 들어올 수 있다. 호스트에게만 코드가 온다.
    if (session.code != null && session.room > 0)
      CupertinoButton(
        key: const ValueKey('invite-more'),
        padding: EdgeInsets.zero,
        onPressed: () =>
            Clipboard.setData(ClipboardData(text: session.code ?? '')),
        child: Text(
          l.partnerInviteMore(session.code!),
          style: const TextStyle(fontSize: 14),
        ),
      )
    else if (session.host && session.room > 0)
      CupertinoButton(
        key: const ValueKey('invite-more'),
        padding: EdgeInsets.zero,
        onPressed: sync.busy ? null : () => sync.invite(renew: true),
        child: Text(l.partnerNewCode, style: const TextStyle(fontSize: 14)),
      ),
    const SizedBox(height: 10),
    ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
      ),
      child: !session.partnerLoaded
          // 아직 못 받은 것과 기록이 없는 것은 다르다. 빈 화면을 "없음" 으로
          // 보여 주면 데이터가 사라진 것처럼 보인다.
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const CupertinoActivityIndicator(),
                  Text(
                    l.partnerLoading,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ],
              ),
            )
          : ListView(
              shrinkWrap: true,
              children: [
                // 사람마다 한 묶음. 볼 수만 있다 — 남의 기록을 여기서 고치는 길은 없다.
                for (final person
                    in session.others.isNotEmpty
                        ? session.others
                        : [
                            PartnerPerson(
                              key: '',
                              name: session.partnerName ?? '',
                              blocks: session.partnerBlocks,
                            ),
                          ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(
                      '${l.partnerTheirRecord(person.name)} · ${l.partnerReadOnly}',
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  ),
                  if (person.blocks.isEmpty)
                    Text(
                      l.partnerNoRecordYet,
                      style: TextStyle(fontSize: 13, color: muted),
                    )
                  else
                    for (final block in person.blocks)
                      BlockSummary(block: block),
                ],
              ],
            ),
    ),
    CupertinoButton(
      onPressed: sync.busy
          ? null
          : () async {
              await sync.end();
            },
      child: Text(
        l.partnerEnd,
        style: const TextStyle(color: CupertinoColors.destructiveRed),
      ),
    ),
  ];
}
