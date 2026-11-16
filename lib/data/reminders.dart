import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'repo.dart';

/// How urgent an unpaid debt is relative to its due date.
enum DueStatus { overdue, today, soon }

class DueDebt {
  const DueDebt(this.debt, this.status, this.days);
  final Map<String, dynamic> debt;
  final DueStatus status;

  /// Days past due (overdue), 0 (today) or days left (soon).
  final int days;

  num get remaining => (debt['total'] as num) - (debt['paid'] as num);
  bool get owe => debt['direction'] == 'owe';
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Unpaid debts that are overdue, due today, or due within [soonDays] days, most urgent first.
List<DueDebt> dueDebts(List<Map<String, dynamic>> debts, DateTime now, {int soonDays = 3}) {
  final today = _day(now);
  final out = <DueDebt>[];
  for (final d in debts) {
    final due = d['due_on'] as String?;
    if (due == null || (d['paid'] as num) >= (d['total'] as num)) continue;
    final diff = _day(DateTime.parse(due)).difference(today).inDays;
    if (diff < 0) {
      out.add(DueDebt(d, DueStatus.overdue, -diff));
    } else if (diff == 0) {
      out.add(DueDebt(d, DueStatus.today, 0));
    } else if (diff <= soonDays) {
      out.add(DueDebt(d, DueStatus.soon, diff));
    }
  }
  out.sort((a, b) {
    final c = a.status.index.compareTo(b.status.index);
    if (c != 0) return c;
    return a.status == DueStatus.overdue ? b.days.compareTo(a.days) : a.days.compareTo(b.days);
  });
  return out;
}

String dueLabel(DueDebt d) => switch (d.status) {
      DueStatus.overdue => 'Terlambat ${d.days} hari',
      DueStatus.today => 'Jatuh tempo hari ini',
      DueStatus.soon => d.days == 1 ? 'Jatuh tempo besok' : 'Jatuh tempo ${d.days} hari lagi',
    };

String _money(num v) => 'Rp ${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

String _who(Map<String, dynamic> debt) =>
    debt['direction'] == 'owe' ? 'Utang ke ${debt['person']}' : 'Piutang dari ${debt['person']}';

/// Stable positive notification id for a debt (two slots: 0 = day before, 1 = on the day).
int _id(String debtId, int slot) => (debtId.hashCode.abs() % 1000000) * 2 + slot + 10;

/// Local notifications for debt due dates.
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _summaryId = 1;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'debt_due',
      'Jatuh tempo utang',
      channelDescription: 'Pengingat utang dan piutang yang jatuh tempo',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    _ready = true;
  }

  /// Rebuilds all reminders from [debts]: one at 09:00 the day before and one at 09:00 on the due date
  /// (only future ones), plus an immediate summary for anything overdue or due today.
  /// Best effort: notification problems never affect the app.
  static Future<void> sync(List<Map<String, dynamic>> debts, {DateTime? now}) async {
    if (kIsWeb) return;
    try {
      await _init();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.requestNotificationsPermission() == false) return;
      await _plugin.cancelAll();

      final clock = now ?? DateTime.now();
      for (final d in debts) {
        final due = d['due_on'] as String?;
        if (due == null || (d['paid'] as num) >= (d['total'] as num)) continue;
        final day = _day(DateTime.parse(due));
        final left = (d['total'] as num) - (d['paid'] as num);
        for (final (slot, at, text) in [
          (0, DateTime(day.year, day.month, day.day - 1, 9), 'jatuh tempo besok'),
          (1, DateTime(day.year, day.month, day.day, 9), 'jatuh tempo hari ini'),
        ]) {
          if (!at.isAfter(clock)) continue;
          await _plugin.zonedSchedule(
            id: _id(d['id'], slot),
            title: _who(d),
            body: '${_money(left)} $text',
            // Same instant as the local wall-clock time; no timezone database needed for one-shot alarms.
            scheduledDate: tz.TZDateTime.from(at, tz.UTC),
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }

      final urgent = dueDebts(debts, clock).where((d) => d.status != DueStatus.soon).toList();
      if (urgent.isNotEmpty) {
        await _plugin.show(
          id: _summaryId,
          title: urgent.length == 1 ? _who(urgent.first.debt) : '${urgent.length} utang perlu perhatian',
          body: urgent.length == 1
              ? '${_money(urgent.first.remaining)} - ${dueLabel(urgent.first).toLowerCase()}'
              : urgent.map((d) => '${_who(d.debt)} ${_money(d.remaining)} (${dueLabel(d).toLowerCase()})').join('\n'),
          notificationDetails: _details,
        );
      }
    } catch (e) {
      debugPrint('Reminders.sync failed: $e');
    }
  }
}
