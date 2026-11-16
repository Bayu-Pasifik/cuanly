import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/repo.dart';
import 'category_drill.dart';
import 'common.dart';
import 'theme.dart';

/// Income, expense and category totals of one period (a month or a year).
class Period {
  Period(List<Map<String, dynamic>> txs, this.monthly) {
    for (final t in txs) {
      final a = t['amount'] as num;
      final m = int.parse((t['occurred_on'] as String).substring(5, 7));
      if (t['kind'] == 'income') {
        income += a;
        monthlyIncome[m] = (monthlyIncome[m] ?? 0) + a;
      } else {
        expense += a;
        byCategory[t['category']] = (byCategory[t['category']] ?? 0) + a;
        monthlyExpense[m] = (monthlyExpense[m] ?? 0) + a;
        if (a > (biggest?['amount'] as num? ?? 0)) biggest = t;
      }
    }
  }

  final bool monthly;
  num income = 0, expense = 0;
  final byCategory = <String, num>{};
  final monthlyIncome = <int, num>{}, monthlyExpense = <int, num>{};
  Map<String, dynamic>? biggest;

  num get net => income - expense;

  /// Share of income that was not spent, or null when there was no income.
  double? get savingRate => income > 0 ? (net / income).toDouble() : null;
}

/// Percent change from [prev] to [cur]; null when there is no base to compare to.
double? pctChange(num cur, num prev) => prev > 0 ? ((cur - prev) / prev * 100).toDouble() : null;

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _yearly = false;
  DateTime _at = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late Future<List<Period>> _f = _load();

  DateTime get _start => _yearly ? DateTime(_at.year, 1, 1) : _at;
  DateTime get _end => _yearly ? DateTime(_at.year, 12, 31) : DateTime(_at.year, _at.month + 1, 0);
  DateTime get _prevStart => _yearly ? DateTime(_at.year - 1, 1, 1) : DateTime(_at.year, _at.month - 1, 1);
  DateTime get _prevEnd => _yearly ? DateTime(_at.year - 1, 12, 31) : DateTime(_at.year, _at.month, 0);

  Future<List<Period>> _load() async {
    final r = await Future.wait([
      repo.transactions(from: _start, to: _end),
      repo.transactions(from: _prevStart, to: _prevEnd),
    ]);
    return [Period(r[0], !_yearly), Period(r[1], !_yearly)];
  }

  void _reload() => setState(() {
        _f = _load();
      });

  void _shift(int d) {
    _at = _yearly ? DateTime(_at.year + d, _at.month, 1) : DateTime(_at.year, _at.month + d, 1);
    _reload();
  }

  Widget _delta(num cur, num prev, {required bool upIsBad}) {
    final p = pctChange(cur, prev);
    if (p == null) return const Text('Tidak ada pembanding', style: TextStyle(fontSize: 12));
    final up = p >= 0;
    final bad = upIsBad ? up : !up;
    return Text(
      '${up ? '▲' : '▼'} ${p.abs().toStringAsFixed(0)}% dari ${_yearly ? 'tahun' : 'bulan'} lalu',
      style: TextStyle(fontSize: 12, color: p == 0 ? null : (bad ? Colors.red.shade700 : Colors.green.shade700)),
    );
  }

  Widget _stat(String label, num value, Color color, Widget? foot) => Expanded(
        child: Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(rp(value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              if (foot != null) ...[const SizedBox(height: 4), foot],
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Laporan')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Bulanan')),
                ButtonSegment(value: true, label: Text('Tahunan')),
              ],
              selected: {_yearly},
              onSelectionChanged: (s) {
                _yearly = s.first;
                _reload();
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
            Text(_yearly ? '${_at.year}' : DateFormat('MMMM yyyy', 'id_ID').format(_at),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
          ]),
          Expanded(
            child: Async<List<Period>>(
              future: _f,
              builder: (_, ps) {
                final cur = ps[0], prev = ps[1];
                if (cur.income == 0 && cur.expense == 0) {
                  return const Center(child: Text('Belum ada transaksi di periode ini.'));
                }
                final cats = cur.byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                final rate = cur.savingRate;
                return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 24), children: [
                  Row(children: [
                    _stat('Masuk', cur.income, C.mint, _delta(cur.income, prev.income, upIsBad: false)),
                    _stat('Keluar', cur.expense, C.coral, _delta(cur.expense, prev.expense, upIsBad: true)),
                  ]),
                  Row(children: [_stat('Selisih', cur.net, cur.net >= 0 ? C.sky : C.orange, null)]),
                  if (rate != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                          rate >= 0
                              ? 'Kamu menyisihkan ${(rate * 100).toStringAsFixed(0)}% dari pemasukan.'
                              : 'Pengeluaran melebihi pemasukan ${(-rate * 100).toStringAsFixed(0)}%.',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  if (_yearly) ...[
                    const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('Per bulan')),
                    SizedBox(
                      height: 180,
                      child: BarChart(BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(DateFormat('MMM', 'id_ID').format(DateTime(2000, v.toInt() + 1)).substring(0, 1),
                                    style: const TextStyle(fontSize: 11)),
                              ),
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var m = 1; m <= 12; m++)
                            BarChartGroupData(x: m - 1, barsSpace: 2, barRods: [
                              BarChartRodData(toY: (cur.monthlyIncome[m] ?? 0).toDouble(), color: C.mint, width: 6),
                              BarChartRodData(toY: (cur.monthlyExpense[m] ?? 0).toDouble(), color: C.coral, width: 6),
                            ]),
                        ],
                      )),
                    ),
                  ],
                  if (cats.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.only(top: 12, bottom: 4), child: Text('Pengeluaran per kategori')),
                    SizedBox(
                      height: 180,
                      child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: [
                        for (var i = 0; i < cats.length; i++)
                          PieChartSectionData(
                              value: cats[i].value.toDouble(),
                              color: C.chart[i % C.chart.length],
                              title: '',
                              radius: 36),
                      ])),
                    ),
                    for (var i = 0; i < cats.length; i++)
                      ListTile(
                        dense: true,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => CategoryDrillPage(category: cats[i].key))),
                        leading: CircleAvatar(radius: 6, backgroundColor: C.chart[i % C.chart.length]),
                        title: Text('${cats[i].key} • ${(cats[i].value / cur.expense * 100).toStringAsFixed(0)}%'),
                        subtitle: _delta(cats[i].value, prev.byCategory[cats[i].key] ?? 0, upIsBad: true),
                        trailing: Text(rp(cats[i].value), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ],
                  if (cur.biggest != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_fire_department_outlined),
                        title: const Text('Pengeluaran terbesar'),
                        subtitle: Text('${cur.biggest!['category']} • ${cur.biggest!['occurred_on']}'
                            '${(cur.biggest!['note'] as String?)?.isNotEmpty ?? false ? ' • ${cur.biggest!['note']}' : ''}'),
                        trailing: Text(rp(cur.biggest!['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]),
      );
}
