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

String _rp(num v) => 'Rp ${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

/// Shareable text summary of one month.
String monthSummaryText(({DateTime month, num income, num expense, num? target}) m) {
  final savings = m.income - m.expense;
  final b = StringBuffer()
    ..writeln('Ringkasan keuangan ${monthLabel(m.month)}')
    ..writeln('Pemasukan: ${_rp(m.income)}')
    ..writeln('Pengeluaran: ${_rp(m.expense)}')
    ..writeln('Tabungan: ${savings < 0 ? '-' : ''}${_rp(savings.abs())}');
  final t = m.target;
  if (t != null && t > 0) {
    b.writeln('Target pengeluaran: ${_rp(t)} (${(m.expense / t * 100).round()}% terpakai)');
  }
  b.write('Dicatat dengan Cuanly');
  return b.toString();
}

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
