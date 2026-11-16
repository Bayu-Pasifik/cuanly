import 'package:cuanly/data/education.dart';
import 'package:cuanly/ui/education.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('articles are well formed', () {
    final ids = [for (final a in articles) a.id];
    expect(ids.toSet().length, ids.length);
    for (final a in articles) {
      expect(a.title, isNotEmpty);
      expect(a.summary, isNotEmpty);
      expect(a.body, isNotEmpty, reason: a.id);
      expect(a.minutes, greaterThanOrEqualTo(1));
    }
  });

  test('articleById', () {
    expect(articleById('dana-darurat')?.title, contains('Dana darurat'));
    expect(articleById('nope'), isNull);
  });

  test('tipOfTheDay is stable within a day and cycles', () {
    final d = DateTime(2026, 11, 16);
    expect(tipOfTheDay(DateTime(2026, 11, 16, 8)), tipOfTheDay(DateTime(2026, 11, 16, 23)));
    expect(tipOfTheDay(d), isNot(tipOfTheDay(d.add(const Duration(days: 1)))));
    expect(tipOfTheDay(d), tipOfTheDay(d.add(Duration(days: tips.length))));
  });

  testWidgets('list shows the tip and opens an article', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EducationPage()));
    expect(find.text('Tips hari ini'), findsOneWidget);
    await tester.tap(find.text(articles.first.title));
    await tester.pumpAndSettle();
    expect(find.text(articles.first.body.first), findsOneWidget);
  });
}
