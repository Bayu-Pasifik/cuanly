import 'package:cuanly/ui/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
  }

  testWidgets('suggests a fix for a mistyped email domain and applies it', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'budi@gmial.com');
    await tester.pump();
    expect(find.text('Maksudmu budi@gmail.com?'), findsOneWidget);
    await tester.tap(find.text('Maksudmu budi@gmail.com?'));
    await tester.pump();
    expect(find.text('budi@gmail.com'), findsOneWidget);
    expect(find.textContaining('Maksudmu'), findsNothing);
  });

  testWidgets('rejects a malformed email before calling the server', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'bukan-email');
    await tester.tap(find.text('Masuk').last);
    await tester.pump();
    expect(find.text('Format email belum benar'), findsOneWidget);
  });

  testWidgets('sign-up enforces the minimum password length', (tester) async {
    await open(tester);
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'budi@gmail.com');
    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.text('Daftar').first);
    await tester.pump();
    expect(find.text('Password minimal 6 karakter'), findsOneWidget);
  });

  testWidgets('forgot-password link only shows on the login form', (tester) async {
    await open(tester);
    expect(find.text('Lupa password?'), findsOneWidget);
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pump();
    expect(find.text('Lupa password?'), findsNothing);
  });
}
