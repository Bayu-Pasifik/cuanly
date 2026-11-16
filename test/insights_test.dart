import 'package:cuanly/data/insights.dart';
import 'package:cuanly/ui/scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> t(String kind, String cat, num amt) => {'kind': kind, 'category': cat, 'amount': amt};

List<String> titles(List<Insight> l) => [for (final i in l) i.title];

void main() {
  final mid = DateTime(2026, 11, 15); // 15 of 30 days

  test('no transactions gives the empty-state hint only', () {
    final r = buildInsights(thisMonth: [], lastMonth: [t('expense', 'Makan', 1)], target: null, now: mid);
    expect(r.single.title, 'Belum ada transaksi bulan ini');
  });

  test('over target', () {
    final r = buildInsights(thisMonth: [t('expense', 'Makan', 600000)], lastMonth: [], target: 500000, now: mid);
    expect(titles(r), contains('Target bulan ini terlewati'));
  });

  test('on pace to exceed target', () {
    // 300k by day 15 -> 600k projected, target 500k.
    final r = buildInsights(thisMonth: [t('expense', 'Makan', 300000)], lastMonth: [], target: 500000, now: mid);
    expect(titles(r), contains('Pengeluaran melaju di atas target'));
  });

  test('on track against target', () {
    final r = buildInsights(thisMonth: [t('expense', 'Makan', 100000)], lastMonth: [], target: 500000, now: mid);
    expect(titles(r), contains('Pengeluaran sesuai target'));
  });

  test('no pace insight in the first days of the month', () {
    final r = buildInsights(
        thisMonth: [t('expense', 'Makan', 900000)], lastMonth: [], target: 500000, now: DateTime(2026, 11, 2));
    expect(titles(r), isNot(contains('Pengeluaran melaju di atas target')));
  });

  test('compares with last month when there is no target', () {
    final higher = buildInsights(
        thisMonth: [t('expense', 'Makan', 500000)], lastMonth: [t('expense', 'Makan', 600000)], target: null, now: mid);
    expect(titles(higher), contains('Pengeluaran lebih tinggi dari bulan lalu')); // 1.0M projected vs 600k
    final lower = buildInsights(
        thisMonth: [t('expense', 'Makan', 100000)], lastMonth: [t('expense', 'Makan', 600000)], target: null, now: mid);
    expect(titles(lower), contains('Pengeluaran lebih hemat dari bulan lalu'));
  });

  test('dominant category', () {
    final r = buildInsights(
        thisMonth: [t('expense', 'Makan', 80000), t('expense', 'Transport', 20000)], lastMonth: [], target: null, now: mid);
    expect(titles(r).any((x) => x.startsWith('Makan menyedot 80%')), isTrue);
  });

  test('category jump needs both a relative and an absolute increase', () {
    final jump = buildInsights(
        thisMonth: [t('expense', 'Belanja', 300000), t('expense', 'Makan', 10000)],
        lastMonth: [t('expense', 'Belanja', 100000)],
        target: null,
        now: mid);
    expect(titles(jump), contains('Belanja naik 200%'));
    final small = buildInsights(
        thisMonth: [t('expense', 'Belanja', 30000), t('expense', 'Makan', 10000)],
        lastMonth: [t('expense', 'Belanja', 10000)],
        target: null,
        now: mid);
    expect(titles(small).any((x) => x.contains('naik')), isFalse); // +20k is under 50k
  });

  test('savings rate', () {
    List<String> run(num inc, num exp) => titles(buildInsights(
        thisMonth: [t('income', 'Gaji', inc), t('expense', 'Makan', exp)], lastMonth: [], target: null, now: DateTime(2026, 11, 2)));
    expect(run(1000000, 1200000), contains('Pengeluaran lebih besar dari pemasukan'));
    expect(run(1000000, 950000), contains('Tabunganmu tipis'));
    expect(run(1000000, 500000), contains('Tabunganmu sehat'));
  });

  test('falls back to a calm message', () {
    final r = buildInsights(
        thisMonth: [t('income', 'Gaji', 1000000), t('expense', 'Makan', 850000)], lastMonth: [], target: null, now: DateTime(2026, 11, 2));
    expect(r.single.title, 'Keuanganmu stabil');
  });

  testWidgets('InsightCard renders title and body', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: InsightCard(insight: const Insight(InsightLevel.warning, 'Judul', 'Isi insight'))),
    ));
    expect(find.text('Judul'), findsOneWidget);
    expect(find.text('Isi insight'), findsOneWidget);
  });
}
