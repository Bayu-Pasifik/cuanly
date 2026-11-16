import 'package:cuanly/data/travel.dart';
import 'package:cuanly/ui/travel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> ex(String d, num a, String by) => {'description': d, 'amount': a, 'paidBy': by};

void main() {
  test('equal split, balances and settlements', () {
    final s = splitTrip(['A', 'B', 'C'], [ex('Hotel', 300000, 'A'), ex('Makan', 150000, 'B')]);
    expect(s.total, 450000);
    expect(s.perPerson, 150000);
    expect(s.balances['A'], 150000);
    expect(s.balances['B'], 0);
    expect(s.balances['C'], -150000);
    expect(s.settlements, [(from: 'C', to: 'A', amount: 150000)]);
  });

  test('settlements square everyone up', () {
    final people = ['A', 'B', 'C', 'D'];
    final s = splitTrip(people, [ex('x', 100000, 'A'), ex('y', 40000, 'B'), ex('z', 10000, 'C')]);
    final net = {for (final p in people) p: s.balances[p]!.round()};
    for (final t in s.settlements) {
      net[t.from] = net[t.from]! + t.amount.toInt();
      net[t.to] = net[t.to]! - t.amount.toInt();
    }
    // Rounding may leave at most a rupiah per person.
    expect(net.values.every((v) => v.abs() <= 1), isTrue);
    expect(s.settlements.length, lessThanOrEqualTo(people.length - 1));
  });

  test('already even means no settlements', () {
    final s = splitTrip(['A', 'B'], [ex('x', 50000, 'A'), ex('y', 50000, 'B')]);
    expect(s.settlements, isEmpty);
    expect(s.balances.values.every((v) => v == 0), isTrue);
  });

  test('ignores non-positive amounts and unknown payers still count in total', () {
    final s = splitTrip(['A', 'B'], [ex('x', -5, 'A'), ex('y', 0, 'A'), ex('z', 100, 'Zed')]);
    expect(s.total, 100);
    expect(s.perPerson, 50);
    expect(s.balances['A'], -50);
  });

  test('no participants does not divide by zero', () {
    final s = splitTrip([], [ex('x', 100, 'A')]);
    expect(s.perPerson, 0);
    expect(s.settlements, isEmpty);
  });

  test('validateTrip', () {
    final ok = [ex('Hotel', 1000, 'A')];
    expect(validateTrip('Bali', ['A', 'B'], ok), isNull);
    expect(validateTrip(' ', ['A', 'B'], ok), isNotNull);
    expect(validateTrip('Bali', ['A'], ok), 'Minimal 2 peserta');
    expect(validateTrip('Bali', ['A', 'A'], ok), 'Nama peserta harus berbeda');
    expect(validateTrip('Bali', ['A', ''], ok), isNotNull);
    expect(validateTrip('Bali', ['A', 'B'], []), isNotNull);
    expect(validateTrip('Bali', ['A', 'B'], [ex('x', 0, 'A')]), isNotNull);
    expect(validateTrip('Bali', ['A', 'B'], [ex('x', 5, null.toString())]), isNotNull);
  });

  test('stored row helpers tolerate missing columns', () {
    final row = {
      'participants': [{'name': 'A'}, {'name': 'B'}],
      'expenses': [ex('x', 10, 'A')],
    };
    expect(tripPeople(row), ['A', 'B']);
    expect(tripExpenses(row).single['amount'], 10);
    expect(tripPeople({}), isEmpty);
    expect(tripExpenses({}), isEmpty);
  });

  testWidgets('SplitSummary shows per person and who pays whom', (tester) async {
    final people = ['Ani', 'Budi'];
    final expenses = [ex('Hotel', 200000, 'Ani')];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SplitSummary(people: people, expenses: expenses, split: splitTrip(people, expenses)),
        ),
      ),
    ));
    expect(find.text('Rp 200.000'), findsWidgets);
    expect(find.textContaining('Rp 100.000 per orang'), findsOneWidget);
    expect(find.text('Budi ke Ani'), findsOneWidget);
    expect(find.text('Dapat Rp 100.000'), findsOneWidget);
    expect(find.text('Bayar Rp 100.000'), findsOneWidget);
  });
}
