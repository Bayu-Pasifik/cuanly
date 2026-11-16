import 'package:cuanly/data/legal.dart';
import 'package:cuanly/data/tracker.dart';
import 'package:cuanly/ui/legal.dart';
import 'package:cuanly/ui/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthSummaryText', () {
    test('with a target', () {
      final t = monthSummaryText((month: DateTime(2026, 11), income: 5000000, expense: 2000000, target: 4000000));
      expect(t, contains('Ringkasan keuangan November 2026'));
      expect(t, contains('Pemasukan: Rp 5.000.000'));
      expect(t, contains('Pengeluaran: Rp 2.000.000'));
      expect(t, contains('Tabungan: Rp 3.000.000'));
      expect(t, contains('Target pengeluaran: Rp 4.000.000 (50% terpakai)'));
      expect(t, endsWith('Dicatat dengan Cuanly'));
    });

    test('without a target and with a deficit', () {
      final t = monthSummaryText((month: DateTime(2026, 1), income: 1000000, expense: 1500000, target: null));
      expect(t, contains('Tabungan: -Rp 500.000'));
      expect(t, isNot(contains('Target pengeluaran')));
    });
  });

  test('legal texts have headings and bodies, and mention account deletion', () {
    for (final s in [...privacyPolicy, ...termsOfService]) {
      expect(s.heading, isNotEmpty);
      expect(s.body.length, greaterThan(40));
    }
    expect(privacyPolicy.map((s) => s.body).join(' '), contains('menghapus akun'));
  });

  testWidgets('LegalPage lists every section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LegalPage(title: 'Kebijakan privasi', sections: privacyPolicy)));
    expect(find.text('Kebijakan privasi'), findsOneWidget);
    expect(find.text(privacyPolicy.first.heading), findsOneWidget);
  });

  testWidgets('onboarding walks through the steps then finishes', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(home: OnboardingPage(onDone: () => done++)));
    expect(find.text(onboardingSteps.first.title), findsOneWidget);
    for (var i = 0; i < onboardingSteps.length - 1; i++) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
    }
    expect(find.text(onboardingSteps.last.title), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    expect(done, 1);
  });

  testWidgets('onboarding can be skipped', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(home: OnboardingPage(onDone: () => done++)));
    await tester.tap(find.text('Lewati'));
    expect(done, 1);
  });
}
