import 'package:flutter/material.dart';

import '../data/investments.dart';
import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';

class InvestmentsPage extends StatefulWidget {
  const InvestmentsPage({super.key});

  @override
  State<InvestmentsPage> createState() => _InvestmentsPageState();
}

class _InvestmentsPageState extends State<InvestmentsPage> {
  late Future<List<Map<String, dynamic>>> _f = repo.investments();

  void _reload() => setState(() {
        _f = repo.investments();
      });

  Future<void> _add() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddInvestmentSheet(),
    );
    if (ok == true) _reload();
  }

  Future<void> _updateValue(Map<String, dynamic> r) async {
    final v = await askAmount(context, 'Nilai ${r['investment_type']} saat ini');
    if (v == null || !mounted) return;
    await guarded(context, () => repo.updateInvestmentValue(r['id'], v), _reload);
  }

  Future<void> _sell(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tandai ${r['investment_type']} terjual?'),
        content: const Text('Investasi keluar dari ringkasan portofolio. Riwayatnya tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Jual')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await guarded(context, () => repo.sellInvestment(r['id']), _reload);
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    if (!await confirmDelete(context, 'Hapus ${r['investment_type']}?')) return;
    if (!mounted) return;
    await guarded(context, () => repo.deleteInvestment(r['id']), _reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Investasi')),
        floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
        body: Async<List<Map<String, dynamic>>>(
          future: _f,
          builder: (_, rows) {
            final p = summarize(rows);
            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
              PortfolioCard(portfolio: p),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => RecommendationSheet(initialTotal: p.value > 0 ? p.value : null),
                ),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Lihat rekomendasi alokasi'),
              ),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Belum ada investasi.\nCatat modal dan nilai terkini untuk memantau untung rugi.',
                        textAlign: TextAlign.center))
              else
                for (final r in rows)
                  InvestmentTile(
                    row: r,
                    onValue: () => _updateValue(r),
                    onSell: () => _sell(r),
                    onDelete: () => _delete(r),
                  ),
            ]);
          },
        ),
      );
}

String signedRp(num v) => v < 0 ? '-${rp(-v)}' : '+${rp(v)}';

class PortfolioCard extends StatelessWidget {
  const PortfolioCard({super.key, required this.portfolio});
  final Portfolio portfolio;

  @override
  Widget build(BuildContext context) {
    final p = portfolio;
    final pct = p.gainPercent;
    return PastelCard(
      color: C.mint,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nilai portofolio', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(rp(p.value), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
          Text('Modal ${rp(p.capital)}'),
          Text(
            pct == null ? 'Belum ada investasi aktif' : '${signedRp(p.gain)} (${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)',
            style: TextStyle(fontWeight: FontWeight.w800, color: p.gain < 0 ? const Color(0xFFB3261E) : null),
          ),
          if (p.byType.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Alokasi', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white54),
              child: Row(children: [
                for (var i = 0; i < p.byType.length; i++)
                  Expanded(
                    flex: (p.byType[i].value / p.value * 1000).round().clamp(1, 1000),
                    child: Container(key: ValueKey('alloc-$i'), color: C.chart[i % C.chart.length]),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 14, runSpacing: 4, children: [
              for (var i = 0; i < p.byType.length; i++)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(radius: 5, backgroundColor: C.chart[i % C.chart.length]),
                  const SizedBox(width: 6),
                  Text('${p.byType[i].type} ${(p.byType[i].value / p.value * 100).round()}%'),
                ]),
            ]),
          ],
        ]),
      ),
    );
  }
}

class InvestmentTile extends StatelessWidget {
  const InvestmentTile({super.key, required this.row, required this.onValue, required this.onSell, required this.onDelete});
  final Map<String, dynamic> row;
  final VoidCallback onValue, onSell, onDelete;

