import 'repo.dart';

enum TrackerStatus { noTarget, onTrack, warning, over }

/// How [expense] compares with the monthly [target]: under 80% is on track, up to the target is a warning.
TrackerStatus trackerStatus(num expense, num? target) {
  if (target == null || target <= 0) return TrackerStatus.noTarget;
  if (expense > target) return TrackerStatus.over;
  return expense / target >= .8 ? TrackerStatus.warning : TrackerStatus.onTrack;
}

/// Share of the target already spent (can exceed 1). Null without a target.
double? trackerRatio(num expense, num? target) => (target == null || target <= 0) ? null : (expense / target).toDouble();

const monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String monthLabel(DateTime m) => '${monthNames[m.month - 1]} ${m.year}';

typedef MonthRecap = ({DateTime month, num income, num expense, num? target});

extension TrackerRepo on Repo {
  Future<void> deleteBudget(DateTime month) => db.from('monthly_targets').delete().eq('month', monthStart(month));

  /// The 12 months ending at [month] (oldest first) with each month's target.
  Future<List<MonthRecap>> trackerRecap(DateTime month) async {
    final trend12 = await trend(month, months: 12);
    final targets = {
      for (final r in await db.from('monthly_targets').select('month,budget')) (r['month'] as String).substring(0, 7): r['budget'] as num
    };
    return [
      for (final t in trend12)
        (month: t.month, income: t.income, expense: t.expense, target: targets[dateStr(t.month).substring(0, 7)])
    ];
  }
}
