import 'repo.dart';

/// Date in [year]/[month] for [day], clamped to the month length (31 -> 28/29/30).
DateTime clampedDay(int year, int month, int day) {
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > last ? last : day);
}

/// First occurrence of [day] on or after [from].
DateTime firstDue(int day, DateTime from) {
  final d = DateTime(from.year, from.month, from.day);
  final c = clampedDay(d.year, d.month, day);
  return c.isBefore(d) ? clampedDay(d.year, d.month + 1, day) : c;
}

extension RecurringRepo on Repo {
  Future<List<Map<String, dynamic>>> recurringList() async => List<Map<String, dynamic>>.from(
      await db.from('recurring').select().order('day_of_month').order('created_at'));

  Future<void> addRecurring({
    required String kind,
    required num amount,
    required String category,
    String? note,
    String? walletId,
    required int day,
  }) =>
      db.from('recurring').insert({
        'kind': kind,
        'amount': amount,
        'category': category,
        'note': note,
        'wallet_id': walletId,
        'day_of_month': day,
        'next_due': dateStr(firstDue(day, DateTime.now())),
      });

  Future<void> setRecurringActive(Map<String, dynamic> r, bool active) async {
    final upd = <String, dynamic>{'active': active};
    // When resuming, skip months missed while paused; start from tomorrow to avoid a double booking today.
    if (active) upd['next_due'] = dateStr(firstDue(r['day_of_month'], DateTime.now().add(const Duration(days: 1))));
    await db.from('recurring').update(upd).eq('id', r['id']);
  }

  Future<void> deleteRecurring(String id) => db.from('recurring').delete().eq('id', id);

  /// Books every due recurring transaction up to today. Returns how many were created.
  /// Each run is claimed by advancing next_due first (compare-and-set), so concurrent
  /// launches cannot book the same month twice.
  Future<int> runDueRecurring() async {
    final today = dateStr(DateTime.now());
    final due = List<Map<String, dynamic>>.from(
        await db.from('recurring').select().eq('active', true).lte('next_due', today));
    var created = 0;
    for (final r in due) {
      var cur = r['next_due'] as String;
      for (var i = 0; i < 36 && cur.compareTo(today) <= 0; i++) {
        final d = DateTime.parse(cur);
        final next = dateStr(clampedDay(d.year, d.month + 1, r['day_of_month']));
        final claimed =
            await db.from('recurring').update({'next_due': next}).eq('id', r['id']).eq('next_due', cur).select();
        if ((claimed as List).isEmpty) break;
        await addTransaction(
          kind: r['kind'],
          amount: r['amount'],
          category: r['category'],
          note: [if ((r['note'] as String?)?.isNotEmpty ?? false) r['note'], '(berulang)'].join(' '),
          walletId: r['wallet_id'],
          date: d,
        );
        created++;
        cur = next;
      }
    }
    return created;
  }
}
