import 'package:flutter_test/flutter_test.dart';
import 'package:cuanly/data/export.dart';

void main() {
  final rows = [
    {'kind': 'expense', 'amount': 40000, 'category': 'Makan', 'note': 'nasi, "enak"', 'occurred_on': '2026-11-16', 'wallet_id': 'w1'},
    {'kind': 'income', 'amount': 100000, 'category': 'Gaji', 'note': '=1+1', 'occurred_on': '2026-11-15', 'wallet_id': null},
    {'kind': 'transfer', 'amount': 5000, 'category': 'Transfer', 'note': 'Kas ke Tunai', 'occurred_on': '2026-11-14', 'wallet_id': null},
  ];

  test('csv header, escaping, signs and formula guard', () {
    final lines = buildCsv(rows, {'w1': 'Kas'}).split('\r\n');
    expect(lines[0], '﻿Tanggal,Jenis,Kategori,Catatan,Dompet,Jumlah');
    expect(lines[1], '2026-11-16,Pengeluaran,Makan,"nasi, ""enak""",Kas,-40000');
    expect(lines[2], "2026-11-15,Pemasukan,Gaji,'=1+1,,100000");
    expect(lines[3], '2026-11-14,Transfer,Transfer,Kas ke Tunai,,5000');
    expect(lines[4], '');
  });

  test('pdf builds a valid document', () async {
    final bytes = await buildPdf('November 2026', rows, {'w1': 'Kas'});
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
