import 'package:cuanly/ui/lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({VoidCallback? onForgot}) => MaterialApp(
        home: PinPad(title: 'PIN', onSubmit: (_) async => false, onSuccess: () {}, onForgot: onForgot),
      );

  testWidgets('shows Lupa PIN only when onForgot is set and fires it', (tester) async {
    await tester.pumpWidget(host());
    expect(find.text('Lupa PIN?'), findsNothing);

    var tapped = 0;
    await tester.pumpWidget(host(onForgot: () => tapped++));
    await tester.tap(find.text('Lupa PIN?'));
    expect(tapped, 1);
  });

  testWidgets('wrong PIN shows error and clears dots', (tester) async {
    await tester.pumpWidget(host());
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('1'));
      await tester.pump();
    }
    await tester.pump();
    expect(find.text('PIN salah'), findsOneWidget);
  });
}
