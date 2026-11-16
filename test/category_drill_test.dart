import 'package:cuanly/data/category_drill.dart';
import 'package:cuanly/ui/category_drill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> tx(String kind, String cat, num amt, String on, [String? note]) =>
    {'kind': kind, 'category': cat, 'amount': amt, 'occurred_on': on, 'note': note};

void main() {
  final rows = [
    tx('expense', 'Makan', 30000, '2026-11-03', 'Bakso'),
    tx('expense', 'Makan', 20000, '2026-11-10'),
    tx('expense', 'Makan', 40000, '2026-10-15'),
    tx('expense', 'Transport', 50000, '2026-11-04'),
    tx('income', 'Makan', 99999, '2026-11-05'), // other kind, must not count
    tx('expense', 'Makan', 5000, '2026-05-01'), // outside the 6-month window
  ];

  test('categoryMonthly sums per month for one category and kind, oldest first', () {
    final m = categoryMonthly(rows, 'Makan', 'expense', DateTime(2026, 11, 20));
    expect(m.length, 6);
    expect(m.first.month, DateTime(2026, 6));
    expect(m.last.month, DateTime(2026, 11));
    expect(m.last.total, 50000);
    expect(m[m.length - 2].total, 40000);
    expect(m.take(4).every((x) => x.total == 0), isTrue); // Jun..Sep, May is outside
  });

  test('categoryMonthly crosses the year boundary', () {
    final m = categoryMonthly([tx('expense', 'Makan', 1, '2025-12-31')], 'Makan', 'expense', DateTime(2026, 2, 1), months: 3);
    expect([for (final x in m) x.month], [DateTime(2025, 12), DateTime(2026, 1), DateTime(2026, 2)]);
    expect(m.first.total, 1);
  });

  test('shareOf', () {
    expect(shareOf(25, 100), .25);
    expect(shareOf(5, 0), 0);
    expect(shareOf(5, -1), 0);
  });

  test('monthKey pads', () {
    expect(monthKey(DateTime(2026, 3)), '2026-03');
  });

  testWidgets('body shows total, share, change and the month transactions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryDrillBody(rows: rows, category: 'Makan', kind: 'expense', month: DateTime(2026, 11)),
        ),
      ),
    ));
    expect(find.text('Rp 50.000'), findsWidgets);
    expect(find.text('50% dari pengeluaran bulan ini'), findsOneWidget); // 50k of 100k
    expect(find.text('+25% dari bulan lalu'), findsOneWidget); // 50k vs 40k
    expect(find.text('Transaksi (2)'), findsOneWidget);
    expect(find.text('Bakso'), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-11')), findsOneWidget);
  });

  testWidgets('body handles an empty month', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryDrillBody(rows: const [], category: 'Makan', kind: 'expense', month: DateTime(2026, 11)),
        ),
      ),
    ));
    expect(find.text('Rp 0'), findsOneWidget);
    expect(find.text('Belum ada transaksi di bulan ini.'), findsOneWidget);
  });
}
