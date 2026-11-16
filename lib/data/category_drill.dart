import 'repo.dart';

typedef MonthTotal = ({DateTime month, num total});

DateTime _firstOf(DateTime d) => DateTime(d.year, d.month);

String monthKey(DateTime m) => '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';

/// Totals of [category] (rows of [kind]) per month for the [months] months ending at [endMonth], oldest first.
List<MonthTotal> categoryMonthly(
  List<Map<String, dynamic>> rows,
  String category,
  String kind,
  DateTime endMonth, {
  int months = 6,
}) {
  final end = _firstOf(endMonth);
  final totals = <String, num>{};
  for (final r in rows) {
    if (r['kind'] != kind || r['category'] != category) continue;
    final key = (r['occurred_on'] as String).substring(0, 7);
    totals[key] = (totals[key] ?? 0) + (r['amount'] as num);
  }
  return [
    for (var i = months - 1; i >= 0; i--)
      () {
        final m = DateTime(end.year, end.month - i);
        return (month: m, total: totals[monthKey(m)] ?? 0);
      }()
  ];
}

/// Share (0..1) that [part] makes up of [whole]; 0 when [whole] is not positive.
double shareOf(num part, num whole) => whole <= 0 ? 0 : (part / whole).toDouble();

extension CategoryDrillRepo on Repo {
  /// Every transaction in the [months] months ending at [endMonth] (all categories, so shares can be computed).
  Future<List<Map<String, dynamic>>> drillRows(DateTime endMonth, {int months = 6}) async {
    final start = DateTime(endMonth.year, endMonth.month - (months - 1));
    return List<Map<String, dynamic>>.from(await db
        .from('transactions')
        .select()
        .gte('occurred_on', monthStart(start))
        .lt('occurred_on', monthStart(DateTime(endMonth.year, endMonth.month + 1)))
        .order('occurred_on', ascending: false)
        .order('created_at', ascending: false));
  }
}
