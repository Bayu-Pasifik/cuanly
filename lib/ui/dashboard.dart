import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';

class _Summary {
  _Summary(this.wallets, this.txs, this.budget);
  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> txs;
  final num? budget;
}

Future<_Summary> _load() async {
  final now = DateTime.now();
  final r = await Future.wait([repo.wallets(), repo.transactions(month: now), repo.budget(now)]);
  return _Summary(r[0] as List<Map<String, dynamic>>, r[1] as List<Map<String, dynamic>>, r[2] as num?);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_Summary> _f = _load();
  void _reload() => setState(() => _f = _load());

  Future<void> _addWallet() async {
    final name = TextEditingController();
    final bal = TextEditingController();
    String type = 'regular';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Dompet baru'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(
                controller: bal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Saldo awal', prefixText: 'Rp ')),
            DropdownButton<String>(
              value: type,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'regular', child: Text('Reguler')),
                DropdownMenuItem(value: 'saving', child: Text('Tabungan')),
                DropdownMenuItem(value: 'credit_card', child: Text('Kartu kredit')),
                DropdownMenuItem(value: 'investment', child: Text('Investasi')),
              ],
              onChanged: (v) => set(() => type = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && mounted) {
      await guarded(context, () => repo.addWallet(name.text.trim(), type, parseAmount(bal.text) ?? 0), _reload);
    }
  }

  Future<void> _setBudget() async {
    final v = await askAmount(context, 'Anggaran bulan ini');
    if (v != null && mounted) await guarded(context, () => repo.setBudget(DateTime.now(), v), _reload);
  }

  @override
  Widget build(BuildContext context) => Async<_Summary>(
        future: _f,
        builder: (_, s) {
          num income = 0, expense = 0;
          final byCat = <String, num>{};
          for (final t in s.txs) {
            final a = t['amount'] as num;
            if (t['kind'] == 'income') {
              income += a;
            } else {
              expense += a;
              byCat[t['category']] = (byCat[t['category']] ?? 0) + a;
            }
          }
          final total = s.wallets.fold<num>(0, (p, w) => p + (w['balance'] as num));
          final budget = s.budget;
          final colors = C.chart;
          final cats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                color: C.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total saldo', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(rp(total),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
              Row(children: [
                Expanded(
                  child: Card(
                    color: C.mint,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.south_west_rounded, size: 18), SizedBox(width: 4), Text('Masuk')]),
                        const SizedBox(height: 4),
                        Text(rp(income), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: C.coral,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.north_east_rounded, size: 18), SizedBox(width: 4), Text('Keluar')]),
                        const SizedBox(height: 4),
                        Text(rp(expense), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
                    ),
                  ),
                ),
              ]),
              Card(
                color: C.lilac,
                child: ListTile(
                  title: Text(budget == null ? 'Anggaran bulan ini belum diatur' : 'Anggaran ${rp(budget)}'),
                  subtitle: budget == null
                      ? null
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                              value: (expense / budget).clamp(0, 1).toDouble(),
                              color: expense > budget ? Colors.red.shade700 : C.ink),
                          const SizedBox(height: 4),
                          Text(expense > budget
                              ? 'Melebihi ${rp(expense - budget)}'
                              : 'Sisa ${rp(budget - expense)}'),
                        ]),
                  trailing: TextButton(onPressed: _setBudget, child: const Text('Atur')),
                ),
              ),
              if (cats.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('Pengeluaran per kategori')),
                SizedBox(
                  height: 180,
                  child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: [
                    for (var i = 0; i < cats.length; i++)
                      PieChartSectionData(
                          value: cats[i].value.toDouble(), color: colors[i % colors.length], title: '', radius: 36),
                  ])),
                ),
                for (var i = 0; i < cats.length; i++)
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 6, backgroundColor: colors[i % colors.length]),
                    title: Text(cats[i].key),
                    trailing: Text(rp(cats[i].value)),
                  ),
              ],
              Row(children: [
                const Expanded(child: Text('Dompet')),
                TextButton.icon(onPressed: _addWallet, icon: const Icon(Icons.add), label: const Text('Tambah')),
              ]),
              for (final w in s.wallets)
                Dismissible(
                  key: ValueKey(w['id']),
                  background: Container(color: Colors.red.shade100),
                  confirmDismiss: (_) async => await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Hapus dompet "${w['name']}"?'),
                          content: const Text('Transaksinya tetap ada.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                          ],
                        ),
                      ),
                  onDismissed: (_) => guarded(context, () => repo.deleteWallet(w['id']), _reload),
                  child: Card(
                    color: C.accents[s.wallets.indexOf(w) % C.accents.length],
                    child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet_rounded),
                        title: Text(w['name'], style: const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: Text(rp(w['balance']), style: const TextStyle(fontWeight: FontWeight.w800))),
                  ),
                ),
            ]),
          );
        },
      );
}
