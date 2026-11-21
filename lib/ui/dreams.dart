import 'package:flutter/material.dart';

import '../data/history_repo.dart';
import '../data/repo.dart';
import 'common.dart';
import 'history.dart';
import 'theme.dart';

class DreamsPage extends StatefulWidget {
  const DreamsPage({super.key});

  @override
  State<DreamsPage> createState() => _DreamsPageState();
}

class _DreamsPageState extends State<DreamsPage> {
  late Future<List<Map<String, dynamic>>> _f = repo.dreams();
  void _reload() => setState(() {
    _f = repo.dreams();
  });

  Future<void> _add([Map<String, dynamic>? d]) async {
    final title = TextEditingController(text: d?['title']);
    final target = TextEditingController(
      text: d == null ? '' : fmtAmount(d['target'] as num),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d == null ? 'Impian baru' : 'Ubah impian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Apa impianmu?'),
            ),
            TextField(
              controller: target,
              keyboardType: TextInputType.number,
              inputFormatters: const [AmountFormatter()],
              decoration: const InputDecoration(
                labelText: 'Target',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final t = parseAmount(target.text);
    if (ok != true || !mounted) return;
    if (title.text.trim().isEmpty || t == null || t <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Isi impian dan target')));
      return;
    }
    await guarded(
      context,
      () => d == null
          ? repo.addDream(title.text.trim(), t)
          : repo.updateDream(d['id'], title.text.trim(), t),
      _reload,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Async<List<Map<String, dynamic>>>(
      future: _f,
      builder: (_, list) => list.isEmpty
          ? const EmptyState(icon: Icons.savings_outlined, message: 'Belum ada impian. Tambah satu!')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final d in list)
                  PastelCard(
                    color: C.accents[list.indexOf(d) % C.accents.length],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d['title'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Ubah',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _add(d),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  if (await confirmDelete(
                                        context,
                                        'Hapus impian "${d['title']}"?',
                                      ) &&
                                      context.mounted) {
                                    await guarded(
                                      context,
                                      () => repo.deleteDream(d['id']),
                                      _reload,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          LinearProgressIndicator(
                            value: ((d['saved'] as num) / (d['target'] as num))
                                .clamp(0, 1)
                                .toDouble(),
                          ),
                          const SizedBox(height: 6),
                          Text('${rp(d['saved'])} / ${rp(d['target'])}'),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    final changed = await showHistory(
                                      context,
                                      title: 'Riwayat tabungan - ${d['title']}',
                                      load: () =>
                                          repo.dreamContributions(d['id']),
                                      dateKey: 'saved_on',
                                      onDelete: repo.deleteDreamContribution,
                                      total: d['saved'],
                                    );
                                    if (changed) _reload();
                                  },
                                  child: const Text('Riwayat'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final v = await askAmount(
                                      context,
                                      'Tambah tabungan',
                                    );
                                    if (v != null && context.mounted) {
                                      await guarded(
                                        context,
                                        () => repo.contributeDream(d, v),
                                        _reload,
                                      );
                                    }
                                  },
                                  child: const Text('Menabung'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _add,
      child: const Icon(Icons.add),
    ),
  );
}