  @override
  Widget build(BuildContext context) {
    final sold = row['status'] == 'sold';
    final cap = row['amount'] as num;
    final val = (row['current_value'] as num?) ?? cap;
    final gain = val - cap;
    final t = investmentType(row['investment_type']);
    return Card(
      child: ListTile(
        onTap: sold ? null : onValue,
        title: Text('${t.code}  -  ${t.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Modal ${rp(cap)}  -  ${row['purchase_date']}  -  Risiko ${riskLabel(t.risk)}'
            '${sold ? '  -  TERJUAL' : ''}${(row['notes'] as String?)?.isNotEmpty == true ? '\n${row['notes']}' : ''}'),
        isThreeLine: (row['notes'] as String?)?.isNotEmpty == true,
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(rp(val), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(signedRp(gain), style: TextStyle(color: gain < 0 ? C.coral : null, fontSize: 12)),
        ]),
        onLongPress: () => showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (!sold)
                ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Ubah nilai saat ini'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onValue();
                    }),
              if (!sold)
                ListTile(
                    leading: const Icon(Icons.sell_outlined),
                    title: const Text('Tandai terjual'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onSell();
                    }),
              ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Hapus'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  }),
            ]),
          ),
        ),
      ),
    );
  }
}

class AddInvestmentSheet extends StatefulWidget {
  const AddInvestmentSheet({super.key});

  @override
  State<AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends State<AddInvestmentSheet> {
  String _type = investmentTypes.first.code;
  final _capital = TextEditingController();
  final _value = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final cap = parseAmount(_capital.text);
    final val = _value.text.trim().isEmpty ? null : parseAmount(_value.text);
    if (cap == null || cap <= 0) {
      setState(() => _error = 'Modal harus lebih dari 0');
      return;
    }
    if (_value.text.trim().isNotEmpty && (val == null || val < 0)) {
      setState(() => _error = 'Nilai saat ini tidak valid');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repo.addInvestment(_type, cap, val, _date, _notes.text);
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
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tambah investasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Jenis'),
              items: [
                for (final t in investmentTypes)
                  DropdownMenuItem(
                      value: t.code,
                      child: Text('${t.code} - ${t.name} (${riskLabel(t.risk)})', maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _capital,
                keyboardType: TextInputType.number,
                inputFormatters: const [AmountFormatter()],
                decoration: const InputDecoration(labelText: 'Modal', prefixText: 'Rp ')),
            const SizedBox(height: 12),
            TextField(
                controller: _value,
                keyboardType: TextInputType.number,
                inputFormatters: const [AmountFormatter()],
                decoration: const InputDecoration(labelText: 'Nilai saat ini (opsional)', prefixText: 'Rp ', helperText: 'Kosong = sama dengan modal')),
            const SizedBox(height: 4),
            TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.event), label: Text('Dibeli ${dateStr(_date)}')),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: C.coral, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _save, child: const Text('Simpan'))),
          ]),
        ),
      );
}

/// Allocation suggestions per risk profile for an amount the user types in.
class RecommendationSheet extends StatefulWidget {
  const RecommendationSheet({super.key, this.initialTotal});
  final num? initialTotal;

  @override
  State<RecommendationSheet> createState() => _RecommendationSheetState();
}

class _RecommendationSheetState extends State<RecommendationSheet> {
  late final _total = TextEditingController(text: widget.initialTotal == null ? '' : fmtAmount(widget.initialTotal!));
  String _profile = 'moderate';

  @override
  Widget build(BuildContext context) {
    final total = parseAmount(_total.text) ?? 0;
    final info = riskProfiles[_profile]!;
    final amounts = recommendedAmounts(_profile, total);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Rekomendasi alokasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [for (final e in riskProfiles.entries) ButtonSegment(value: e.key, label: Text(e.value.title))],
            selected: {_profile},
            onSelectionChanged: (s) => setState(() => _profile = s.first),
          ),
          const SizedBox(height: 8),
          Text(info.description),
          const SizedBox(height: 8),
          TextField(
            controller: _total,
            keyboardType: TextInputType.number,
            inputFormatters: const [AmountFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Dana yang diinvestasikan', prefixText: 'Rp '),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < info.allocation.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 8, backgroundColor: C.chart[i % C.chart.length]),
              title: Text('${info.allocation[i].type}  ${info.allocation[i].percent}%'),
              subtitle: Text(investmentType(info.allocation[i].type).name),
              trailing: Text(total > 0 ? rp(amounts[i].amount) : '-', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          const Text('Ini panduan umum, bukan saran keuangan. Sesuaikan dengan tujuan dan toleransi risikomu.',
              style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
