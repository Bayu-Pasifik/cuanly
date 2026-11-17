/// Reads the useful fields (total, date, merchant, category) out of OCR text of a receipt.
/// Pure Dart so it can be unit-tested without a camera or the OCR engine.
class ReceiptData {
  const ReceiptData({this.total, this.date, this.merchant, this.category});
  final num? total;
  final DateTime? date;
  final String? merchant;

  /// One of the app's expense categories, or null when nothing matched.
  final String? category;

  bool get isEmpty => total == null && date == null && merchant == null;
}

final _amountToken = RegExp(r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?');

/// Parses one money token such as `125.000`, `125.000,00`, `125,000.50` or `12500` into rupiah.
/// Returns null when it does not look like an amount.
num? parseMoney(String token) {
  var t = token.trim();
  if (!RegExp(r'^\d[\d.,]*$').hasMatch(t)) return null;
  final lastDot = t.lastIndexOf('.'), lastComma = t.lastIndexOf(',');
  final last = lastDot > lastComma ? lastDot : lastComma;
  if (last >= 0) {
    final tail = t.substring(last + 1);
    // One or two digits after the last separator: decimals. Exactly three: thousands separator.
    if (tail.length <= 2) {
      t = t.substring(0, last);
    }
  }
  t = t.replaceAll('.', '').replaceAll(',', '');
  final v = num.tryParse(t);
  return v;
}

/// Amounts found in [line], left to right.
List<num> amountsIn(String line) {
  final out = <num>[];
  for (final m in _amountToken.allMatches(line)) {
    final v = parseMoney(m.group(0)!);
    if (v != null && v > 0) out.add(v);
  }
  return out;
}

const _totalKeywords = <List<String>>[
  ['grand total', 'total bayar', 'total tagihan', 'total belanja', 'total harga', 'total pembayaran', 'amount due', 'total due'],
  ['total'],
  ['jumlah', 'tagihan', 'amount'],
];

const _skipInTotal = ['subtotal', 'sub total', 'sub-total', 'kembali', 'change', 'diskon', 'discount', 'ppn', 'pajak', 'tax', 'item', 'qty'];

const _tenderWords = ['tunai', 'cash', 'bayar', 'dibayar', 'uang', 'tendered', 'debit', 'kartu', 'card'];
const _changeWords = ['kembali', 'kembalian', 'change'];

bool _hasAny(String lower, List<String> words) => words.any(lower.contains);

/// Last amount on [lines][i], or on the next line when this one has none (value printed below).
num? _amountAt(List<String> lines, int i) {
  var a = amountsIn(lines[i]);
  if (a.isEmpty && i + 1 < lines.length) a = amountsIn(lines[i + 1]);
  return a.isEmpty ? null : a.last;
}

/// Receipts without a TOTAL line (small shops, waserda): use the "BARIS=3 QTY=3,00 23.000,00"
/// summary line, else cash given minus change returned.
num? _totalWithoutKeyword(List<String> lines) {
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i].toLowerCase();
    if (l.contains('baris') || l.contains('qty')) {
      final a = amountsIn(lines[i]).where((v) => v >= 100).toList(); // skip the quantity itself
      if (a.isNotEmpty) return a.last;
    }
  }
  num? tender, change;
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i].toLowerCase();
    if (_hasAny(l, _changeWords)) {
      change ??= _amountAt(lines, i);
    } else if (_hasAny(l, _tenderWords)) {
      tender ??= _amountAt(lines, i);
    }
  }
  if (tender != null && change != null && tender > change) return tender - change;
  return _totalByArithmetic(lines);
}

/// OCR often reads a receipt column by column, so labels end up apart from their values
/// (`Tunai | Kembali | 23.000 | 100.000 | 77.000`). The numbers still add up: the bill equals the
/// sum of the item amounts just before it, and bill + change = cash given.
num? _totalByArithmetic(List<String> lines) {
  final all = <num>[];
  for (final l in lines) {
    for (final m in _amountToken.allMatches(l)) {
      final raw = m.group(0)!;
      final v = parseMoney(raw);
      if (v == null || v < 1000 || v > 100000000) continue;
      if (raw.length >= 10 && !raw.contains(RegExp(r'[.,]'))) continue; // phone numbers and barcodes
      all.add(v);
    }
  }
  num? best;
  // A value equal to the sum of the 2+ amounts right before it.
  for (var i = 2; i < all.length; i++) {
    num sum = 0;
    for (var j = i - 1; j >= 0 && i - j <= 12; j--) {
      sum += all[j];
      if (i - j >= 2 && sum == all[i] && (best == null || all[i] > best)) best = all[i];
    }
  }
  if (best != null) return best;
  // bill + change = cash given
  // The bill is printed before the change, so of the pair the earlier one is the bill.
  for (var a = 0; a < all.length; a++) {
    for (var b = a + 1; b < all.length; b++) {
      for (var c = 0; c < all.length; c++) {
        if (c != a && c != b && all[a] + all[b] == all[c]) return all[a];
      }
    }
  }
  return null;
}

