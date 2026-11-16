import 'package:flutter/material.dart';

import '../data/recurring_repo.dart';
import '../data/repo.dart';
import 'common.dart';

class RecurringPage extends StatefulWidget {
  const RecurringPage({super.key});

  @override
  State<RecurringPage> createState() => _RecurringPageState();
}

class _RecurringPageState extends State<RecurringPage> {
  late Future<List<List<Map<String, dynamic>>>> _f = _load();

  Future<List<List<Map<String, dynamic>>>> _load() => Future.wait([repo.recurringList(), repo.wallets()]);
  void _reload() => setState(() {
        _f = _load();
      });

  Future<void> _add() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddRecurringSheet(),
    );
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Transaksi berulang')),
        floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
        body: Async<List<List<Map<String, dynamic>>>>(
          future: _f,
          builder: (_, data) {
            final rows = data[0];
            final names = {for (final w in data[1]) w['id']: w['name']};
            if (rows.isEmpty) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada transaksi berulang.\nContoh: gaji, listrik, kos tiap bulan.',
                          textAlign: TextAlign.center)));
            }
            return ListView(children: [
              for (final r in rows)
                Dismissible(
                  key: ValueKey(r['id']),
                  background: Container(color: Colors.red.shade100),
                  confirmDismiss: (_) => confirmDelete(context, 'Hapus transaksi berulang?',
                      message: 'Transaksi yang sudah tercatat tidak ikut terhapus.'),
                  onDismissed: (_) => guarded(context, () => repo.deleteRecurring(r['id']), _reload),
                  child: ListTile(
                    title: Text('${r['category']} • ${rp(r['amount'])}'),
                    subtitle: Text([
                      'Tiap tanggal ${r['day_of_month']}',
                      if (r['wallet_id'] != null && names[r['wallet_id']] != null) names[r['wallet_id']],
                      r['active'] == true ? 'Berikutnya ${r['next_due']}' : 'Dijeda',
                    ].join(' • ')),
                    leading: Icon(r['kind'] == 'income' ? Icons.south_west_rounded : Icons.north_east_rounded),
                    trailing: Switch(
                      value: r['active'] == true,
                      onChanged: (v) => guarded(context, () => repo.setRecurringActive(r, v), _reload),
                    ),
                  ),
                ),
            ]);
          },
        ),
      );
}

class _AddRecurringSheet extends StatefulWidget {
  const _AddRecurringSheet();

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  String _kind = 'expense';
  String? _category;
  String? _walletId;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _day = TextEditingController(text: DateTime.now().day.toString());
  final _cats = <String, List<String>>{};
  late final Future<List<Map<String, dynamic>>> _wallets = repo.wallets();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    final kind = _kind;
    final names = await repo.categoryNames(kind);
    if (mounted) setState(() => _cats[kind] = names);
  }

  Future<void> _save() async {
    final amt = parseAmount(_amount.text);
    final day = int.tryParse(_day.text.trim());
    if (amt == null || amt <= 0 || _category == null || day == null || day < 1 || day > 31) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Isi nominal, kategori, dan tanggal (1-31).')));
      return;
    }
    setState(() => _busy = true);
    await guarded(
        context,
        () => repo.addRecurring(
            kind: _kind,
            amount: amt,
            category: _category!,
            note: _note.text.trim(),
            walletId: _walletId,
            day: day),
        () {});
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                ButtonSegment(value: 'income', label: Text('Pemasukan')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) {
                setState(() {
                  _kind = s.first;
                  _category = null;
                });
                if (!_cats.containsKey(_kind)) _loadCats();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final c in _cats[_kind] ?? const <String>[])
                ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _day,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Tanggal tiap bulan (1-31)',
                  helperText: 'Bulan yang lebih pendek memakai tanggal terakhir.',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _wallets,
              builder: (_, s) {
                final ws = s.data ?? const [];
                if (ws.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String>(
                  initialValue: _walletId,
                  decoration: const InputDecoration(labelText: 'Dompet (opsional)', border: OutlineInputBorder()),
                  items: [for (final w in ws) DropdownMenuItem(value: w['id'] as String, child: Text(w['name']))],
                  onChanged: (v) => setState(() => _walletId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _note, decoration: const InputDecoration(labelText: 'Catatan', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan')),
          ]),
        ),
      );
}
