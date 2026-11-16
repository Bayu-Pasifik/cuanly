import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/reminders.dart';
import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';

class _Summary {
  _Summary(this.wallets, this.txs, this.budget, this.trend, this.catBudgets, this.debts);
  final List<Map<String, dynamic>> debts;
  final Map<String, num> catBudgets;
  final List<({DateTime month, num income, num expense})> trend;
  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> txs;
  final num? budget;
}

Future<_Summary> _load() async {
  final now = DateTime.now();
  final r = await Future.wait([repo.wallets(), repo.transactions(month: now), repo.budget(now), repo.trend(now), repo.categoryBudgets(), repo.debts()]);
  return _Summary(r[0] as List<Map<String, dynamic>>, r[1] as List<Map<String, dynamic>>, r[2] as num?, r[3] as List<({DateTime month, num income, num expense})>, r[4] as Map<String, num>, r[5] as List<Map<String, dynamic>>);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_Summary> _f = _load();
  void _reload() => setState(() { _f = _load(); });

  Future<void> _addWallet([Map<String, dynamic>? w]) async {
    final name = TextEditingController(text: w?['name']);
    final bal = TextEditingController(text: w == null ? '' : (w['balance'] as num).round().toString());
    String type = w?['type'] ?? 'regular';
    var wantDelete = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(w == null ? 'Dompet baru' : 'Ubah dompet'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(
                controller: bal,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: w == null ? 'Saldo awal' : 'Saldo', prefixText: 'Rp ')),
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
            if (w != null)
              TextButton(
                  onPressed: () {
                    wantDelete = true;
                    Navigator.pop(ctx, false);
                  },
                  child: Text('Hapus', style: TextStyle(color: Colors.red.shade700))),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (wantDelete && w != null && mounted) {
      if (await _confirmDeleteWallet(w) && mounted) {
        await guarded(context, () => repo.deleteWallet(w['id']), _reload);
      }
      return;
    }
    if (ok == true && name.text.trim().isNotEmpty && mounted) {
      final n = name.text.trim(), b = parseAmount(bal.text) ?? 0;
      await guarded(context, () => w == null ? repo.addWallet(n, type, b) : repo.updateWallet(w['id'], n, type, b), _reload);
    }
  }

  /// Asks before deleting [w], spelling out what happens to its balance and history.
  Future<bool> _confirmDeleteWallet(Map<String, dynamic> w) async {
    String msg;
    try {
      final u = await repo.walletUsage(w['id']);
      final n = u.transactions + u.transfers;
      msg = n == 0
          ? 'Dompet belum dipakai transaksi.'
          : '${u.transactions} transaksi dan ${u.transfers} transfer tetap ada, tapi tidak terhubung ke dompet ini lagi.';
    } catch (_) {
      msg = 'Transaksi tetap ada.';
    }
    if (((w['balance'] as num?) ?? 0) != 0) {
      msg += ' Saldo ${rp(w['balance'])} ikut hilang dari total saldo.';
    }
    if (!mounted) return false;
    return confirmDelete(context, 'Hapus dompet "${w['name']}"?', message: msg);
  }

  Future<void> _transfer(List<Map<String, dynamic>> wallets) async {
    if (wallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Butuh minimal 2 dompet')));
      return;
    }
    final amt = TextEditingController();
    String from = wallets[0]['id'], to = wallets[1]['id'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) {
          Widget pick(String label, String value, ValueChanged<String> on) => DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w['id'] as String, child: Text('$label: ${w['name']} (${rp(w['balance'])})')),
                ],
                onChanged: (v) => set(() => on(v!)),
              );
          return AlertDialog(
            title: const Text('Transfer antar dompet'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              pick('Dari', from, (v) => from = v),
              pick('Ke', to, (v) => to = v),
              TextField(
                  controller: amt,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp ')),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Transfer')),
            ],
          );
        },
      ),
    );
    final v = parseAmount(amt.text);
    if (ok != true || !mounted) return;
    if (from == to || v == null || v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dompet harus beda dan jumlah > 0')));
      return;
    }
    final bal = wallets.firstWhere((w) => w['id'] == from)['balance'] as num;
    if (v > bal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo dompet asal tidak cukup')));
      return;
    }
    await guarded(context, () => repo.transfer(from, to, v), _reload);
  }

  /// Sets or removes the monthly limit of an expense category. [initial] preselects one.
  Future<void> _editCategoryBudget(Map<String, num> current, {String? initial}) async {
    final names = await repo.categoryNames('expense');
    if (!mounted) return;
    final all = {...names, ...current.keys}.toList();
    var cat = initial ?? all.first;
    final amt = TextEditingController(text: current[cat]?.round().toString() ?? '');
    var remove = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Anggaran kategori'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButton<String>(
              value: cat,
              isExpanded: true,
              items: [for (final n in all) DropdownMenuItem(value: n, child: Text(n))],
              onChanged: (v) => set(() {
                cat = v!;
                amt.text = current[cat]?.round().toString() ?? '';
              }),
            ),
            TextField(
                controller: amt,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Batas per bulan', prefixText: 'Rp ')),
          ]),
          actions: [
            if (current.containsKey(cat))
              TextButton(
                  onPressed: () {
                    remove = true;
                    Navigator.pop(ctx, true);
                  },
                  child: Text('Hapus', style: TextStyle(color: Colors.red.shade700))),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    if (remove) {
      await guarded(context, () => repo.clearCategoryBudget(cat), _reload);
      return;
    }
    final v = parseAmount(amt.text);
    if (v == null || v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi batas lebih dari 0')));
      return;
    }
    await guarded(context, () => repo.setCategoryBudget(cat, v), _reload);
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
              PastelCard(
                color: C.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total saldo', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(rp(total),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: C.ink)),
                  ]),
                ),
              ),
              Builder(builder: (_) {
                final due = dueDebts(s.debts, DateTime.now());
                if (due.isEmpty) return const SizedBox.shrink();
                return PastelCard(
                  color: C.orange,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Row(children: [
                          Icon(Icons.notifications_active_outlined, size: 18),
                          SizedBox(width: 6),
                          Text('Jatuh tempo', style: TextStyle(fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      for (final d in due)
                        ListTile(
                          dense: true,
                          title: Text('${d.owe ? 'Ke' : 'Dari'} ${d.debt['person']} • ${rp(d.remaining)}'),
                          subtitle: Text(dueLabel(d),
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: d.status == DueStatus.overdue ? (Theme.of(context).brightness == Brightness.dark ? Colors.red.shade200 : Colors.red.shade900) : C.fg(context))),
                        ),
                    ]),
                  ),
                );
              }),
              Row(children: [
                Expanded(
                  child: PastelCard(
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
                  child: PastelCard(
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
              PastelCard(
                color: C.lilac,
                child: ListTile(
                  title: Text(budget == null ? 'Anggaran bulan ini belum diatur' : 'Anggaran ${rp(budget)}'),
                  subtitle: budget == null
                      ? null
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                              value: (expense / budget).clamp(0, 1).toDouble(),
                              color: expense > budget ? Colors.red.shade700 : C.fg(context)),
                          const SizedBox(height: 4),
                          Text(expense > budget
                              ? 'Melebihi ${rp(expense - budget)}'
                              : 'Sisa ${rp(budget - expense)}'),
                        ]),
                  trailing: TextButton(onPressed: _setBudget, child: const Text('Atur')),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: Text('Tren 6 bulan terakhir')),
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
                          child: Text(DateFormat('MMM', 'id_ID').format(s.trend[v.toInt()].month),
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (g, _, r, i) => BarTooltipItem(
                          rp(r.toY), TextStyle(color: i == 0 ? C.mint : C.coral, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < s.trend.length; i++)
                      BarChartGroupData(x: i, barsSpace: 3, barRods: [
                        BarChartRodData(toY: s.trend[i].income.toDouble(), color: C.mint, width: 10),
                        BarChartRodData(toY: s.trend[i].expense.toDouble(), color: C.coral, width: 10),
                      ]),
                  ],
                )),
              ),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircleAvatar(radius: 5, backgroundColor: C.mint),
                SizedBox(width: 4),
                Text('Masuk', style: TextStyle(fontSize: 12)),
                SizedBox(width: 12),
                CircleAvatar(radius: 5, backgroundColor: C.coral),
                SizedBox(width: 4),
                Text('Keluar', style: TextStyle(fontSize: 12)),
              ]),
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
                const Expanded(child: Padding(padding: EdgeInsets.only(top: 8), child: Text('Anggaran per kategori'))),
                TextButton.icon(
                    onPressed: () => _editCategoryBudget(s.catBudgets),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Atur')),
              ]),
              if (s.catBudgets.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Belum ada batas per kategori.', style: TextStyle(fontSize: 12))),
              for (final e in (s.catBudgets.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
                Builder(builder: (_) {
                  final spent = byCat[e.key] ?? 0;
                  final over = spent > e.value;
                  return ListTile(
                    dense: true,
                    onTap: () => _editCategoryBudget(s.catBudgets, initial: e.key),
                    title: Text(e.key),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                          value: (spent / e.value).clamp(0, 1).toDouble(),
                          color: over ? Colors.red.shade700 : (spent / e.value >= 0.8 ? Colors.orange.shade700 : C.fg(context))),
                    ]),
                    trailing: Text('${rp(spent)} / ${rp(e.value)}',
                        style: TextStyle(color: over ? Colors.red.shade700 : null, fontWeight: FontWeight.w600)),
                  );
                }),
              Row(children: [
                const Expanded(child: Text('Dompet')),
                TextButton.icon(
                    onPressed: () => _transfer(s.wallets),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Transfer')),
                TextButton.icon(onPressed: _addWallet, icon: const Icon(Icons.add), label: const Text('Tambah')),
              ]),
              for (final w in s.wallets)
                Dismissible(
                  key: ValueKey(w['id']),
                  background: Container(color: Colors.red.shade100),
                  confirmDismiss: (_) => _confirmDeleteWallet(w),
                  onDismissed: (_) => guarded(context, () => repo.deleteWallet(w['id']), _reload),
                  child: PastelCard(
                    color: C.accents[s.wallets.indexOf(w) % C.accents.length],
                    child: ListTile(
                        onTap: () => _addWallet(w),
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
