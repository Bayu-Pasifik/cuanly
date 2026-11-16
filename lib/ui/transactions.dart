import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late Future<List<Map<String, dynamic>>> _f = repo.transactions(month: DateTime.now());

  void _reload() => setState(() { _f = repo.transactions(month: DateTime.now()); });

  Future<void> _add([Map<String, dynamic>? existing]) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionSheet(existing: existing),
    );
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Async<List<Map<String, dynamic>>>(
          future: _f,
          builder: (_, list) => list.isEmpty
              ? const Center(child: Text('Belum ada transaksi bulan ini.'))
              : RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final t = list[i];
                      final income = t['kind'] == 'income';
                      return Dismissible(
                        key: ValueKey(t['id']),
                        background: Container(color: Colors.red.shade100),
                        onDismissed: (_) => guarded(context, () => repo.deleteTransaction(t), _reload),
                        child: ListTile(
                          onTap: () => _add(t),
                          leading: CircleAvatar(
                              backgroundColor: income ? C.mint : C.coral,
                              foregroundColor: C.ink,
                              child: Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded, size: 18)),
                          title: Text(t['category']),
                          subtitle: Text([
                            DateFormat('d MMM', 'id_ID').format(DateTime.parse(t['occurred_on'])),
                            if ((t['note'] as String?)?.isNotEmpty ?? false) t['note'],
                          ].join(' • ')),
                          trailing: Text('${income ? '+' : '-'}${rp(t['amount'])}',
                              style: TextStyle(
                                  color: income ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      );
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _kind = 'expense';
  String? _category;
  String? _walletId;
  DateTime _date = DateTime.now();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late final Future<List<Map<String, dynamic>>> _wallets = repo.wallets();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _kind = e['kind'];
      _category = e['category'];
      _walletId = e['wallet_id'];
      _date = DateTime.parse(e['occurred_on']);
      _amount.text = (e['amount'] as num).round().toString();
      _note.text = e['note'] ?? '';
    }
  }

  List<String> get _cats => _kind == 'expense' ? expenseCategories : incomeCategories;

  Future<void> _save() async {
    final amt = parseAmount(_amount.text);
    if (amt == null || amt <= 0 || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nominal dan kategori.')));
      return;
    }
    setState(() => _busy = true);
    final e = widget.existing;
    await guarded(
      context,
      () => e == null
          ? repo.addTransaction(
              kind: _kind, amount: amt, category: _category!, note: _note.text.trim(), walletId: _walletId, date: _date)
          : repo.updateTransaction(e,
              kind: _kind, amount: amt, category: _category!, note: _note.text.trim(), walletId: _walletId, date: _date),
      () {},
    );
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
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _category = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp ', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final c in _cats)
                ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
            ]),
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
            TextField(controller: _note, decoration: const InputDecoration(labelText: 'Catatan', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(DateFormat('d MMMM y', 'id_ID').format(_date)),
              onPressed: () async {
                final d = await showDatePicker(
                    context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (d != null) setState(() => _date = d);
              },
            ),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan')),
          ]),
        ),
      );
}
