import 'package:cuanly/data/business.dart';
import 'package:cuanly/ui/business.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> prod(String id, String name, num price, num cost) => {'id': id, 'name': name, 'price': price, 'cost': cost};

void main() {
  test('cart merges repeated products and totals', () {
    final c = Cart()
      ..add(prod('a', 'Kopi', 15000, 6000))
      ..add(prod('a', 'Kopi', 15000, 6000))
      ..add(prod('b', 'Roti', 10000, 4000));
    expect(c.lines.length, 2);
    expect(c.count, 3);
    expect(c.total, 40000);
    expect(c.costTotal, 16000);
  });

  test('setQty changes quantity and removes at zero', () {
    final c = Cart()..add(prod('a', 'Kopi', 15000, 6000));
    c.setQty('a', 3);
    expect(c.total, 45000);
    c.setQty('a', 0);
    expect(c.isEmpty, isTrue);
    c.setQty('missing', 5); // no-op
    expect(c.isEmpty, isTrue);
  });

  test('product without cost counts as zero cost', () {
    final c = Cart()..add({'id': 'x', 'name': 'Jasa', 'price': 50000, 'cost': null});
    expect(c.costTotal, 0);
  });

  test('changeFor', () {
    expect(changeFor(40000, 50000), 10000);
    expect(changeFor(40000, 40000), 0);
    expect(changeFor(40000, 30000), isNull);
  });

  test('businessReport computes profit, margin and best sellers', () {
    final sales = [
      {'total': 40000, 'cost_total': 16000, 'items': [
        {'name': 'Kopi', 'qty': 2, 'price': 15000, 'cost': 6000},
        {'name': 'Roti', 'qty': 1, 'price': 10000, 'cost': 4000},
      ]},
      {'total': 30000, 'cost_total': 12000, 'items': [
        {'name': 'Kopi', 'qty': 2, 'price': 15000, 'cost': 6000},
      ]},
    ];
    final r = businessReport(sales, [{'amount': 20000}]);
    expect(r.revenue, 70000);
    expect(r.cogs, 28000);
    expect(r.grossProfit, 42000);
    expect(r.expenses, 20000);
    expect(r.netProfit, 22000);
    expect(r.saleCount, 2);
    expect(r.margin, closeTo(22000 / 70000, 1e-9));
    expect(r.top.first.name, 'Kopi');
    expect(r.top.first.qty, 4);
    expect(r.top.first.revenue, 60000);
  });

  test('empty report has no margin and no loss', () {
    final r = businessReport([], []);
    expect(r.netProfit, 0);
    expect(r.margin, isNull);
    expect(r.top, isEmpty);
  });

  test('expenses can make a loss', () {
    final r = businessReport([{'total': 10000, 'cost_total': 4000, 'items': []}], [{'amount': 20000}]);
    expect(r.netProfit, -14000);
  });

  test('receiptText for cash with change and footer', () {
    final lines = [CartLine(productId: 'a', name: 'Kopi', price: 15000, cost: 0, qty: 2)];
    final t = receiptText(
        businessName: 'Warung Ani', footer: 'Terima kasih!', lines: lines, method: 'cash', date: DateTime(2026, 11, 5), received: 50000);
    expect(t, contains('Warung Ani'));
    expect(t, contains('05/11/2026'));
    expect(t, contains('2 x Rp 15.000 = Rp 30.000'));
    expect(t, contains('TOTAL: Rp 30.000'));
    expect(t, contains('Bayar (Tunai): Rp 50.000'));
    expect(t, contains('Kembali: Rp 20.000'));
    expect(t, endsWith('Terima kasih!'));
  });

  test('receiptText for QRIS has no change line', () {
    final lines = [CartLine(productId: 'a', name: 'Kopi', price: 15000, cost: 0)];
    final t = receiptText(businessName: '', lines: lines, method: 'qris', date: DateTime(2026, 1, 2), received: 20000);
    expect(t, startsWith('Struk'));
    expect(t, isNot(contains('Kembali')));
  });

  testWidgets('report card shows profit and loss states', (tester) async {
    Future<void> show(BusinessReport r) => tester.pumpWidget(MaterialApp(home: Scaffold(body: BusinessReportCard(report: r))));
    await show(businessReport([{'total': 100000, 'cost_total': 40000, 'items': []}], [{'amount': 10000}]));
    expect(find.text('Laba bersih'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsWidgets);
    await show(businessReport([{'total': 10000, 'cost_total': 4000, 'items': []}], [{'amount': 20000}]));
    expect(find.text('Rugi bersih'), findsOneWidget);
    expect(find.text('-Rp 14.000'), findsOneWidget);
  });
}
