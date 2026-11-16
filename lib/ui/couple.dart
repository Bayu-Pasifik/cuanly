import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/couple.dart';
import '../data/repo.dart';
import '../data/tracker.dart';
import 'common.dart';
import 'theme.dart';

class CouplePage extends StatefulWidget {
  const CouplePage({super.key});

  @override
  State<CouplePage> createState() => _CouplePageState();
}

class _CouplePageState extends State<CouplePage> {
  late Future<Map<String, dynamic>?> _f = repo.myCouple();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _reload() => setState(() {
        _f = repo.myCouple();
      });

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(coupleError(e))));
    }
    _reload();
  }

  Future<void> _enterCode() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan kode undangan'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'Contoh: A1B2C3D4'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terima')),
        ],
      ),
    );
    if (ok != true || normalizeInviteCode(c.text).isEmpty) return;
    await _run(() => repo.acceptInvite(c.text));
  }

  Future<void> _end(Map<String, dynamic> row) async {
    final active = coupleState(row) == CoupleState.active;
    final ok = await confirmDelete(
      context,
      active ? 'Akhiri kemitraan?' : 'Batalkan undangan?',
      message: active ? 'Kalian tidak akan saling melihat ringkasan lagi.' : null,
    );
    if (!ok) return;
    await _run(() => repo.endCouple(row['id']));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mode pasangan')),
        body: Async<Map<String, dynamic>?>(
          future: _f,
          builder: (_, row) => switch (coupleState(row)) {
            CoupleState.none => _Connect(onCreate: () => _run(repo.createInvite), onEnter: _enterCode),
            CoupleState.pending => isInviter(row!, db.auth.currentUser?.id)
                ? _Pending(code: row['invite_code'], onCancel: () => _end(row))
                : _Connect(onCreate: () => _run(repo.createInvite), onEnter: _enterCode),
            CoupleState.active => _Active(
                month: _month,
                onMonth: (m) => setState(() => _month = m),
                onEnd: () => _end(row!),
              ),
          },
        ),
      );
}

class _Connect extends StatelessWidget {
  const _Connect({required this.onCreate, required this.onEnter});
  final VoidCallback onCreate, onEnter;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        PastelCard(
          color: C.pink,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Atur uang bareng pasangan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              SizedBox(height: 8),
              Text('Hubungkan dua akun lewat kode undangan. Kalian hanya saling melihat total bulanan '
                  '(pengeluaran, pemasukan, kategori terbesar), bukan transaksi satu per satu.'),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onCreate, child: const Text('Buat kode undangan')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onEnter, child: const Text('Saya punya kode undangan')),
      ]);
}

class _Pending extends StatelessWidget {
  const _Pending({required this.code, required this.onCancel});
  final String code;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        PastelCard(
          color: C.yellow,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Menunggu pasangan', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SelectableText(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: 4)),
              const SizedBox(height: 4),
              const Text('Bagikan kode ini. Pasanganmu memasukkannya di menu Mode pasangan.'),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => SharePlus.instance.share(ShareParams(
                  text: 'Ayo atur uang bareng di Cuanly! Buka Menu > Mode pasangan, lalu masukkan kode undangan: $code')),
              icon: const Icon(Icons.share),
              label: const Text('Bagikan'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Salin kode',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode disalin')));
              }
            },
          ),
        ]),
        TextButton(onPressed: onCancel, child: const Text('Batalkan undangan')),
      ]);
}

class _Active extends StatelessWidget {
  const _Active({required this.month, required this.onMonth, required this.onEnd});
  final DateTime month;
  final ValueChanged<DateTime> onMonth;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => Async<CoupleSummary?>(
        // Keyed by month so the future is re-created when the month changes.
        key: ValueKey(month),
        future: repo.coupleSummary(month),
        builder: (_, s) => ListView(padding: const EdgeInsets.all(16), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                tooltip: 'Bulan sebelumnya',
                onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
                icon: const Icon(Icons.chevron_left)),
            Text(monthLabel(month), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            IconButton(
                tooltip: 'Bulan berikutnya',
                onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right)),
          ]),
          if (s == null)
            const Padding(padding: EdgeInsets.all(24), child: Text('Ringkasan belum tersedia.'))
          else
            CoupleSummaryView(summary: s),
          const SizedBox(height: 12),
          TextButton(onPressed: onEnd, child: const Text('Akhiri kemitraan')),
        ]),
      );
}

/// Combined spending plus a per-person comparison.
class CoupleSummaryView extends StatelessWidget {
  const CoupleSummaryView({super.key, required this.summary});
  final CoupleSummary summary;

  Widget _person(String label, CoupleMember m, Color color) => PastelCard(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(rp(m.expense), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            Text('Pemasukan ${rp(m.income)}'),
            Text(m.topCategory == null ? 'Belum ada pengeluaran' : 'Terbesar: ${m.topCategory}'),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PastelCard(
        color: C.lilac,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pengeluaran bersama', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(rp(s.combinedExpense), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s.myShare.clamp(0, 1).toDouble(),
                minHeight: 14,
                color: C.ink,
                backgroundColor: Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            Text('Kamu ${(s.myShare * 100).round()}%  -  Pasangan ${s.combinedExpense <= 0 ? 0 : 100 - (s.myShare * 100).round()}%'),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      _person('Kamu', s.me, C.mint),
      _person('Pasangan', s.partner, C.sky),
    ]);
  }
}
