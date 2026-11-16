import 'package:flutter/material.dart';

import '../data/repo.dart';
import '../data/tracker.dart';
import 'common.dart';
import 'theme.dart';

Color trackerColor(TrackerStatus s) => switch (s) {
      TrackerStatus.onTrack => C.mint,
      TrackerStatus.warning => C.orange,
      TrackerStatus.over => C.coral,
      TrackerStatus.noTarget => C.lilac,
    };

String trackerText(TrackerStatus s) => switch (s) {
      TrackerStatus.onTrack => 'Sesuai target',
      TrackerStatus.warning => 'Hampir habis',
      TrackerStatus.over => 'Melebihi target',
      TrackerStatus.noTarget => 'Belum ada target',
    };

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<MonthRecap>> _f = repo.trackerRecap(_month);

  void _reload() => setState(() {
        _f = repo.trackerRecap(_month);
      });

  void _go(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    _reload();
  }

  Future<void> _setTarget(num? current) async {
    final v = await askAmount(context, 'Target pengeluaran ${monthLabel(_month)}');
    if (v == null || !mounted) return;
    await guarded(context, () => repo.setBudget(_month, v), _reload);
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, 'Hapus target ${monthLabel(_month)}?')) return;
    if (!mounted) return;
    await guarded(context, () => repo.deleteBudget(_month), _reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cuan Tracker')),
        body: Async<List<MonthRecap>>(
          future: _f,
          builder: (_, recap) {
            final cur = recap.last;
            final status = trackerStatus(cur.expense, cur.target);
            final ratio = trackerRatio(cur.expense, cur.target);
            final color = trackerColor(status);
            final savings = cur.income - cur.expense;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(tooltip: 'Bulan sebelumnya', onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left)),
                Text(monthLabel(_month), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                IconButton(tooltip: 'Bulan berikutnya', onPressed: () => _go(1), icon: const Icon(Icons.chevron_right)),
              ]),
              PastelCard(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trackerText(status), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(cur.target == null ? rp(cur.expense) : '${rp(cur.expense)} / ${rp(cur.target!)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
                    if (ratio != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0, 1).toDouble(),
                          minHeight: 14,
                          color: C.ink,
                          backgroundColor: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${(ratio * 100).round()}% terpakai'),
                    ] else
                      const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Atur target pengeluaran bulan ini untuk melacak progresmu.')),
                  ]),
                ),
              ),
              Row(children: [
                Expanded(child: FilledButton(onPressed: () => _setTarget(cur.target), child: Text(cur.target == null ? 'Atur target' : 'Ubah target'))),
                if (cur.target != null) ...[
                  const SizedBox(width: 8),
                  IconButton(tooltip: 'Hapus target', onPressed: _delete, icon: const Icon(Icons.delete_outline)),
                ],
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _Stat('Pemasukan', rp(cur.income), C.mint),
                const SizedBox(width: 8),
                _Stat('Pengeluaran', rp(cur.expense), C.coral),
                const SizedBox(width: 8),
                _Stat('Tabungan', savings < 0 ? '-${rp(-savings)}' : rp(savings), C.sky),
              ]),
              const SizedBox(height: 20),
              const Text('Rekap 12 bulan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              for (final m in recap.reversed)
                Card(
                  child: ListTile(
                    onTap: () {
                      _month = m.month;
                      _reload();
                    },
                    leading: CircleAvatar(
                      backgroundColor: trackerColor(trackerStatus(m.expense, m.target)),
                      foregroundColor: C.ink,
                      child: Text('${m.month.month}'),
                    ),
                    title: Text(monthLabel(m.month)),
                    subtitle: Text('Masuk ${rp(m.income)}  -  Keluar ${rp(m.expense)}'),
                    trailing: Text(m.target == null ? '-' : rp(m.target!)),
                  ),
                ),
            ]);
          },
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: PastelCard(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
            ]),
          ),
        ),
      );
}
