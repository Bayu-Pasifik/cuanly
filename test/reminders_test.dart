import 'package:flutter_test/flutter_test.dart';
import 'package:cuanly/data/reminders.dart';

Map<String, dynamic> debt(String person, String? due, {num total = 100, num paid = 0, String dir = 'owe'}) =>
    {'id': person, 'person': person, 'direction': dir, 'total': total, 'paid': paid, 'due_on': due};

void main() {
  final now = DateTime(2026, 11, 16, 14, 30);

  test('classifies overdue, today and soon, most urgent first', () {
    final r = dueDebts([
      debt('far', '2026-11-30'),
      debt('soon3', '2026-11-19'),
      debt('today', '2026-11-16'),
      debt('late5', '2026-11-11'),
      debt('late1', '2026-11-15'),
      debt('tomorrow', '2026-11-17'),
    ], now);
    expect(r.map((d) => d.debt['person']), ['late5', 'late1', 'today', 'tomorrow', 'soon3']);
    expect(r.first.status, DueStatus.overdue);
    expect(r.first.days, 5);
    expect(dueLabel(r[2]), 'Jatuh tempo hari ini');
    expect(dueLabel(r[3]), 'Jatuh tempo besok');
    expect(dueLabel(r[4]), 'Jatuh tempo 3 hari lagi');
    expect(dueLabel(r[0]), 'Terlambat 5 hari');
  });

  test('ignores settled debts and debts without due date', () {
    final r = dueDebts([debt('paid', '2026-11-16', paid: 100), debt('none', null)], now);
    expect(r, isEmpty);
  });

  test('remaining and direction', () {
    final r = dueDebts([debt('x', '2026-11-16', total: 500, paid: 120, dir: 'lent')], now).single;
    expect(r.remaining, 380);
    expect(r.owe, isFalse);
  });
}
