import 'package:cuanly/data/couple.dart';
import 'package:cuanly/ui/couple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row(String who, num exp, num inc, [String? top]) =>
    {'who': who, 'expense': exp, 'income': inc, 'top_category': top};

void main() {
  test('parseCoupleSummary needs both people', () {
    expect(parseCoupleSummary([]), isNull);
    expect(parseCoupleSummary([row('me', 1, 2)]), isNull);
    final s = parseCoupleSummary([row('partner', 300, 900, 'Makan'), row('me', 100, 500)])!;
    expect(s.me.expense, 100);
    expect(s.partner.topCategory, 'Makan');
    expect(s.me.topCategory, isNull);
    expect(s.combinedExpense, 400);
    expect(s.combinedIncome, 1400);
    expect(s.myShare, .25);
  });

  test('myShare is 0 when nobody spent', () {
    expect(parseCoupleSummary([row('me', 0, 0), row('partner', 0, 0)])!.myShare, 0);
  });

  test('null totals from the database are treated as 0', () {
    final s = parseCoupleSummary([
      {'who': 'me', 'expense': null, 'income': null, 'top_category': null},
      row('partner', 50, 0),
    ])!;
    expect(s.me.expense, 0);
    expect(s.combinedExpense, 50);
  });

  test('coupleState and isInviter', () {
    expect(coupleState(null), CoupleState.none);
    expect(coupleState({'status': 'pending'}), CoupleState.pending);
    expect(coupleState({'status': 'active'}), CoupleState.active);
    expect(isInviter({'inviter_id': 'u1'}, 'u1'), isTrue);
    expect(isInviter({'inviter_id': 'u1'}, 'u2'), isFalse);
    expect(isInviter({'inviter_id': 'u1'}, null), isFalse);
  });

  test('normalizeInviteCode ignores spaces and case', () {
    expect(normalizeInviteCode(' a1b2 c3d4\n'), 'A1B2C3D4');
  });

  test('coupleError keeps known server messages', () {
    expect(coupleError(Exception('PostgrestException(message: Kode undangan tidak valid atau sudah dipakai)')),
        'Kode undangan tidak valid atau sudah dipakai');
    expect(coupleError('boom'), 'Gagal: boom');
  });

  testWidgets('summary view shows combined spending, shares and top category', (tester) async {
    final s = parseCoupleSummary([row('me', 100000, 500000, 'Makan'), row('partner', 300000, 0, 'Belanja')])!;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: CoupleSummaryView(summary: s)))));
    expect(find.text('Rp 400.000'), findsOneWidget);
    expect(find.text('Kamu 25%  -  Pasangan 75%'), findsOneWidget);
    expect(find.text('Terbesar: Makan'), findsOneWidget);
    expect(find.text('Terbesar: Belanja'), findsOneWidget);
  });
}
