import 'package:cuanly/data/tracker.dart';
import 'package:cuanly/ui/theme.dart';
import 'package:cuanly/ui/tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trackerStatus thresholds', () {
    expect(trackerStatus(100, null), TrackerStatus.noTarget);
    expect(trackerStatus(100, 0), TrackerStatus.noTarget);
    expect(trackerStatus(79, 100), TrackerStatus.onTrack);
    expect(trackerStatus(80, 100), TrackerStatus.warning);
    expect(trackerStatus(100, 100), TrackerStatus.warning); // at the target is not yet over
    expect(trackerStatus(101, 100), TrackerStatus.over);
    expect(trackerStatus(0, 100), TrackerStatus.onTrack);
  });

  test('trackerRatio', () {
    expect(trackerRatio(50, 200), .25);
    expect(trackerRatio(300, 200), 1.5);
    expect(trackerRatio(50, null), isNull);
    expect(trackerRatio(50, 0), isNull);
  });

  test('monthLabel is Indonesian', () {
    expect(monthLabel(DateTime(2026, 11)), 'November 2026');
    expect(monthLabel(DateTime(2027, 1)), 'Januari 2027');
    expect(monthNames.length, 12);
  });

  test('every status has a color and text', () {
    for (final s in TrackerStatus.values) {
      expect(trackerText(s), isNotEmpty);
    }
    expect(trackerColor(TrackerStatus.over), C.coral);
    expect(trackerColor(TrackerStatus.onTrack), C.mint);
  });
}
