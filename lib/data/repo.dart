import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get db => Supabase.instance.client;

const expenseCategories = ['Makan', 'Transport', 'Belanja', 'Tagihan', 'Hiburan', 'Kesehatan', 'Pendidikan', 'Lainnya'];
const incomeCategories = ['Gaji', 'Bonus', 'Usaha', 'Hadiah', 'Lainnya'];

String dateStr(DateTime d) => d.toIso8601String().substring(0, 10);
String monthStart(DateTime d) => dateStr(DateTime(d.year, d.month, 1));

class Repo {
  Future<List<Map<String, dynamic>>> wallets() async =>
      List<Map<String, dynamic>>.from(await db.from('wallets').select().order('created_at'));

  Future<void> addWallet(String name, String type, num balance) =>
      db.from('wallets').insert({'name': name, 'type': type, 'balance': balance});

  Future<void> deleteWallet(String id) => db.from('wallets').delete().eq('id', id);

  Future<List<Map<String, dynamic>>> transactions({DateTime? month}) async {
    var q = db.from('transactions').select();
    if (month != null) {
      q = q
          .gte('occurred_on', monthStart(month))
          .lt('occurred_on', monthStart(DateTime(month.year, month.month + 1, 1)));
    }
    return List<Map<String, dynamic>>.from(
        await q.order('occurred_on', ascending: false).order('created_at', ascending: false));
  }

  /// Inserts a transaction and adjusts the wallet balance.
  Future<void> addTransaction({
    required String kind,
    required num amount,
    required String category,
    String? note,
    String? walletId,
    DateTime? date,
  }) async {
    await db.from('transactions').insert({
      'kind': kind,
      'amount': amount,
      'category': category,
      'note': note,
      'wallet_id': walletId,
      'occurred_on': dateStr(date ?? DateTime.now()),
    });
    if (walletId != null) await _adjustWallet(walletId, kind == 'income' ? amount : -amount);
  }

  /// Updates a transaction and re-balances wallets (old effect reverted, new applied).
  Future<void> updateTransaction(
    Map<String, dynamic> old, {
    required String kind,
    required num amount,
    required String category,
    String? note,
    String? walletId,
    required DateTime date,
  }) async {
    await db.from('transactions').update({
      'kind': kind,
      'amount': amount,
      'category': category,
      'note': note,
      'wallet_id': walletId,
      'occurred_on': dateStr(date),
    }).eq('id', old['id']);
    final ow = old['wallet_id'] as String?;
    final oamt = old['amount'] as num;
    if (ow != null) await _adjustWallet(ow, old['kind'] == 'income' ? -oamt : oamt);
    if (walletId != null) await _adjustWallet(walletId, kind == 'income' ? amount : -amount);
  }

  Future<void> deleteTransaction(Map<String, dynamic> t) async {
    await db.from('transactions').delete().eq('id', t['id']);
    final w = t['wallet_id'] as String?;
    if (w != null) {
      final amt = t['amount'] as num;
      await _adjustWallet(w, t['kind'] == 'income' ? -amt : amt);
    }
  }

  Future<void> transfer(String fromId, String toId, num amount) async {
    await db.from('transfers').insert({'from_wallet': fromId, 'to_wallet': toId, 'amount': amount});
    await _adjustWallet(fromId, -amount);
    await _adjustWallet(toId, amount);
  }

  /// Transfers of [month], newest first, each tagged kind 'transfer' with wallet names in 'note'.
  Future<List<Map<String, dynamic>>> transfers(DateTime month) async {
    final rows = List<Map<String, dynamic>>.from(await db
        .from('transfers')
        .select()
        .gte('occurred_on', monthStart(month))
        .lt('occurred_on', monthStart(DateTime(month.year, month.month + 1, 1)))
        .order('occurred_on', ascending: false)
        .order('created_at', ascending: false));
    final names = {for (final w in await wallets()) w['id']: w['name']};
    return [
      for (final r in rows)
        {
          ...r,
          'kind': 'transfer',
          'category': 'Transfer',
          'note': '${names[r['from_wallet']] ?? '?'} ke ${names[r['to_wallet']] ?? '?'}',
        }
    ];
  }

  Future<void> deleteTransfer(Map<String, dynamic> t) async {
    await db.from('transfers').delete().eq('id', t['id']);
    final amt = t['amount'] as num;
    if (t['from_wallet'] != null) await _adjustWallet(t['from_wallet'], amt);
    if (t['to_wallet'] != null) await _adjustWallet(t['to_wallet'], -amt);
  }

  Future<void> _adjustWallet(String id, num delta) async {
    final row = await db.from('wallets').select('balance').eq('id', id).single();
    await db.from('wallets').update({'balance': (row['balance'] as num) + delta}).eq('id', id);
  }

  Future<num?> budget(DateTime month) async {
    final r = await db.from('monthly_targets').select('budget').eq('month', monthStart(month)).maybeSingle();
    return r?['budget'] as num?;
  }

  Future<void> setBudget(DateTime month, num value) =>
      db.from('monthly_targets').upsert({'month': monthStart(month), 'budget': value}, onConflict: 'user_id,month');

  Future<List<Map<String, dynamic>>> dreams() async =>
      List<Map<String, dynamic>>.from(await db.from('dreams').select().order('created_at'));
  Future<void> addDream(String title, num target) => db.from('dreams').insert({'title': title, 'target': target});
  Future<void> contributeDream(Map<String, dynamic> d, num amount) =>
      db.from('dreams').update({'saved': (d['saved'] as num) + amount}).eq('id', d['id']);
  Future<void> deleteDream(String id) => db.from('dreams').delete().eq('id', id);

  Future<List<Map<String, dynamic>>> debts() async =>
      List<Map<String, dynamic>>.from(await db.from('debts').select().order('created_at'));
  Future<void> addDebt(String person, String direction, num total, DateTime? due) => db.from('debts').insert({
        'person': person,
        'direction': direction,
        'total': total,
        'due_on': due == null ? null : dateStr(due),
      });
  Future<void> payDebt(Map<String, dynamic> d, num amount) =>
      db.from('debts').update({'paid': (d['paid'] as num) + amount}).eq('id', d['id']);
  Future<void> deleteDebt(String id) => db.from('debts').delete().eq('id', id);
}

final repo = Repo();
