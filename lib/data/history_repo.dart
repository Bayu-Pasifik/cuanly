import 'repo.dart';

/// Payment history for debts and contribution history for dreams.
/// The running total stays on the parent row (debts.paid / dreams.saved) and is
/// adjusted together with each history row.
extension HistoryRepo on Repo {
  Future<void> _bump(String table, String column, String id, num delta) async {
    final row = await db.from(table).select(column).eq('id', id).single();
    final next = (row[column] as num) + delta;
    await db.from(table).update({column: next < 0 ? 0 : next}).eq('id', id);
  }

  Future<void> payDebt(Map<String, dynamic> d, num amount) async {
    await db.from('debt_payments').insert({'debt_id': d['id'], 'amount': amount, 'paid_on': dateStr(DateTime.now())});
    await _bump('debts', 'paid', d['id'], amount);
  }

  Future<List<Map<String, dynamic>>> debtPayments(String debtId) async => List<Map<String, dynamic>>.from(
      await db.from('debt_payments').select().eq('debt_id', debtId).order('paid_on', ascending: false).order('created_at', ascending: false));

  Future<void> deleteDebtPayment(Map<String, dynamic> p) async {
    await db.from('debt_payments').delete().eq('id', p['id']);
    await _bump('debts', 'paid', p['debt_id'], -(p['amount'] as num));
  }

  Future<void> contributeDream(Map<String, dynamic> d, num amount) async {
    await db.from('dream_contributions').insert({'dream_id': d['id'], 'amount': amount, 'saved_on': dateStr(DateTime.now())});
    await _bump('dreams', 'saved', d['id'], amount);
  }

  Future<List<Map<String, dynamic>>> dreamContributions(String dreamId) async => List<Map<String, dynamic>>.from(
      await db.from('dream_contributions').select().eq('dream_id', dreamId).order('saved_on', ascending: false).order('created_at', ascending: false));

  Future<void> deleteDreamContribution(Map<String, dynamic> c) async {
    await db.from('dream_contributions').delete().eq('id', c['id']);
    await _bump('dreams', 'saved', c['dream_id'], -(c['amount'] as num));
  }
}
