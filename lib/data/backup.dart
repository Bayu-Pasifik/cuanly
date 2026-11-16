import 'dart:convert';

import 'repo.dart';

const backupVersion = 1;

/// Tables in foreign-key order: parents before the rows that reference them.
const backupTables = [
  'wallets',
  'categories',
  'transactions',
  'transfers',
  'dreams',
  'debts',
  'recurring',
  'category_budgets',
  'monthly_targets',
  'debt_payments',
  'dream_contributions',
  'spending_challenges',
  'travel_splits',
  'investments',
  'business_products',
  'business_sales',
  'business_expenses',
];

const _conflictKeys = {
  'category_budgets': 'user_id,category',
  'monthly_targets': 'user_id,month',
};

/// Serialises [tables] into the backup JSON document.
String encodeBackup(Map<String, List<Map<String, dynamic>>> tables, DateTime now) =>
    const JsonEncoder.withIndent(' ').convert({
      'app': 'cuanly',
      'version': backupVersion,
      'created_at': now.toUtc().toIso8601String(),
      'tables': tables,
    });

/// Parses and validates a backup document. Throws [FormatException] when it is not a Cuanly backup.
Map<String, List<Map<String, dynamic>>> decodeBackup(String text) {
  final Object? doc;
  try {
    doc = jsonDecode(text);
  } catch (_) {
    throw const FormatException('Bukan berkas backup Cuanly');
  }
  if (doc is! Map || doc['app'] != 'cuanly' || doc['tables'] is! Map) {
    throw const FormatException('Bukan berkas backup Cuanly');
  }
  final v = doc['version'];
  if (v is! int || v > backupVersion) throw const FormatException('Versi backup tidak didukung');
  final raw = doc['tables'] as Map;
  final out = <String, List<Map<String, dynamic>>>{};
  for (final t in backupTables) {
    final rows = raw[t];
    if (rows == null) continue;
    if (rows is! List || rows.any((r) => r is! Map)) throw FormatException('Data "$t" rusak');
    out[t] = [for (final r in rows) Map<String, dynamic>.from(r as Map)];
  }
  return out;
}

class BackupRepo {
  /// Reads every table of the signed-in user.
  Future<Map<String, List<Map<String, dynamic>>>> fetchAll() async => {
        for (final t in backupTables) t: List<Map<String, dynamic>>.from(await db.from(t).select()),
      };

  Future<String> export() async => encodeBackup(await fetchAll(), DateTime.now());

  /// Merges [tables] into the account: rows are upserted by id, existing rows that are not in the
  /// backup stay untouched. Returns the number of rows written.
  Future<int> restore(Map<String, List<Map<String, dynamic>>> tables) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) throw StateError('Belum masuk');
    var n = 0;
    for (final t in backupTables) {
      final rows = tables[t];
      if (rows == null || rows.isEmpty) continue;
      final owned = [for (final r in rows) {...r, 'user_id': uid}];
      for (var i = 0; i < owned.length; i += 200) {
        final chunk = owned.sublist(i, i + 200 > owned.length ? owned.length : i + 200);
        await db.from(t).upsert(chunk, onConflict: _conflictKeys[t]);
      }
      n += owned.length;
    }
    return n;
  }
}

final backupRepo = BackupRepo();
