import 'package:flutter/material.dart';

import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';

class DreamsPage extends StatefulWidget {
  const DreamsPage({super.key});

  @override
  State<DreamsPage> createState() => _DreamsPageState();
}

class _DreamsPageState extends State<DreamsPage> {
  late Future<List<Map<String, dynamic>>> _f = repo.dreams();
  void _reload() => setState(() => _f = repo.dreams());

  Future<void> _add() async {
    final title = TextEditingController();
    final target = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impian baru'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Apa impianmu?')),
          TextField(
              controller: target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target', prefixText: 'Rp ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    final t = parseAmount(target.text);
    if (ok == true && title.text.trim().isNotEmpty && t != null && t > 0 && mounted) {
      await guarded(context, () => repo.addDream(title.text.trim(), t), _reload);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Async<List<Map<String, dynamic>>>(
          future: _f,
          builder: (_, list) => list.isEmpty
              ? const Center(child: Text('Belum ada impian. Tambah satu!'))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final d in list)
                    Card(
                      color: C.accents[list.indexOf(d) % C.accents.length],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(d['title'], style: Theme.of(context).textTheme.titleMedium)),
                            IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => guarded(context, () => repo.deleteDream(d['id']), _reload)),
                          ]),
                          LinearProgressIndicator(value: ((d['saved'] as num) / (d['target'] as num)).clamp(0, 1).toDouble()),
                          const SizedBox(height: 6),
                          Text('${rp(d['saved'])} / ${rp(d['target'])}'),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                final v = await askAmount(context, 'Tambah tabungan');
                                if (v != null && context.mounted) {
                                  await guarded(context, () => repo.contributeDream(d, v), _reload);
                                }
                              },
                              child: const Text('Menabung'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                ]),
        ),
        floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      );
}
