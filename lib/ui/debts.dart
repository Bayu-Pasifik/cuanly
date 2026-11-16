import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  late Future<List<Map<String, dynamic>>> _f = repo.debts();
  void _reload() => setState(() => _f = repo.debts());

  Future<void> _add() async {
    final person = TextEditingController();
    final total = TextEditingController();
    String dir = 'owe';
    DateTime? due;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Catat utang'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'owe', label: Text('Saya berutang')),
                ButtonSegment(value: 'lent', label: Text('Saya meminjamkan')),
              ],
              selected: {dir},
              onSelectionChanged: (s) => set(() => dir = s.first),
            ),
            TextField(controller: person, decoration: const InputDecoration(labelText: 'Nama orang')),
            TextField(
                controller: total,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp ')),
            TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                    context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (d != null) set(() => due = d);
              },
              child: Text(due == null ? 'Jatuh tempo (opsional)' : DateFormat('d MMM y', 'id_ID').format(due!)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    final t = parseAmount(total.text);
    if (ok == true && person.text.trim().isNotEmpty && t != null && t > 0 && mounted) {
      await guarded(context, () => repo.addDebt(person.text.trim(), dir, t, due), _reload);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Async<List<Map<String, dynamic>>>(
          future: _f,
          builder: (_, list) {
            num owe = 0, lent = 0;
            for (final d in list) {
              final rest = (d['total'] as num) - (d['paid'] as num);
              d['direction'] == 'owe' ? owe += rest : lent += rest;
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: Card(color: C.coral, child: ListTile(title: const Text('Utangmu'), subtitle: Text(rp(owe), style: const TextStyle(fontWeight: FontWeight.w800))))),
                Expanded(child: Card(color: C.mint, child: ListTile(title: const Text('Piutangmu'), subtitle: Text(rp(lent), style: const TextStyle(fontWeight: FontWeight.w800))))),
              ]),
              if (list.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Tidak ada catatan utang.'))),
              for (final d in list)
                Card(
                  color: d['direction'] == 'owe' ? C.pink : C.sky,
                  child: ListTile(
                    title: Text('${d['direction'] == 'owe' ? 'Ke' : 'Dari'} ${d['person']}'),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: ((d['paid'] as num) / (d['total'] as num)).clamp(0, 1).toDouble()),
                      const SizedBox(height: 4),
                      Text('${rp(d['paid'])} / ${rp(d['total'])}'
                          '${d['due_on'] != null ? ' • tempo ${DateFormat('d MMM y', 'id_ID').format(DateTime.parse(d['due_on']))}' : ''}'),
                    ]),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'pay') {
                          final a = await askAmount(context, 'Jumlah dibayar');
                          if (a != null && context.mounted) await guarded(context, () => repo.payDebt(d, a), _reload);
                        } else {
                          await guarded(context, () => repo.deleteDebt(d['id']), _reload);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'pay', child: Text('Catat pembayaran')),
                        PopupMenuItem(value: 'del', child: Text('Hapus')),
                      ],
                    ),
                  ),
                ),
            ]);
          },
        ),
        floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      );
}
