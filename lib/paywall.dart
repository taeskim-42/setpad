import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'l10n/generated/app_localizations.dart';
import 'palette.dart';
import 'purchases.dart';

/// 무료와 이용권의 차이. **서버가 정한 것과 같은 수여야 한다** —
/// app/api/record-query/route.ts 의 LIMITS 가 진짜다. 여기 적힌 것은 파는
/// 말이고, 다르면 산 사람이 속은 것이 된다.
const freeQuestionsPerMonth = 30;
const paidQuestionsPerDay = 200;

/// 이용권을 파는 화면.
///
/// **파는 것은 하나뿐이다.** 기록에 말로 묻는 것. 그 밖의 기록·타이머·건강
/// 앱 연동·체육관 연결은 이용권 없이 전부 된다. 그렇게 적어 둔다 — 다 막아
/// 놓은 것처럼 보이면 사기 전에 앱을 지운다.
class Paywall extends StatefulWidget {
  const Paywall({super.key, required this.account});
  final Account account;

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  bool _busy = false;

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
    final owned = account.plan;
    final prices = account.prices;
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);

    return AnimatedBuilder(
      animation: account,
      builder: (context, _) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(l.planMonthly)),
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
              const SizedBox(height: 24),

              _Compare(
                free: l.proFree(freeQuestionsPerMonth),
                paid: l.proPaid(paidQuestionsPerDay),
              ),
              const SizedBox(height: 20),

              Text(
                l.proEverythingElseFree,
                style: TextStyle(fontSize: 14, height: 1.45, color: muted),
              ),
              const SizedBox(height: 28),

              if (owned == Plan.lifetime)
                Text(
                  l.proOwned,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: seal.resolveFrom(context),
                  ),
                )
              else ...[
                if (!account.signedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      l.proSignInFirst,
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                  ),
                for (final plan in Plan.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BuyButton(
                      label: plan == Plan.monthly
                          ? l.planMonthly
                          : l.planLifetime,
                      // 값은 스토어가 준 문자열 그대로. 나라마다 통화도
                      // 자릿수도 다르고, 우리가 적으면 반드시 어긋난다.
                      price: prices[plan],
                      filled: plan == Plan.lifetime,
                      active: owned == plan,
                      onPressed: _busy || owned == plan || !account.signedIn
                          ? null
                          : () => _buy(plan),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
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
    return SizedBox(
      width: double.infinity,
      child: filled
          ? CupertinoButton.filled(onPressed: onPressed, child: Text(text))
          : CupertinoButton(
              color: CupertinoColors.secondarySystemGroupedBackground
                  .resolveFrom(context),
              onPressed: onPressed,
              child: Text(
                text,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
    );
  }
}
