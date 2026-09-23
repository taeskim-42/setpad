import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'health_page.dart';
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'purchases.dart';
import 'share.dart';
import 'sign_in.dart';

/// 무료와 Pro 의 차이. **서버가 정한 것과 같은 수여야 한다** — 서버의 원판
/// 규칙이 진짜다(gymdojo lib/ai-quota.ts, lib/plate-pricing.ts). 여기 적힌 것은
/// 파는 말이고, 다르면 산 사람이 속은 것이 된다.
const freeInputPerDay = 10;
const proInputPerDay = 100;
const proPlatesPerMonth = 300;

/// App Store 의 표준 이용약관. 따로 약관을 두지 않은 앱은 이것을 건다.
const appleEulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// 이용권을 파는 화면.
///
/// **파는 것은 AI 도움뿐이다.** 기록 질문에 쓰는 원판과 적기 도움. 그 밖의
/// 기록·타이머·손목 알림·같이 하기·체육관은 이용권 없이 전부 된다. 그렇게
/// 적어 둔다 — 다 막아 놓은 것처럼 보이면 사기 전에 앱을 지운다.
class Paywall extends StatefulWidget {
  const Paywall({super.key, required this.account});
  final Account account;

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 달이 바뀌었으면 Pro 원판이 채워져 있다. 여기서 보이는 수가 맞아야 한다.
    unawaited(widget.account.refreshPlates());
  }

  Future<void> _buy(Plan plan) async {
    setState(() => _busy = true);
    try {
      await widget.account.buy(plan);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final account = widget.account;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);

    return AnimatedBuilder(
      animation: account,
      builder: (context, _) {
        // 산 뒤에 바뀌는 값이다. 밖에서 읽어 두면 산 뒤에도 옛 화면이 남는다.
        final owned = account.plan;
        final offers = account.offers;
        return CupertinoPageScaffold(
          // 제목을 두지 않는다. 무엇을 파는지는 아래 큰 글씨가 말하고,
          // 여기에 상품 하나의 이름을 쓰면 나머지 하나가 가려진다.
          navigationBar: const CupertinoNavigationBar(),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text(
                  l.proTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.proBody,
                  style: TextStyle(fontSize: 16, height: 1.45, color: muted),
                ),
                if (account.plates case final plates?) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.platesBalance(plates),
                    style: TextStyle(fontSize: 14, color: muted),
                  ),
                ],
                const SizedBox(height: 24),

                _Compare(
                  free: l.proFree(freeInputPerDay, dailyPlateSets),
                  paid: l.proPaid(proPlatesPerMonth, proInputPerDay),
                ),
                const SizedBox(height: 20),

                Text(
                  l.proEverythingElseFree,
                  style: TextStyle(fontSize: 14, height: 1.45, color: muted),
                ),
                const SizedBox(height: 28),

                if (owned != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      l.proOwned,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: seal.resolveFrom(context),
                      ),
                    ),
                  )
                else if (!account.signedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      l.proSignInFirst,
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                  ),
                // 서버가 구매를 안 받았다. 돈을 낸 사람이 기다리지 않게 말한다.
                if (account.purchaseProblem case final problem?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      problem == PurchaseProblem.otherAccount
                          ? l.purchaseOtherAccount
                          : l.purchaseNotConfirmed,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemRed.resolveFrom(context),
                      ),
                    ),
                  ),
                // 스토어가 값을 준 요금제만 판다. 값 없이 파는 단추나, 스토어가
                // 모르는 체험을 약속하는 글은 그리지 않는다. 가진 것은 늘 보인다.
                for (final plan in Plan.values)
                  if (offers[plan] != null || owned == plan)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          _BuyButton(
                            label: plan == Plan.yearly
                                ? l.planYearly
                                : l.planMonthly,
                            // 값은 스토어가 준 문자열 그대로. 나라마다 통화도
                            // 자릿수도 다르고, 우리가 적으면 반드시 어긋난다.
                            price: offers[plan]?.price,
                            filled: plan == Plan.yearly,
                            active: owned == plan,
                            // 바꾸는 것은 스토어의 구독 관리에서 한다. 여기서
                            // 하나 더 사면 구독이 둘이 되는 스토어가 있다.
                            onPressed:
                                _busy || owned != null || !account.signedIn
                                ? null
                                : () => _buy(plan),
                          ),
                          // 체험은 얼마 동안이고 끝나면 얼마가 나가는지, 사는
                          // 단추 바로 밑에 적는다. 스토어가 이 사람에게 체험을
                          // 줄 때만(자격이 없거나 오퍼가 없으면 바로 청구된다).
                          if (offers[plan] case (
                            :final price,
                            trialDays: final days?,
                            buy: _,
                          ) when plan == Plan.yearly && owned == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                l.planYearlyTrial(days, price),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                const SizedBox(height: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _busy ? null : account.restore,
                  child: Text(
                    l.restorePurchases,
                    style: TextStyle(fontSize: 14, color: muted),
                  ),
                ),
                // 자동 갱신 구독을 파는 화면에 있어야 하는 것: 갱신·해지 안내와
                // 약관·개인정보 링크(App Store 3.1.2).
                const SizedBox(height: 12),
                Text(
                  l.subscriptionRenews,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.4, color: muted),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    // 표준 EULA 는 App Store 구매의 약관이다. Play 에는 걸지 않는다.
                    if (platformSignIn != SignInMethod.google)
                      _Link(l.termsOfUse, () => openUrl(appleEulaUrl)),
                    _Link(
                      l.healthDataPrivacy,
                      () => openUrl(HealthDataPage.privacyUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    minimumSize: const Size(44, 44),
    onPressed: onPressed,
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        decoration: TextDecoration.underline,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}

/// 무료와 이용권을 나란히. 표 하나가 문장 열 줄보다 빨리 읽힌다.
class _Compare extends StatelessWidget {
  const _Compare({required this.free, required this.paid});
  final String free, paid;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(free, style: TextStyle(fontSize: 15, color: muted)),
          const SizedBox(height: 6),
          Text(
            paid,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: seal.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.label,
    required this.price,
    required this.filled,
    required this.active,
    required this.onPressed,
  });
  final String label;
  final String? price;
  final bool filled, active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = active
        ? '$label · ${l.planActive}'
        : price == null
        ? label
        : '$label · $price';
    final ink = seal.resolveFrom(context);
    return SizedBox(
      width: double.infinity,
      child: filled
          // 채운 쪽은 우리 색이다. CupertinoButton.filled 은 테마의 기본
          // 파랑을 쓰는데, 앱 어디에도 없는 색이라 여기만 남의 것처럼 보였다.
          ? CupertinoButton(
              color: ink,
              onPressed: onPressed,
              child: Text(
                text,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          // 안 채운 쪽에 테두리를 준다. 예전에는 배경과 같은 색을 칠해 둬서
          // 글자만 떠 있었고, 누를 수 있는 것으로 보이지 않았다.
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: ink, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoButton(
                onPressed: onPressed,
                child: Text(
                  text,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                ),
              ),
            ),
    );
  }
}
