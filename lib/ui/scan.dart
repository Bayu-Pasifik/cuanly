import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../data/insights.dart';
import '../data/receipt.dart';
import '../data/repo.dart';
import 'common.dart';
import 'theme.dart';
import 'transactions.dart';

/// Reads a receipt photo on the device (ML Kit) and opens the add-expense form pre-filled.
class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  bool _busy = false;
  String? _message;

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 90);
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final text = await recognizer.processImage(InputImage.fromFile(File(file.path)));
      final r = parseReceipt(text.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = r.isEmpty ? 'Teks struk tidak terbaca. Coba foto lebih dekat dan terang.' : null;
      });
      if (r.isEmpty) return;
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddTransactionSheet(prefill: {
          'kind': 'expense',
          'amount': r.total ?? 0,
          'category': r.category,
          'occurred_on': dateStr(r.date ?? DateTime.now()),
          'note': r.merchant ?? '',
        }),
      );
      if (saved == true && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = 'Gagal memindai: $e';
        });
      }
    } finally {
      await recognizer.close();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan struk')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          PastelCard(
            color: C.sky,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Foto struk, nominal terisi otomatis', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                SizedBox(height: 8),
                Text('Teks dibaca langsung di HP-mu. Foto tidak dikirim ke mana pun. '
                    'Periksa lagi nominal, tanggal, dan kategori sebelum menyimpan.'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : () => _scan(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Ambil foto struk'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _scan(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pilih dari galeri'),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_message!, style: const TextStyle(color: C.coral, fontWeight: FontWeight.w700)),
            ),
        ]),
      );
}

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late final Future<List<Insight>> _f = repo.insights();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Insight keuangan')),
        body: Async<List<Insight>>(
          future: _f,
          builder: (_, items) => ListView(padding: const EdgeInsets.all(16), children: [
            for (final i in items) InsightCard(insight: i),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Insight dihitung di perangkatmu dari transaksi bulan ini dan bulan lalu.',
                  style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
      );
}

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (insight.level) {
      InsightLevel.good => (C.mint, Icons.trending_down_rounded),
      InsightLevel.warning => (C.coral, Icons.warning_amber_rounded),
      InsightLevel.info => (C.lilac, Icons.lightbulb_outline),
    };
    return PastelCard(
      color: color,
      child: ListTile(
        leading: Icon(icon),
        title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(insight.body),
      ),
    );
  }
}