num? _findTotal(List<String> lines) {
  for (var g = 0; g < _totalKeywords.length; g++) {
    if (g == 2) {
      final derived = _totalWithoutKeyword(lines);
      if (derived != null) return derived;
    }
    final group = _totalKeywords[g];
    final found = <num>[];
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if (!group.any(l.contains)) continue;
      if (_skipInTotal.any((s) => l.contains(s) && !group.any((g) => g.contains(s)))) continue;
      var a = amountsIn(lines[i]);
      if (a.isEmpty && i + 1 < lines.length) a = amountsIn(lines[i + 1]); // value printed on the next line
      if (a.isNotEmpty) found.add(a.last);
    }
    if (found.isNotEmpty) return found.reduce((a, b) => a > b ? a : b);
  }
  // No keyword: the biggest plausible amount (ignores barcodes and phone numbers).
  num? best;
  for (final l in lines) {
    final lower = l.toLowerCase();
    if (_hasAny(lower, _tenderWords) || _hasAny(lower, _changeWords)) continue; // cash given / change is not the bill
    for (final m in _amountToken.allMatches(l)) {
      final raw = m.group(0)!;
      final v = parseMoney(raw);
      if (v == null || v < 1000 || v > 100000000) continue;
      if (raw.length >= 10 && !raw.contains(RegExp(r'[.,]'))) continue;
      if (best == null || v > best) best = v;
    }
  }
  return best;
}

const _months = {
  'jan': 1, 'januari': 1, 'january': 1, 'feb': 2, 'februari': 2, 'february': 2, 'mar': 3, 'maret': 3, 'march': 3,
  'apr': 4, 'april': 4, 'mei': 5, 'may': 5, 'jun': 6, 'juni': 6, 'june': 6, 'jul': 7, 'juli': 7, 'july': 7,
  'agu': 8, 'agt': 8, 'agustus': 8, 'aug': 8, 'august': 8, 'sep': 9, 'sept': 9, 'september': 9,
  'okt': 10, 'oktober': 10, 'oct': 10, 'october': 10, 'nov': 11, 'november': 11, 'des': 12, 'desember': 12, 'dec': 12, 'december': 12,
};

DateTime? _valid(int y, int m, int d) {
  if (y < 100) y += 2000;
  if (y < 2000 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime(y, m, d);
  return dt.month == m ? dt : null; // rejects 31 Feb and similar
}

DateTime? findDate(String text) {
  // ISO first so "2026-11-05" is not misread as day-first "26-11-05".
  final iso = RegExp(r'(?<!\d)(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})(?!\d)').firstMatch(text);
  if (iso != null) {
    final d = _valid(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    if (d != null) return d;
  }
  for (final m in RegExp(r'(?<!\d)(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2})(?!\d)').allMatches(text)) {
    final d = _valid(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
    if (d != null) return d;
  }
  for (final m in RegExp(r'(?<!\d)(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4}|\d{2})(?!\d)').allMatches(text)) {
    final mon = _months[m.group(2)!.toLowerCase()];
    if (mon == null) continue;
    final d = _valid(int.parse(m.group(3)!), mon, int.parse(m.group(1)!));
    if (d != null) return d;
  }
  return null;
}

final _addressLine = RegExp(r'^(jl|jln|jalan|telp|tel|hp|wa|no|alamat|npwp)\b', caseSensitive: false);

String? _merchant(List<String> lines) {
  for (final l in lines.take(6)) {
    final t = l.trim();
    if (_addressLine.hasMatch(t)) break; // header ends at the address: the shop name was not read, do not guess

    final letters = RegExp(r'[A-Za-z]').allMatches(t).length;
    if (t.length < 3 || t.length > 40 || letters < 3 || letters / t.length < .6) continue;
    if (RegExp(r'^(struk|nota|receipt|invoice|kasir|tanggal|date)\b', caseSensitive: false).hasMatch(t)) continue;
    return t;
  }
  return null;
}

const _categoryHints = <String, List<String>>{
  'Makan': ['resto', 'restoran', 'cafe', 'kafe', 'warung', 'bakso', 'mie', 'ayam', 'kopi', 'coffee', 'bakery', 'pizza', 'burger', 'kfc', 'mcd', 'starbucks', 'sate', 'nasi', 'food'],
  'Transport': ['spbu', 'pertamina', 'shell', 'bensin', 'grab', 'gojek', 'parkir', 'tol', 'taxi', 'bluebird', 'kereta', 'krl', 'mrt', 'tiket pesawat'],
  'Belanja': ['indomaret', 'alfamart', 'alfamidi', 'supermarket', 'minimarket', 'hypermart', 'carrefour', 'lotte', 'transmart', 'mart', 'toko', 'mall', 'waserda', 'koperasi', 'swalayan'],
  'Tagihan': ['pln', 'pdam', 'telkom', 'indihome', 'listrik', 'token', 'pulsa', 'internet', 'bpjs'],
  'Hiburan': ['bioskop', 'cinema', 'xxi', 'cgv', 'netflix', 'spotify', 'game', 'karaoke'],
  'Kesehatan': ['apotek', 'apotik', 'klinik', 'rumah sakit', 'pharmacy', 'kimia farma', 'guardian', 'dokter'],
  'Pendidikan': ['sekolah', 'kampus', 'buku', 'gramedia', 'kursus', 'les '],
};

/// Guesses an expense category from the receipt text; null when nothing matches.
String? guessCategory(String text) {
  final t = text.toLowerCase();
  String? best;
  var bestHits = 0;
  for (final e in _categoryHints.entries) {
    final hits = e.value.where(t.contains).length;
    if (hits > bestHits) {
      best = e.key;
      bestHits = hits;
    }
  }
  return best;
}

ReceiptData parseReceipt(String text) {
  final lines = text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  if (lines.isEmpty) return const ReceiptData();
  return ReceiptData(
    total: _findTotal(lines),
    date: findDate(text),
    merchant: _merchant(lines),
    category: guessCategory(text),
  );
}
