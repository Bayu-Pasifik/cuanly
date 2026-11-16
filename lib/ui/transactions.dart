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
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late Future<List<Map<String, dynamic>>> _f = _fetch();

  String _q = '';
  String? _kindFilter;
  DateTimeRange? _range; // custom range replaces month navigation while set

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range ?? DateTimeRange(start: _month, end: DateTime(_month.year, _month.month + 1, 0)),
    );
    if (r != null) {
      _range = r;
      _reload();
    }
  }

  String _rangeLabel(DateTimeRange r) {
    final f = DateFormat('d MMM yyyy', 'id_ID');
    return '${f.format(r.start)} - ${f.format(r.end)}';
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final r = await Future.wait([
      if (_range == null) repo.transactions(month: _month) else repo.transactions(from: _range!.start, to: _range!.end),
      if (_range == null) repo.transfers(month: _month) else repo.transfers(from: _range!.start, to: _range!.end),
    ]);
    return [...r[0], ...r[1]]..sort((a, b) {
      final c = (b['occurred_on'] as String).compareTo(a['occurred_on'] as String);
      return c != 0 ? c : (b['created_at'] as String).compareTo(a['created_at'] as String);
    });
  }

  void _reload() => setState(() {
    _f = _fetch();
  });

  void _shift(int delta) {
    _month = DateTime(_month.year, _month.month + delta, 1);
    _reload();
  }

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
      builder: (_, all) {
        final list = all.where((t) {
          if (_kindFilter != null && t['kind'] != _kindFilter) return false;
          final q = _q.trim().toLowerCase();
          if (q.isEmpty) return true;
          return '${t['category']} ${t['note'] ?? ''}'.toLowerCase().contains(
            q,
          );
        }).toList();
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_range == null)
                  IconButton(
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                Text(
                  _range == null ? DateFormat('MMMM yyyy', 'id_ID').format(_month) : _rangeLabel(_range!),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (_range == null)
                  IconButton(
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                IconButton(
                  tooltip: 'Pilih rentang tanggal',
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range),
                ),
                if (_range != null)
                  IconButton(
                    tooltip: 'Kembali ke bulanan',
                    onPressed: () {
                      _range = null;
                      _reload();
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'Cari kategori atau catatan',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final o in const [
                    (null, 'Semua'),
                    ('expense', 'Pengeluaran'),
                    ('income', 'Pemasukan'),
                    ('transfer', 'Transfer'),
                  ])
                    ChoiceChip(
                      label: Text(o.$2),
                      selected: _kindFilter == o.$1,
                      onSelected: (_) => setState(() => _kindFilter = o.$1),
                    ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        all.isEmpty
                            ? (_range == null ? 'Belum ada transaksi di bulan ini.' : 'Belum ada transaksi di rentang ini.')
                            : 'Tidak ada hasil.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final t = list[i];
                          final income = t['kind'] == 'income';
                          final xfer = t['kind'] == 'transfer';
                          return Dismissible(
                            key: ValueKey(t['id']),
                            background: Container(color: Colors.red.shade100),
                            confirmDismiss: (_) => confirmDelete(context, xfer ? "Hapus transfer?" : "Hapus transaksi?", message: "Saldo dompet akan dikembalikan."),
                            onDismissed: (_) => guarded(
                              context,
                              () => xfer
                                  ? repo.deleteTransfer(t)
                                  : repo.deleteTransaction(t),
                              _reload,
                            ),
                            child: ListTile(
                              onTap: xfer ? null : () => _add(t),
                              leading: CircleAvatar(
                                backgroundColor: xfer
                                    ? Colors.blue.shade100
                                    : income
                                    ? C.mint
                                    : C.coral,
                                foregroundColor: C.ink,
                                child: Icon(
                                  xfer
                                      ? Icons.swap_horiz_rounded
                                      : income
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  size: 18,
                                ),
                              ),
                              title: Text(t['category']),
                              subtitle: Text(
                                [
                                  DateFormat(
                                    'd MMM',
                                    'id_ID',
                                  ).format(DateTime.parse(t['occurred_on'])),
                                  if ((t['note'] as String?)?.isNotEmpty ??
                                      false)
                                    t['note'],
                                ].join(' • '),
                              ),
                              trailing: Text(
                                '${xfer ? '' : income ? '+' : '-'}${rp(t['amount'])}',
                                style: TextStyle(
                                  color: xfer
                                      ? Colors.blue.shade700
                                      : income
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _add,
      child: const Icon(Icons.add),
    ),
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
    _loadCats();
  }

  final _catCache = <String, List<String>>{};

  Future<void> _loadCats() async {
    final kind = _kind;
    try {
      final names = await repo.categoryNames(kind);
      if (mounted) setState(() => _catCache[kind] = names);
    } catch (_) {
      if (mounted) setState(() => _catCache[kind] = kind == 'expense' ? expenseCategories : incomeCategories);
    }
  }

  List<String> get _cats {
    final base = _catCache[_kind] ?? const <String>[];
    final c = _category;
    // Keep a since-deleted category visible when editing an old transaction.
    return (c != null && !base.contains(c) && widget.existing?['kind'] == _kind) ? [...base, c] : base;
  }

  Future<void> _save() async {
    final amt = parseAmount(_amount.text);
    if (amt == null || amt <= 0 || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nominal dan kategori.')),
      );
      return;
    }
    setState(() => _busy = true);
    final e = widget.existing;
    await guarded(
      context,
      () => e == null
          ? repo.addTransaction(
              kind: _kind,
              amount: amt,
              category: _category!,
              note: _note.text.trim(),
              walletId: _walletId,
              date: _date,
            )
          : repo.updateTransaction(
              e,
              kind: _kind,
              amount: amt,
              category: _category!,
              note: _note.text.trim(),
              walletId: _walletId,
              date: _date,
            ),
      () {},
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      16,
      16,
      MediaQuery.of(context).viewInsets.bottom + 16,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              if (!_catCache.containsKey(_kind)) _loadCats();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final c in _cats)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _wallets,
            builder: (_, s) {
              final ws = s.data ?? const [];
              if (ws.isEmpty) return const SizedBox.shrink();
              return DropdownButtonFormField<String>(
                initialValue: _walletId,
                decoration: const InputDecoration(
                  labelText: 'Dompet (opsional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final w in ws)
                    DropdownMenuItem(
                      value: w['id'] as String,
                      child: Text(w['name']),
                    ),
                ],
                onChanged: (v) => setState(() => _walletId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Catatan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat('d MMMM y', 'id_ID').format(_date)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}
