import 'repo.dart';

enum InsightLevel { good, info, warning }

class Insight {
  const Insight(this.level, this.title, this.body);
  final InsightLevel level;
  final String title, body;
}

String _rp(num v) => 'Rp ${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

num _sum(Iterable<Map<String, dynamic>> rows, String kind) =>
    rows.where((r) => r['kind'] == kind).fold<num>(0, (a, r) => a + (r['amount'] as num));

Map<String, num> _byCategory(Iterable<Map<String, dynamic>> rows) {
  final m = <String, num>{};
  for (final r in rows) {
    if (r['kind'] != 'expense') continue;
    m[r['category']] = (m[r['category']] ?? 0) + (r['amount'] as num);
  }
  return m;
}

/// Rule-based observations about the month containing [now].
/// [thisMonth] and [lastMonth] are transaction rows (`kind`, `category`, `amount`); [target] is the
/// monthly spending target. Runs entirely on the device; nothing is sent anywhere.
List<Insight> buildInsights({
  required List<Map<String, dynamic>> thisMonth,
  required List<Map<String, dynamic>> lastMonth,
  required num? target,
  required DateTime now,
}) {
  final out = <Insight>[];
  final spent = _sum(thisMonth, 'expense');
  final income = _sum(thisMonth, 'income');
  final prevSpent = _sum(lastMonth, 'expense');
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

  if (thisMonth.isEmpty) {
    out.add(const Insight(InsightLevel.info, 'Belum ada transaksi bulan ini',
        'Catat pengeluaran dan pemasukanmu supaya insight muncul di sini.'));
    return out;
  }

  // Pace: where this month is heading if spending continues at the same rate.
  if (spent > 0 && now.day >= 5) {
    final projected = spent / now.day * daysInMonth;
    if (target != null && target > 0) {
      if (spent > target) {
        out.add(Insight(InsightLevel.warning, 'Target bulan ini terlewati',
            'Pengeluaran ${_rp(spent)} sudah melebihi target ${_rp(target)} sebesar ${_rp(spent - target)}.'));
      } else if (projected > target) {
        out.add(Insight(InsightLevel.warning, 'Pengeluaran melaju di atas target',
            'Dengan laju sekarang, bulan ini bisa mencapai sekitar ${_rp(projected)}, lebih dari target ${_rp(target)}.'));
      } else {
        out.add(Insight(InsightLevel.good, 'Pengeluaran sesuai target',
            'Perkiraan akhir bulan ${_rp(projected)}, masih di bawah target ${_rp(target)}.'));
      }
    } else if (prevSpent > 0) {
      final diff = (projected - prevSpent) / prevSpent * 100;
      if (diff >= 15) {
        out.add(Insight(InsightLevel.warning, 'Pengeluaran lebih tinggi dari bulan lalu',
            'Perkiraan akhir bulan ${_rp(projected)}, sekitar ${diff.round()}% di atas bulan lalu (${_rp(prevSpent)}).'));
      } else if (diff <= -15) {
        out.add(Insight(InsightLevel.good, 'Pengeluaran lebih hemat dari bulan lalu',
            'Perkiraan akhir bulan ${_rp(projected)}, sekitar ${(-diff).round()}% di bawah bulan lalu (${_rp(prevSpent)}).'));
      }
    }
  }

  // Biggest category and its share.
  final cats = _byCategory(thisMonth);
  if (cats.isNotEmpty && spent > 0) {
    final top = cats.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final share = top.value / spent * 100;
    if (share >= 40 && cats.length > 1) {
      out.add(Insight(InsightLevel.info, '${top.key} menyedot ${share.round()}% pengeluaran',
          '${_rp(top.value)} dari ${_rp(spent)} bulan ini dipakai untuk ${top.key}.'));
    }
  }

  // Category that grew the most since last month.
  final prevCats = _byCategory(lastMonth);
  ({String name, num delta, num pct})? jump;
  for (final e in cats.entries) {
    final before = prevCats[e.key] ?? 0;
    final delta = e.value - before;
    if (before > 0 && delta >= 50000 && delta / before >= .3 && (jump == null || delta > jump.delta)) {
      jump = (name: e.key, delta: delta, pct: delta / before * 100);
    }
  }
  if (jump != null) {
    out.add(Insight(InsightLevel.warning, '${jump.name} naik ${jump.pct.round()}%',
        'Naik ${_rp(jump.delta)} dibanding bulan lalu (${_rp(prevCats[jump.name]!)} menjadi ${_rp(cats[jump.name]!)}).'));
  }

  // Savings rate.
  if (income > 0) {
    final rate = (income - spent) / income * 100;
    if (rate < 0) {
      out.add(Insight(InsightLevel.warning, 'Pengeluaran lebih besar dari pemasukan',
          'Bulan ini defisit ${_rp(spent - income)}. Tinjau pengeluaran terbesarmu.'));
    } else if (rate < 10) {
      out.add(Insight(InsightLevel.warning, 'Tabunganmu tipis',
          'Hanya ${rate.round()}% pemasukan yang tersisa. Coba sisihkan di awal bulan.'));
    } else if (rate >= 20) {
      out.add(Insight(InsightLevel.good, 'Tabunganmu sehat',
          '${rate.round()}% pemasukan bulan ini tersisa (${_rp(income - spent)}).'));
    }
  }

  if (out.isEmpty) {
    out.add(const Insight(InsightLevel.info, 'Keuanganmu stabil', 'Belum ada hal yang perlu diperhatikan bulan ini.'));
  }
  return out;
}

extension InsightRepo on Repo {
  Future<List<Insight>> insights({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final first = DateTime(clock.year, clock.month, 1);
    final prev = DateTime(clock.year, clock.month - 1, 1);
    final rows = List<Map<String, dynamic>>.from(await db
        .from('transactions')
        .select('kind,category,amount,occurred_on')
        .gte('occurred_on', monthStart(prev))
        .lt('occurred_on', monthStart(DateTime(clock.year, clock.month + 1, 1))));
    final cut = monthStart(first);
    final thisMonth = [for (final r in rows) if ((r['occurred_on'] as String).compareTo(cut) >= 0) r];
    final lastMonth = [for (final r in rows) if ((r['occurred_on'] as String).compareTo(cut) < 0) r];
    return buildInsights(thisMonth: thisMonth, lastMonth: lastMonth, target: await budget(first), now: clock);
  }
}
