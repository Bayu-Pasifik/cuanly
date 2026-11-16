import 'repo.dart';

enum ChallengeState { upcoming, active, ended }

/// Splits the comma-separated category column into names.
List<String> splitCategories(String s) =>
    [for (final c in s.split(',')) if (c.trim().isNotEmpty) c.trim()];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _parse(String s) => _day(DateTime.parse(s));

/// Spending against a challenge's cap.
class ChallengeProgress {
  const ChallengeProgress({required this.spent, required this.limit, required this.state, required this.daysLeft});
  final num spent, limit;
  final ChallengeState state;

  /// Days left including today while active; days until start when upcoming; 0 once ended.
  final int daysLeft;

  num get remaining => limit - spent;
  bool get over => spent > limit;
  double get ratio => limit <= 0 ? 0 : (spent / limit).toDouble();
}

/// Progress of [challenge] given [expenses] (transaction rows; only matching expense rows in range count).
ChallengeProgress challengeProgress(Map<String, dynamic> challenge, List<Map<String, dynamic>> expenses, DateTime now) {
  final start = _parse(challenge['start_date']);
  final end = _parse(challenge['end_date']);
  final cats = splitCategories(challenge['category']).toSet();
  num spent = 0;
  for (final t in expenses) {
    if (t['kind'] != 'expense' || !cats.contains(t['category'])) continue;
    final d = _parse(t['occurred_on']);
    if (d.isBefore(start) || d.isAfter(end)) continue;
    spent += t['amount'] as num;
  }
  final today = _day(now);
  final state = today.isBefore(start)
      ? ChallengeState.upcoming
      : today.isAfter(end)
          ? ChallengeState.ended
          : ChallengeState.active;
  final daysLeft = switch (state) {
    ChallengeState.upcoming => start.difference(today).inDays,
    ChallengeState.active => end.difference(today).inDays + 1,
    ChallengeState.ended => 0,
  };
  return ChallengeProgress(spent: spent, limit: challenge['budget_limit'] as num, state: state, daysLeft: daysLeft);
}

/// New (start, end) for an auto-renewing challenge whose period has passed: the same length, shifted
/// forward until it covers [now]. Null when [challenge] does not need renewing.
({DateTime start, DateTime end})? renewedPeriod(Map<String, dynamic> challenge, DateTime now) {
  if (challenge['auto_renew'] != true) return null;
  final start = _parse(challenge['start_date']);
  final end = _parse(challenge['end_date']);
  final today = _day(now);
  if (!today.isAfter(end)) return null;
  final span = end.difference(start).inDays + 1;
  final k = today.difference(start).inDays ~/ span;
  final s = DateTime(start.year, start.month, start.day + k * span);
  return (start: s, end: DateTime(s.year, s.month, s.day + span - 1));
}

extension ChallengeRepo on Repo {
  /// Challenges, newest first. Auto-renewing ones whose period passed are moved forward first.
  Future<List<Map<String, dynamic>>> challenges({DateTime? now}) async {
    final rows = List<Map<String, dynamic>>.from(
        await db.from('spending_challenges').select().order('start_date', ascending: false).order('created_at'));
    final clock = now ?? DateTime.now();
    for (final r in rows) {
      final p = renewedPeriod(r, clock);
      if (p == null) continue;
      r['start_date'] = dateStr(p.start);
      r['end_date'] = dateStr(p.end);
      await db.from('spending_challenges').update({'start_date': r['start_date'], 'end_date': r['end_date']}).eq('id', r['id']);
    }
    return rows;
  }

  /// Expense rows that can count toward any of [challenges].
  Future<List<Map<String, dynamic>>> challengeExpenses(List<Map<String, dynamic>> challenges) async {
    if (challenges.isEmpty) return [];
    final from = challenges.map((c) => c['start_date'] as String).reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    final to = challenges.map((c) => c['end_date'] as String).reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    return List<Map<String, dynamic>>.from(await db
        .from('transactions')
        .select('kind, category, amount, occurred_on')
        .eq('kind', 'expense')
        .gte('occurred_on', from)
        .lte('occurred_on', to));
  }

  Future<void> saveChallenge(Map<String, dynamic>? existing, Map<String, dynamic> values) => existing == null
      ? db.from('spending_challenges').insert(values)
      : db.from('spending_challenges').update(values).eq('id', existing['id']);

  Future<void> deleteChallenge(String id) => db.from('spending_challenges').delete().eq('id', id);
}
