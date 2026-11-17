import 'package:cuanly/data/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMoney', () {
    test('Indonesian and English formats', () {
      expect(parseMoney('125.000'), 125000);
      expect(parseMoney('125.000,00'), 125000);
      expect(parseMoney('125,000'), 125000);
      expect(parseMoney('125,000.50'), 125000);
      expect(parseMoney('1.250.000'), 1250000);
      expect(parseMoney('12500'), 12500);
      expect(parseMoney('0'), 0);
    });

    test('rejects non-amounts', () {
      expect(parseMoney('abc'), isNull);
      expect(parseMoney(''), isNull);
      expect(parseMoney('Rp'), isNull);
    });
  });

  test('amountsIn reads several amounts on a line', () {
    expect(amountsIn('2 x 15.000   30.000'), [2, 15000, 30000]);
    expect(amountsIn('no numbers'), isEmpty);
  });

  group('findDate', () {
    test('numeric day-first and 2-digit year', () {
      expect(findDate('Tgl 05/11/2026 14:30'), DateTime(2026, 11, 5));
      expect(findDate('05-11-26'), DateTime(2026, 11, 5));
    });
    test('ISO and named month', () {
      expect(findDate('2026-11-05 10:00'), DateTime(2026, 11, 5));
      expect(findDate('5 Nov 2026'), DateTime(2026, 11, 5));
      expect(findDate('12 Agustus 2026'), DateTime(2026, 8, 12));
    });
    test('rejects impossible dates', () {
      expect(findDate('31/02/2026'), isNull);
      expect(findDate('no date here'), isNull);
    });
  });

  group('guessCategory', () {
    test('matches by merchant keywords', () {
      expect(guessCategory('INDOMARET POINT'), 'Belanja');
      expect(guessCategory('SPBU Pertamina 34.123'), 'Transport');
      expect(guessCategory('Apotek Kimia Farma'), 'Kesehatan');
      expect(guessCategory('Warung Nasi Ibu Tini'), 'Makan');
    });
    test('null when nothing matches', () {
      expect(guessCategory('XYZ'), isNull);
    });
  });

  group('parseReceipt', () {
    const indomaret = '''
INDOMARET
JL. MERDEKA NO 1
05/11/2026 14:30
AQUA 600ML       2   6.000
ROTI TAWAR       1  15.500
SUBTOTAL            21.500
PPN                  2.150
TOTAL               23.650
TUNAI               50.000
KEMBALI             26.350
''';

    test('picks TOTAL, not subtotal, cash or change', () {
      final r = parseReceipt(indomaret);
      expect(r.total, 23650);
      expect(r.date, DateTime(2026, 11, 5));
      expect(r.merchant, 'INDOMARET');
      expect(r.category, 'Belanja');
    });

    test('grand total beats a plain total and the value may be on the next line', () {
      const t = 'Cafe Kopi Kita\nTOTAL 40.000\nDiskon 5.000\nGRAND TOTAL\nRp 35.000\n';
      expect(parseReceipt(t).total, 35000);
    });

    test('falls back to the largest plausible amount without a keyword', () {
      const t = 'Toko Maju\n1234567890123\nBakso 25.000\nEs teh 5.000\n';
      expect(parseReceipt(t).total, 25000);
    });

    // Real waserda receipt: no TOTAL line, cash 100.000, change 77.000, bill 23.000.
    const waserda = '''
WASERDA ANNUR
JL. SUROPATI 14
BULULAWANG
Telp: HAFIDZ 0895619846363 Fax:
No. : 4301/KSR/UTM/1126 16-11-2026
Kasir: ADMIN 18:15:14
KUKIS VANILA
7.000,00 x 1,00 PCS = 7.000,00
ITENG
7.000,00 x 1,00 PCS = 7.000,00
TIC-TAC BWG GORENG
9.000,00 x 1,00 RTG = 9.000,00
BARIS=3 QTY=3,00 23.000,00
Tunai
= 100.000,00
Kembali
= 77.000,00
''';

    test('no TOTAL line: uses the BARIS/QTY summary, not the cash given', () {
      final r = parseReceipt(waserda);
      expect(r.total, 23000);
      expect(r.date, DateTime(2026, 11, 16));
      expect(r.category, 'Belanja');
    });

    // What ML Kit actually returned on the device: read column by column, labels apart from values.
    const waserdaColumns =
        'JL, SUROPATI 14\nBULULAWANG\nTelp: HAFIDZ 0895619846363 Fax:\nNo.:4301/KSR/UTM/1126\nKasir: ADMIN\n'
        'Pel, : UMUM/CASH\nKUKIS VANILA\n7.000,00\nITENG\n7.000,00\n9.000,00\nTIC-TAC BMG GORENG\nBARIS=3\nTunai\n'
        'Kempali\nWSEROA ANUR\nX 1,00 PCS =\nx 1,00\nx 1,00\nQTY=3,00\nPCS =\nRTG =\n16-11-2026\n18:15:14\n'
        '7.000,00\n7.000,00\n9.000,00\n23.000,00\n100.000,00\n77.000,00\nBarang yang telah dibeli tidak dapat\n'
        'dikembalikan kecuali ada perjanjian';

    test('column-wise OCR: total found by arithmetic, address not used as merchant', () {
      final r = parseReceipt(waserdaColumns);
      expect(r.total, 23000);
      expect(r.date, DateTime(2026, 11, 16));
      expect(r.merchant, isNull);
    });

    test('no summary line: total is cash minus change', () {
      const t = 'Warung\nBakso 15.000\nTunai 100.000\nKembali 85.000\n';
      expect(parseReceipt(t).total, 15000);
    });

    test('address is never taken as the merchant', () {
      final r = parseReceipt('JL. SUROPATI 14\nBULULAWANG\nBakso 15.000\n');
      expect(r.merchant, isNull);
      expect(parseReceipt(waserda).merchant, 'WASERDA ANNUR');
    });

    test('empty and junk text', () {
      expect(parseReceipt('').isEmpty, isTrue);
      expect(parseReceipt('   \n  ').isEmpty, isTrue);
      expect(parseReceipt('??').total, isNull);
    });
  });
}
