import 'package:cuanly/data/challenges.dart';
import 'package:cuanly/ui/challenges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> ch({String cat = 'Makan,Hiburan', num limit = 100000, String s = '2026-11-10', String e = '2026-11-16', bool renew = false}) =>
    {'title': 'Hemat', 'category': cat, 'budget_limit': limit, 'start_date': s, 'end_date': e, 'auto_renew': renew};

Map<String, dynamic> tx(String cat, num amt, String on, {String kind = 'expense'}) =>
    {'kind': kind, 'category': cat, 'amount': amt, 'occurred_on': on};

void main() {
  final now = DateTime(2026, 11, 12, 15);

  test('splitCategories trims and drops blanks', () {
    expect(splitCategories('Makan, Hiburan,,'), ['Makan', 'Hiburan']);
    expect(splitCategories(''), isEmpty);
  });

  test('counts only matching expenses inside the range', () {
    final p = challengeProgress(ch(), [
      tx('Makan', 30000, '2026-11-10'), // start day counts
      tx('Hiburan', 20000, '2026-11-16'), // end day counts
      tx('Makan', 99999, '2026-11-09'), // before range
      tx('Makan', 99999, '2026-11-17'), // after range
      tx('Transport', 50000, '2026-11-12'), // other category
      tx('Makan', 70000, '2026-11-12', kind: 'income'), // not an expense
    ], now);
    expect(p.spent, 50000);
    expect(p.remaining, 50000);
    expect(p.over, isFalse);
    expect(p.ratio, closeTo(.5, 1e-9));
  });

  test('over the limit', () {
    final p = challengeProgress(ch(limit: 40000), [tx('Makan', 45000, '2026-11-11')], now);
    expect(p.over, isTrue);
    expect(p.remaining, -5000);
  });

  test('state and days left', () {
    expect(challengeProgress(ch(), [], now).state, ChallengeState.active);
    expect(challengeProgress(ch(), [], now).daysLeft, 5); // 12..16 inclusive
    final upcoming = challengeProgress(ch(s: '2026-11-15', e: '2026-11-20'), [], now);
    expect(upcoming.state, ChallengeState.upcoming);
    expect(upcoming.daysLeft, 3);
    final ended = challengeProgress(ch(s: '2026-11-01', e: '2026-11-07'), [], now);
    expect(ended.state, ChallengeState.ended);
    expect(ended.daysLeft, 0);
    // Last day is still active.
    expect(challengeProgress(ch(e: '2026-11-12'), [], now).state, ChallengeState.active);
  });

  test('renewedPeriod shifts by whole periods only when auto_renew and ended', () {
    expect(renewedPeriod(ch(), now), isNull); // still running
    expect(renewedPeriod(ch(s: '2026-11-01', e: '2026-11-07'), now), isNull); // not auto-renew
    // 7-day period 1..7 Nov, today 12 Nov -> 8..14 Nov.
    final p = renewedPeriod(ch(s: '2026-11-01', e: '2026-11-07', renew: true), now)!;
    expect(p.start, DateTime(2026, 11, 8));
    expect(p.end, DateTime(2026, 11, 14));
    // Many periods behind still lands on the one that covers today.
    final far = renewedPeriod(ch(s: '2026-09-01', e: '2026-09-07', renew: true), now)!;
    expect(!now.isBefore(far.start) && !now.isAfter(far.end.add(const Duration(days: 1))), isTrue);
    expect(far.end.difference(far.start).inDays, 6);
  });

  testWidgets('card shows spent, limit and status', (tester) async {
    final c = ch(limit: 100000);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChallengeCard(
          challenge: c,
          progress: challengeProgress(c, [tx('Makan', 25000, '2026-11-11')], now),
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    ));
    expect(find.text('Hemat'), findsOneWidget);
    expect(find.textContaining('Rp 25.000 / Rp 100.000'), findsOneWidget);
    expect(find.text('Sisa Rp 75.000'), findsOneWidget);
  });
}
