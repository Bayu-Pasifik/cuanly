import 'package:flutter/material.dart';

import '../data/repo.dart';
import '../data/travel.dart';
import 'common.dart';
import 'theme.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  late Future<List<Map<String, dynamic>>> _f = repo.trips();

  void _reload() => setState(() {
        _f = repo.trips();
      });

  Future<void> _new() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const TripEditorPage()));
    if (ok == true) _reload();
  }

  Future<void> _open(Map<String, dynamic> t) async {
    final deleted = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TripDetailPage(trip: t)));
    if (deleted == true) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Patungan perjalanan')),
        floatingActionButton: FloatingActionButton(onPressed: _new, child: const Icon(Icons.add)),
        body: Async<List<Map<String, dynamic>>>(
          future: _f,
          builder: (_, rows) {
            if (rows.isEmpty) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada perjalanan.\nCatat pengeluaran bersama lalu bagi rata.',
                          textAlign: TextAlign.center)));
            }
            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
              for (final t in rows)
                Card(
                  child: ListTile(
                    onTap: () => _open(t),
                    leading: const CircleAvatar(backgroundColor: C.sky, foregroundColor: C.ink, child: Icon(Icons.flight_takeoff)),
                    title: Text(t['trip_name'], style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${tripPeople(t).length} orang  -  ${rp(splitTrip(tripPeople(t), tripExpenses(t)).perPerson)} / orang'),
                    trailing: Text(rp(t['total_amount'] as num), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ]);
          },
        ),
      );
}

class TripDetailPage extends StatelessWidget {
  const TripDetailPage({super.key, required this.trip});
  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    final people = tripPeople(trip);
    final expenses = tripExpenses(trip);
    final split = splitTrip(people, expenses);
    return Scaffold(
      appBar: AppBar(
        title: Text(trip['trip_name']),
        actions: [
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (!await confirmDelete(context, 'Hapus perjalanan "${trip['trip_name']}"?')) return;
              if (!context.mounted) return;
              try {
                await repo.deleteTrip(trip['id']);
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [SplitSummary(people: people, expenses: expenses, split: split)]),
    );
  }
}

/// Total, per-person share, balances, who-pays-whom and the expense list.
class SplitSummary extends StatelessWidget {
  const SplitSummary({super.key, required this.people, required this.expenses, required this.split});
  final List<String> people;
  final List<Map<String, dynamic>> expenses;
  final TripSplit split;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PastelCard(
          color: C.sky,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total pengeluaran', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(rp(split.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
                Text('${rp(split.perPerson)} per orang (${people.length} orang)'),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Saldo peserta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        for (final p in people)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(p),
            trailing: Text(
              (split.balances[p]! >= 0.5 ? 'Dapat ${rp(split.balances[p]!)}' : split.balances[p]! <= -0.5 ? 'Bayar ${rp(-split.balances[p]!)}' : 'Lunas'),
              style: TextStyle(fontWeight: FontWeight.w800, color: split.balances[p]! <= -0.5 ? C.coral : null),
            ),
          ),
        const SizedBox(height: 8),
        const Text('Cara melunasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        if (split.settlements.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tidak ada yang perlu dibayar.'))
        else
          for (final s in split.settlements)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.arrow_forward),
              title: Text('${s.from} ke ${s.to}'),
              trailing: Text(rp(s.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        const SizedBox(height: 8),
        const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        for (final e in expenses)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(e['description'] ?? ''),
            subtitle: Text('Dibayar ${e['paidBy']}'),
            trailing: Text(rp(e['amount'] as num)),
          ),
      ]);
}

class TripEditorPage extends StatefulWidget {
  const TripEditorPage({super.key});

  @override
  State<TripEditorPage> createState() => _TripEditorPageState();
}

class _ExpenseRow {
  final desc = TextEditingController();
  final amount = TextEditingController();
  String? paidBy;
}

class _TripEditorPageState extends State<TripEditorPage> {
  final _name = TextEditingController();
  final _people = [TextEditingController(), TextEditingController()];
  final _rows = [_ExpenseRow()];
  bool _saving = false;
  String? _error;

  List<String> get _names => [for (final c in _people) c.text.trim()];

  List<Map<String, dynamic>> get _expenses => [
        for (final r in _rows)
          if (r.desc.text.trim().isNotEmpty || r.amount.text.trim().isNotEmpty)
            {'description': r.desc.text.trim(), 'amount': parseAmount(r.amount.text) ?? 0, 'paidBy': r.paidBy},
      ];

  Future<void> _save() async {
    final err = validateTrip(_name.text, _names, _expenses);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repo.addTrip(_name.text, _names, _expenses);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = _names.where((n) => n.isNotEmpty).toList();
    final preview = splitTrip(names, _expenses);
    return Scaffold(
      appBar: AppBar(title: const Text('Perjalanan baru')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama perjalanan')),
        const SizedBox(height: 16),
        const Text('Peserta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        for (var i = 0; i < _people.length; i++)
          Row(children: [
            Expanded(
              child: TextField(
                controller: _people[i],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: 'Peserta ${i + 1}'),
              ),
            ),
            if (_people.length > 2)
              IconButton(
                tooltip: 'Hapus peserta',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  final gone = _people.removeAt(i).text.trim();
                  for (final r in _rows) {
                    if (r.paidBy == gone) r.paidBy = null;
                  }
                }),
              ),
          ]),
        TextButton.icon(
          onPressed: () => setState(() => _people.add(TextEditingController())),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Tambah peserta'),
        ),
        const SizedBox(height: 8),
        const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        for (var i = 0; i < _rows.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  Expanded(child: TextField(controller: _rows[i].desc, decoration: const InputDecoration(labelText: 'Keterangan'))),
                  if (_rows.length > 1)
                    IconButton(
                      tooltip: 'Hapus pengeluaran',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _rows.removeAt(i)),
                    ),
                ]),
                TextField(
                  controller: _rows[i].amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [AmountFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp '),
                ),
                DropdownButtonFormField<String>(
                  initialValue: names.contains(_rows[i].paidBy) ? _rows[i].paidBy : null,
                  decoration: const InputDecoration(labelText: 'Dibayar oleh'),
                  items: [for (final n in names) DropdownMenuItem(value: n, child: Text(n))],
                  onChanged: (v) => setState(() => _rows[i].paidBy = v),
                ),
              ]),
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() => _rows.add(_ExpenseRow())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah pengeluaran'),
        ),
        if (preview.total > 0 && names.length >= 2) ...[
          const SizedBox(height: 8),
          Text('Pratinjau: ${rp(preview.total)} total, ${rp(preview.perPerson)} per orang',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: C.coral, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Simpan perjalanan')),
      ]),
    );
  }
}
