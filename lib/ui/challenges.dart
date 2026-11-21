import 'package:flutter/material.dart';

import '../data/challenges.dart';
import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';

typedef _Loaded = ({List<Map<String, dynamic>> rows, List<Map<String, dynamic>> expenses});

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  late Future<_Loaded> _f = _load();

  Future<_Loaded> _load() async {
    final rows = await repo.challenges();
    return (rows: rows, expenses: await repo.challengeExpenses(rows));
  }

  void _reload() => setState(() {
        _f = _load();
      });

  Future<void> _edit([Map<String, dynamic>? c]) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChallengeSheet(existing: c),
    );
    if (ok == true) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tantangan hemat')),
        floatingActionButton: FloatingActionButton(onPressed: _edit, child: const Icon(Icons.add)),
        body: Async<_Loaded>(
          future: _f,
          builder: (_, data) {
            if (data.rows.isEmpty) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada tantangan.\nContoh: jajan maksimal Rp 200.000 minggu ini.',
                          textAlign: TextAlign.center)));
            }
            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
              for (final c in data.rows)
                ChallengeCard(
                  challenge: c,
                  progress: challengeProgress(c, data.expenses, DateTime.now()),
                  onEdit: () => _edit(c),
                  onDelete: () async {
                    if (!await confirmDelete(context, 'Hapus tantangan "${c['title']}"?')) return;
                    if (!context.mounted) return;
                    await guarded(context, () => repo.deleteChallenge(c['id']), _reload);
                  },
                ),
            ]);
          },
        ),
      );
}

String _fmt(String iso) {
  final d = DateTime.parse(iso);
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${d.day} ${m[d.month - 1]}';
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.progress,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> challenge;
  final ChallengeProgress progress;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final color = p.over ? C.coral : (p.ratio >= .8 ? C.orange : C.mint);
    final status = switch (p.state) {
      ChallengeState.upcoming => 'Mulai ${p.daysLeft} hari lagi',
      ChallengeState.active => p.over ? 'Melebihi batas' : '${p.daysLeft} hari tersisa',
      ChallengeState.ended => p.over ? 'Gagal' : 'Berhasil',
    };
    final cats = splitCategories(challenge['category']).join(', ');
    final renew = challenge['auto_renew'] == true ? '  -  berulang' : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(challenge['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            IconButton(tooltip: 'Ubah', icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline), onPressed: onDelete),
          ]),
          Text('$cats  -  ${_fmt(challenge['start_date'])} - ${_fmt(challenge['end_date'])}$renew'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p.ratio.clamp(0, 1).toDouble(),
              minHeight: 14,
              color: color,
              backgroundColor: color.withValues(alpha: .25),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${rp(p.spent)} / ${rp(p.limit)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(status, style: TextStyle(fontWeight: FontWeight.w800, color: p.over ? C.coral : null)),
          ]),
          if (p.state == ChallengeState.active) Text(p.over ? 'Lebih ${rp(-p.remaining)}' : 'Sisa ${rp(p.remaining)}'),
        ]),
      ),
    );
  }
}

enum _Duration { weekly, monthly, custom }

class ChallengeSheet extends StatefulWidget {
  const ChallengeSheet({super.key, this.existing});
  final Map<String, dynamic>? existing;

  @override
  State<ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<ChallengeSheet> {
  final _title = TextEditingController();
  final _limit = TextEditingController();
  final _picked = <String>{};
  _Duration _dur = _Duration.weekly;
  late DateTimeRange _range = _preset(_Duration.weekly);
  bool _renew = false, _saving = false;
  String? _error;
  late final Future<List<String>> _cats = repo.categoryNames('expense');

  static DateTimeRange _preset(_Duration d) {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    return d == _Duration.monthly
        ? DateTimeRange(start: today, end: DateTime(today.year, today.month + 1, today.day - 1))
        : DateTimeRange(start: today, end: DateTime(today.year, today.month, today.day + 6));
  }

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c == null) return;
    _title.text = c['title'];
    _limit.text = fmtAmount(c['budget_limit'] as num);
    _picked.addAll(splitCategories(c['category']));
    _range = DateTimeRange(start: DateTime.parse(c['start_date']), end: DateTime.parse(c['end_date']));
    _renew = c['auto_renew'] == true;
    _dur = _Duration.custom;
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final limit = parseAmount(_limit.text);
    String? err;
    if (title.isEmpty) {
      err = 'Nama tantangan wajib diisi';
    } else if (_picked.isEmpty) {
      err = 'Pilih minimal satu kategori';
    } else if (limit == null || limit <= 0) {
      err = 'Batas pengeluaran harus lebih dari 0';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repo.saveChallenge(widget.existing, {
        'title': title,
        'category': _picked.join(','),
        'budget_limit': limit,
        'start_date': dateStr(_range.start),
        'end_date': dateStr(_range.end),
        'auto_renew': _renew,
      });
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
    final span = '${dateStr(_range.start)}  s/d  ${dateStr(_range.end)}';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.existing == null ? 'Tantangan baru' : 'Ubah tantangan',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Nama tantangan')),
          const SizedBox(height: 12),
          const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
          FutureBuilder<List<String>>(
            future: _cats,
            builder: (_, s) => Wrap(spacing: 8, children: [
              for (final c in {...?s.data, ..._picked})
                FilterChip(
                  label: Text(c),
                  selected: _picked.contains(c),
                  onSelected: (v) => setState(() => v ? _picked.add(c) : _picked.remove(c)),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limit,
            keyboardType: TextInputType.number,
            inputFormatters: const [AmountFormatter()],
            decoration: const InputDecoration(labelText: 'Batas pengeluaran', prefixText: 'Rp '),
          ),
          const SizedBox(height: 12),
          SegmentedButton<_Duration>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Duration.weekly, label: Text('Mingguan')),
              ButtonSegment(value: _Duration.monthly, label: Text('Bulanan')),
              ButtonSegment(value: _Duration.custom, label: Text('Kustom')),
            ],
            selected: {_dur},
            onSelectionChanged: (s) => setState(() {
              _dur = s.first;
              if (_dur != _Duration.custom) _range = _preset(_dur);
            }),
          ),
          if (_dur == _Duration.custom)
            TextButton.icon(onPressed: _pickRange, icon: const Icon(Icons.date_range), label: Text(span))
          else
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(span)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ulangi otomatis'),
            subtitle: const Text('Mulai periode baru setelah selesai'),
            value: _renew,
            onChanged: (v) => setState(() => _renew = v),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: C.coral, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _saving ? null : _save, child: const Text('Simpan')),
          ),
        ]),
      ),
    );
  }
}
