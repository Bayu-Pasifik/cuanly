import 'package:flutter/material.dart';

import '../data/category_drill.dart';
import '../data/repo.dart';
import '../data/tracker.dart';
import 'common.dart';
import 'theme.dart';

/// Month-by-month breakdown of one category with the transactions behind it.
class CategoryDrillPage extends StatefulWidget {
  const CategoryDrillPage({super.key, required this.category, this.kind = 'expense', this.month});
  final String category, kind;
  final DateTime? month;

  @override
  State<CategoryDrillPage> createState() => _CategoryDrillPageState();
}

class _CategoryDrillPageState extends State<CategoryDrillPage> {
  late DateTime _month = widget.month ?? DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<Map<String, dynamic>>> _f = repo.drillRows(_month);

  void _go(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _f = repo.drillRows(_month);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: Async<List<Map<String, dynamic>>>(
          future: _f,
          builder: (_, rows) => ListView(padding: const EdgeInsets.all(16), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(tooltip: 'Bulan sebelumnya', onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left)),
              Text(monthLabel(_month), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(tooltip: 'Bulan berikutnya', onPressed: () => _go(1), icon: const Icon(Icons.chevron_right)),
            ]),
            CategoryDrillBody(rows: rows, category: widget.category, kind: widget.kind, month: _month),
          ]),
        ),
      );
}

class CategoryDrillBody extends StatelessWidget {
  const CategoryDrillBody({
    super.key,
    required this.rows,
    required this.category,
    required this.kind,
    required this.month,
  });
  final List<Map<String, dynamic>> rows;
  final String category, kind;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final monthly = categoryMonthly(rows, category, kind, month);
    final key = monthKey(month);
    final inMonth = [for (final r in rows) if ((r['occurred_on'] as String).startsWith(key) && r['kind'] == kind) r];
    final mine = [for (final r in inMonth) if (r['category'] == category) r];
    final total = monthly.last.total;
    final all = inMonth.fold<num>(0, (a, r) => a + (r['amount'] as num));
    final prev = monthly.length >= 2 ? monthly[monthly.length - 2].total : 0;
    final peak = monthly.map((m) => m.total).fold<num>(0, (a, b) => a > b ? a : b);
    final color = kind == 'expense' ? C.coral : C.mint;

    String change() {
      if (prev <= 0) return total > 0 ? 'Baru bulan ini' : '';
      final p = ((total - prev) / prev * 100).round();
      return p == 0 ? 'Sama seperti bulan lalu' : '${p > 0 ? '+' : ''}$p% dari bulan lalu';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PastelCard(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rp(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
            Text('${(shareOf(total, all) * 100).round()}% dari ${kind == 'expense' ? 'pengeluaran' : 'pemasukan'} bulan ini'),
            if (change().isNotEmpty) Text(change()),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      const Text('6 bulan terakhir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 8),
      SizedBox(
        height: 120,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final m in monthly)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: peak <= 0 ? 0.02 : (m.total / peak).clamp(0.02, 1).toDouble(),
                      child: Container(
                        key: ValueKey('bar-${m.month.month}'),
                        decoration: BoxDecoration(
                          color: monthKey(m.month) == key ? color : color.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(monthNames[m.month.month - 1].substring(0, 3), style: const TextStyle(fontSize: 11)),
                ]),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Text('Transaksi (${mine.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      if (mine.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada transaksi di bulan ini.'))
      else
        for (final r in mine)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text((r['note'] as String?)?.isNotEmpty == true ? r['note'] : category),
            subtitle: Text(r['occurred_on']),
            trailing: Text(rp(r['amount'] as num), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
    ]);
  }
}
