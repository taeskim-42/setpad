import 'package:flutter/cupertino.dart';

import 'account.dart';
import 'gym.dart';
import 'l10n/generated/app_localizations.dart';
import 'notes.dart';
import 'palette.dart';

/// PT 예약 화면.
///
/// **액션시트가 아니라 화면이다.** 예전에는 시트 위에 이레가 줄로 쌓여 있었고,
/// 트레이너가 화요일에만 받아도 일곱 칸이 다 열려 있었다. 누르고 나서야
/// "그날은 빈 시간이 없어요"를 봤다. 약속을 잡는 화면은 달력을 먼저 보여
/// 주고, 받지 않는 날은 애초에 못 누르게 한다.
class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    required this.account,
    required this.gymId,
    this.store,
  });
  final Account account;
  final String gymId;

  /// 도장 소식을 적는 곳. 있으면 회원이 여기서 한 신청·취소를 소식에서 뺀다.
  final NotesStore? store;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  /// 오늘부터 이 날짜까지 고를 수 있다. 그보다 먼 날을 잡는 일은 드물다.
  static const _horizon = 28;

  Availability _state = Availability.empty;
  DateTime? _picked;
  bool _busy = false;
  String? _notice;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 예약 목록과 받는 요일을 먼저 받고, 고른 날이 있으면 그 날의 빈 시간까지.
  Future<void> _load({DateTime? day}) async {
    setState(() => _busy = true);
    final found = await widget.account.link.bookings(
      day: day,
      gymId: widget.gymId,
    );
    if (!mounted) return;
    setState(() {
      _state = found;
      _busy = false;
    });
  }

  Future<void> _pick(DateTime day) async {
    setState(() {
      _picked = day;
      _notice = null;
    });
    await _load(day: day);
  }

  Future<void> _book(DateTime at) async {
    setState(() => _busy = true);
    final before = {for (final b in _state.bookings) b.id};
    final problem = await widget.account.link.book(at, gymId: widget.gymId);
    if (!mounted) return;
    final l = L.of(context);
    setState(() {
      _notice = problem == null ? l.bookingSent : _failure(l, problem);
      _picked = problem == null ? null : _picked;
    });
    await _load(day: problem == null ? null : _picked);
    if (problem == null) {
      _mine([
        for (final b in _state.bookings)
          if (!before.contains(b.id)) b,
      ]);
    }
  }

  /// 회원이 여기서 한 신청·취소는 도장 소식이 아니다 — 첫 화면에 'PT 확정'·'PT 취소' 로
  /// 다시 뜨지 않게 본 것으로 적는다(gym.dart gymNews).
  void _mine(Iterable<Booking> bookings) {
    final store = widget.store, owner = widget.account.userId;
    if (store == null || owner == null || store.gymSeenOwner != owner) return;
    store.markGymSeen({
      for (final b in bookings)
        'b:${b.id}': bookingSeen(b.status, b.startsAt, b.trainer),
    });
  }

  /// 못 한 까닭. 서버가 적은 말(이용권이 끝났다, 담당이 바뀌었다, 시작 시각이
  /// 지났다)을 그대로 — 무엇이든 '빈 시간이 없다' 로 보이면 회원은 다른 날만 누른다.
  /// 말이 없으면 서버에 닿지 못한 것이다.
  String _failure(L l, String reason) =>
      reason.isEmpty ? l.partnerErrNetwork : reason;

  Future<void> _cancel(Booking booking) async {
    final l = L.of(context);
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l.bookingCancelAsk, style: const TextStyle(fontSize: 15)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.bookingCancel),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    final problem = await widget.account.link.cancelBooking(booking.id);
    if (!mounted) return;
    // 못 취소했으면 말한다. 목록에 그대로 남기만 하면 취소된 줄 알고 안 온다.
    if (problem != null) {
      setState(() => _notice = _failure(L.of(context), problem));
    } else {
      _mine([
        (
          id: booking.id,
          gym: booking.gym,
          trainer: booking.trainer,
          startsAt: booking.startsAt,
          status: 'cancelled',
        ),
      ]);
    }
    await _load(day: _picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // 시작 시각이 지난 것은 다가오는 예약이 아니다 — 취소도 서버가 받지 않는다.
    final now = DateTime.now();
    final upcoming = _state.bookings
        .where((b) => b.status == 'pending' || b.status == 'booked')
        .where((b) => b.startsAt.isAfter(now))
        .toList();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.bookingTitle)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _header(l),
            if (_notice != null) _banner(_notice!),
            if (upcoming.isNotEmpty) ...[
              _section(l.bookingUpcoming),
              for (final booking in upcoming) _bookingRow(l, booking),
            ],
            // 받을 시간을 안 열었으면 달력을 그릴 이유가 없다.
            if (_state.loaded && _state.receivesBookings && _state.hasPass) ...[
              _section(l.bookingPick),
              _calendar(l),
              if (_picked != null) _slots(l),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(L l) {
    final trainer = _state.trainer;
    final remaining = _state.remaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trainer != null)
            Text(
              l.bookingWith(trainer, _state.durationMin),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          const SizedBox(height: 4),
          // **못 하는 이유를 먼저 말한다.** 고를 수 있게 해 놓고 신청한
          // 뒤에 거절하면 회원은 앱이 고장 난 줄 안다.
          if (_state.loaded && !_state.hasPass)
            _why(_state.paused ? l.bookingPaused : l.bookingNoPass)
          else if (_state.loaded && !_state.receivesBookings)
            _why(l.bookingNoHours(trainer ?? ''))
          else if (remaining != null)
            Text(
              l.bookingRemaining(remaining),
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _why(String message) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      message,
      style: TextStyle(fontSize: 14, color: seal.resolveFrom(context)),
    ),
  );

  Widget _banner(String message) => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(message, style: const TextStyle(fontSize: 14)),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );

  Widget _bookingRow(L l, Booking booking) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    onPressed: _busy ? null : () => _cancel(booking),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_dayLabel(l, booking.startsAt)} ${_time(booking.startsAt)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              Text(
                booking.status == 'pending'
                    ? l.bookingPending
                    : l.bookingConfirmed,
                style: TextStyle(
                  fontSize: 13,
                  color: booking.status == 'pending'
                      ? seal.resolveFrom(context)
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
        Text(
          l.bookingCancel,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.destructiveRed,
          ),
        ),
      ],
    ),
  );

  /// 날짜 줄. **받지 않는 날은 아예 누를 수 없다.**
  Widget _calendar(L l) {
    final today = _today;
    final days = [
      for (var i = 0; i < _horizon; i++) today.add(Duration(days: i)),
    ];
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final open = _state.opensOn(day);
          final chosen = _picked != null && _sameDay(_picked!, day);
          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: open && !_busy ? () => _pick(day) : null,
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: chosen
                    ? seal.resolveFrom(context)
                    : CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.weekdayLabel(day),
                    style: TextStyle(
                      fontSize: 12,
                      color: chosen
                          ? CupertinoColors.white
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: chosen
                          ? CupertinoColors.white
                          : CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _slots(L l) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CupertinoActivityIndicator(),
      );
    }
    if (_state.slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Text(
          _state.opensOn(_picked!) ? l.bookingNone : l.bookingClosedDay,
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final slot in _state.slots)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _book(slot),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: seal.resolveFrom(context)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _time(slot),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: seal.resolveFrom(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _time(DateTime at) =>
      '${at.hour}:${at.minute.toString().padLeft(2, '0')}';

  String _dayLabel(L l, DateTime day) =>
      '${l.dayLabel(day)} · ${l.weekdayLabel(day)}';
}
