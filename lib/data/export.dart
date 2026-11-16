import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _kindLabel = {'income': 'Pemasukan', 'expense': 'Pengeluaran', 'transfer': 'Transfer'};

String _csvCell(Object? v) {
  final s = '${v ?? ''}';
  // Quote cells with separators/quotes/newlines; prefix formula triggers so spreadsheets
  // do not execute user-typed notes like "=1+1".
  final safe = RegExp(r'^[=+\-@]').hasMatch(s) && double.tryParse(s) == null ? "'$s" : s;
  return RegExp(r'[",\n\r]').hasMatch(safe) ? '"${safe.replaceAll('"', '""')}"' : safe;
}

/// CSV of [rows] (transactions and transfers as shown in the list), UTF-8 BOM for Excel.
String buildCsv(List<Map<String, dynamic>> rows, Map<dynamic, dynamic> walletNames) {
  final b = StringBuffer('﻿Tanggal,Jenis,Kategori,Catatan,Dompet,Jumlah\r\n');
  for (final r in rows) {
    final kind = r['kind'] as String;
    final amount = (r['amount'] as num);
    final line = [
      r['occurred_on'],
      _kindLabel[kind] ?? kind,
      r['category'],
      r['note'],
      kind == 'transfer' ? '' : walletNames[r['wallet_id']],
      // Expenses are negative so income/expense rows sum to the net change; transfers stay positive.
      kind == 'expense' ? -amount : amount,
    ].map(_csvCell).join(',');
    b.write('$line\r\n');
  }
  return b.toString();
}

/// PDF report of [rows] with income/expense totals for [title].
Future<Uint8List> buildPdf(String title, List<Map<String, dynamic>> rows, Map<dynamic, dynamic> walletNames) async {
  num income = 0, expense = 0;
  for (final r in rows) {
    if (r['kind'] == 'income') income += r['amount'] as num;
    if (r['kind'] == 'expense') expense += r['amount'] as num;
  }
  String money(num v) => 'Rp ${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (_) => [
      pw.Text('Cuanly - $title', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text('Pemasukan ${money(income)}   Pengeluaran ${money(expense)}   Selisih ${money(income - expense)}'),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        headers: const ['Tanggal', 'Jenis', 'Kategori', 'Catatan', 'Dompet', 'Jumlah'],
        cellAlignments: {5: pw.Alignment.centerRight},
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        data: [
          for (final r in rows)
            [
              r['occurred_on'],
              _kindLabel[r['kind']] ?? r['kind'],
              r['category'],
              r['note'] ?? '',
              r['kind'] == 'transfer' ? '' : (walletNames[r['wallet_id']] ?? ''),
              money(r['amount']),
            ],
        ],
      ),
    ],
  ));
  return doc.save();
}
