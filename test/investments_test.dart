import 'package:cuanly/data/investments.dart';
import 'package:cuanly/ui/investments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> inv(String type, num cap, num? val, {String status = 'active'}) =>
    {'investment_type': type, 'amount': cap, 'current_value': val, 'status': status, 'purchase_date': '2026-01-01', 'notes': null};

void main() {
  test('summarize counts only active rows', () {
    final p = summarize([
      inv('Emas', 1000000, 1100000),
      inv('BTC', 500000, 400000),
      inv('SPY', 9999999, 9999999, status: 'sold'),
    ]);
    expect(p.capital, 1500000);
    expect(p.value, 1500000);
    expect(p.gain, 0);
    expect(p.gainPercent, 0);
    expect(p.byType.first.type, 'Emas'); // biggest first
  });

  test('gain and percent', () {
    final p = summarize([inv('Emas', 1000000, 1250000)]);
    expect(p.gain, 250000);
    expect(p.gainPercent, closeTo(25, 1e-9));
  });

  test('missing current value falls back to capital; empty portfolio has no percent', () {
    expect(summarize([inv('Emas', 100, null)]).value, 100);
    final empty = summarize([]);
    expect(empty.gainPercent, isNull);
    expect(empty.byType, isEmpty);
  });

  test('same type rows are merged in allocation', () {
    final p = summarize([inv('Emas', 100, 100), inv('Emas', 50, 60)]);
    expect(p.byType.single.value, 160);
  });

  test('every risk profile sums to 100% and only uses known types', () {
    for (final e in riskProfiles.entries) {
      expect(e.value.allocation.fold<int>(0, (a, x) => a + x.percent), 100, reason: e.key);
      for (final a in e.value.allocation) {
        expect(investmentTypes.any((t) => t.code == a.type), isTrue, reason: a.type);
      }
    }
  });

  test('recommendedAmounts splits the total', () {
    final r = recommendedAmounts('conservative', 1000000);
    expect(r.map((x) => x.amount), [500000, 300000, 200000]);
    expect(r.fold<num>(0, (a, x) => a + x.amount), 1000000);
  });

  test('unknown type falls back to Lainnya', () {
    expect(investmentType('XYZ').code, 'Lainnya');
    expect(investmentType('BTC').risk, Risk.veryHigh);
  });

  testWidgets('portfolio card shows value, capital and gain', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PortfolioCard(portfolio: summarize([inv('Emas', 1000000, 1100000)]))),
    ));
    expect(find.text('Rp 1.100.000'), findsOneWidget);
    expect(find.text('Modal Rp 1.000.000'), findsOneWidget);
    expect(find.text('+Rp 100.000 (+10.0%)'), findsOneWidget);
  });

  testWidgets('recommendation sheet shows rupiah per type', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RecommendationSheet(initialTotal: 1000000))));
    await tester.tap(find.text('Konservatif'));
    await tester.pump();
    expect(find.text('Rp 500.000'), findsOneWidget);
    expect(find.text('RDPU  50%'), findsOneWidget);
  });
}
