import 'package:cuanly/data/account.dart';
import 'package:cuanly/ui/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isValidEmail', () {
    expect(isValidEmail('budi@gmail.com'), isTrue);
    expect(isValidEmail(' budi@gmail.com '), isTrue);
    expect(isValidEmail('budi@gmail'), isFalse);
    expect(isValidEmail('budi.gmail.com'), isFalse);
    expect(isValidEmail('bu di@gmail.com'), isFalse);
    expect(isValidEmail(''), isFalse);
  });

  test('passwordProblem', () {
    expect(passwordProblem('12345'), isNotNull);
    expect(passwordProblem('123456'), isNull);
  });

  group('suggestEmailFix', () {
    test('fixes common typos', () {
      expect(suggestEmailFix('budi@gmial.com'), 'budi@gmail.com');
      expect(suggestEmailFix('budi@gmal.com'), 'budi@gmail.com');
      expect(suggestEmailFix('Budi@GMAIL.COM '), isNull); // already fine once lowercased
      expect(suggestEmailFix('budi@yaho.com'), 'budi@yahoo.com');
      expect(suggestEmailFix('budi@outlok.com'), 'budi@outlook.com');
    });

    test('leaves correct and unrelated domains alone', () {
      expect(suggestEmailFix('budi@gmail.com'), isNull);
      expect(suggestEmailFix('budi@kantor.co.id'), isNull);
      expect(suggestEmailFix('budi@example.org'), isNull);
    });

    test('ignores incomplete input', () {
      expect(suggestEmailFix(''), isNull);
      expect(suggestEmailFix('budi'), isNull);
      expect(suggestEmailFix('budi@'), isNull);
      expect(suggestEmailFix('@gmail.com'), isNull);
    });
  });

  test('deleteConfirmed requires the word, ignoring case and spaces', () {
    expect(deleteConfirmed('HAPUS'), isTrue);
    expect(deleteConfirmed(' hapus '), isTrue);
    expect(deleteConfirmed('hapu'), isFalse);
    expect(deleteConfirmed(''), isFalse);
  });

  test('newPasswordProblem', () {
    expect(newPasswordProblem('123', '123'), isNotNull); // too short
    expect(newPasswordProblem('123456', '654321'), 'Konfirmasi password tidak sama');
    expect(newPasswordProblem('123456', '123456'), isNull);
  });

  testWidgets('reset password screen rejects mismatching passwords', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(home: ResetPasswordPage(onDone: () => done = true)));
    await tester.enterText(find.byType(TextField).first, 'abcdef');
    await tester.enterText(find.byType(TextField).last, 'abcxyz');
    await tester.tap(find.text('Simpan password'));
    await tester.pump();
    expect(find.text('Konfirmasi password tidak sama'), findsOneWidget);
    expect(done, isFalse);
  });
}
