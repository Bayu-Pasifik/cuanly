import 'package:flutter/material.dart';

import '../data/repo.dart';
import 'common.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _kind = 'expense';
  late Future<List<Map<String, dynamic>>> _f = repo.categoryRows(_kind);

  void _reload() => setState(() {
        _f = repo.categoryRows(_kind);
      });

  Future<String?> _askName(String title, [String initial = '']) async {
    final c = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Nama kategori')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    final v = c.text.trim();
    return (ok == true && v.isNotEmpty) ? v : null;
  }

  Future<void> _add() async {
    final n = await _askName('Kategori baru');
    if (n != null && mounted) await guarded(context, () => repo.addCategory(_kind, n), _reload);
  }

  Future<void> _rename(Map<String, dynamic> row) async {
    final n = await _askName('Ubah kategori', row['name']);
    if (n != null && n != row['name'] && mounted) {
      await guarded(context, () => repo.renameCategory(row, n), _reload);
    }
  }

  Future<void> _delete(Map<String, dynamic> row, int total) async {
    if (total <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal harus ada satu kategori')));
      return;
    }
    final ok = await confirmDelete(context, 'Hapus kategori "${row['name']}"?',
        message: 'Transaksi lama tetap memakai nama ini.');
    if (ok && mounted) await guarded(context, () => repo.deleteCategory(row), _reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kategori')),
        floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                ButtonSegment(value: 'income', label: Text('Pemasukan')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) {
                _kind = s.first;
                _reload();
              },
            ),
          ),
          Expanded(
            child: Async<List<Map<String, dynamic>>>(
              future: _f,
              builder: (_, rows) => ListView(children: [
                for (final r in rows)
                  ListTile(
                    title: Text(r['name']),
                    onTap: () => _rename(r),
                    trailing: IconButton(
                      tooltip: 'Hapus',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(r, rows.length),
                    ),
                  ),
              ]),
            ),
          ),
        ]),
      );
}
