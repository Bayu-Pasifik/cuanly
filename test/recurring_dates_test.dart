import 'package:flutter_test/flutter_test.dart';
import 'package:cuanly/data/recurring_repo.dart';

void main() {
  test('clampedDay clamps to month length', () {
    expect(clampedDay(2026, 2, 31), DateTime(2026, 2, 28));
    expect(clampedDay(2028, 2, 31), DateTime(2028, 2, 29));
    expect(clampedDay(2026, 4, 31), DateTime(2026, 4, 30));
    expect(clampedDay(2026, 13, 5), DateTime(2027, 1, 5));
  });

  test('firstDue picks this month when not passed, else next month', () {
    final today = DateTime(2026, 11, 16);
    expect(firstDue(16, today), DateTime(2026, 11, 16));
    expect(firstDue(20, today), DateTime(2026, 11, 20));
    expect(firstDue(10, today), DateTime(2026, 12, 10));
    expect(firstDue(31, DateTime(2026, 1, 31)), DateTime(2026, 1, 31));
    expect(firstDue(31, DateTime(2026, 2, 5)), DateTime(2026, 2, 28));
    expect(firstDue(5, DateTime(2026, 12, 20)), DateTime(2027, 1, 5));
  });
}
