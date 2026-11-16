import 'package:flutter_test/flutter_test.dart';
import 'package:cuanly/ui/reports.dart';

Map<String, dynamic> tx(String kind, num amount, String cat, String date) =>
    {'kind': kind, 'amount': amount, 'category': cat, 'occurred_on': date, 'note': null};

void main() {
  test('Period totals, categories and saving rate', () {
    final p = Period([
      tx('income', 1000, 'Gaji', '2026-11-01'),
      tx('expense', 200, 'Makan', '2026-11-02'),
      tx('expense', 300, 'Makan', '2026-11-03'),
      tx('expense', 100, 'Transport', '2026-12-04'),
    ], false);
    expect(p.income, 1000);
    expect(p.expense, 600);
    expect(p.net, 400);
    expect(p.byCategory['Makan'], 500);
    expect(p.savingRate, closeTo(0.4, 1e-9));
    expect(p.monthlyExpense[11], 500);
    expect(p.monthlyExpense[12], 100);
    expect(p.biggest!['amount'], 300);
  });

  test('saving rate is null without income', () {
    expect(Period([tx('expense', 5, 'x', '2026-01-01')], true).savingRate, isNull);
  });

  test('pctChange', () {
    expect(pctChange(150, 100), 50);
    expect(pctChange(50, 100), -50);
    expect(pctChange(10, 0), isNull);
  });
}
