import 'package:cuanly/ui/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a spinner while loading, then the value', (tester) async {
    final done = Future<int>.delayed(const Duration(milliseconds: 10), () => 7);
    await tester.pumpWidget(MaterialApp(home: Async<int>(future: done, builder: (_, v) => Text('v=$v'))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('v=7'), findsOneWidget);
  });

  testWidgets('a future that completes with null is a result, not endless loading', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Async<String?>(future: Future<String?>.value(null), builder: (_, v) => Text(v == null ? 'kosong' : 'ada')),
    ));
    await tester.pump();
    expect(find.text('kosong'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the error text when the future fails', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Async<int>(future: (Future<int>.error('boom')..ignore()), builder: (_, v) => Text('v=$v')),
    ));
    await tester.pump();
    expect(find.textContaining('boom'), findsOneWidget);
  });
}
