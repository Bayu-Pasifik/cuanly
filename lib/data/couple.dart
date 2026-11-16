import 'repo.dart';

enum CoupleState { none, pending, active }

/// One person's monthly totals as returned by `couple_summary`.
class CoupleMember {
  const CoupleMember({required this.expense, required this.income, this.topCategory});
  final num expense, income;
  final String? topCategory;
}

class CoupleSummary {
  const CoupleSummary({required this.me, required this.partner});
  final CoupleMember me, partner;

  num get combinedExpense => me.expense + partner.expense;
  num get combinedIncome => me.income + partner.income;

  /// Share of the combined spending that is mine, 0..1 (0 when nobody spent anything).
  double get myShare => combinedExpense <= 0 ? 0 : (me.expense / combinedExpense).toDouble();
}

/// Parses the rows of `couple_summary`. Null unless both people are present (no active partnership).
CoupleSummary? parseCoupleSummary(List<Map<String, dynamic>> rows) {
  CoupleMember? me, partner;
  for (final r in rows) {
    final m = CoupleMember(
      expense: (r['expense'] as num?) ?? 0,
      income: (r['income'] as num?) ?? 0,
      topCategory: r['top_category'] as String?,
    );
    if (r['who'] == 'me') me = m;
    if (r['who'] == 'partner') partner = m;
  }
  return me == null || partner == null ? null : CoupleSummary(me: me, partner: partner);
}

CoupleState coupleState(Map<String, dynamic>? row) => row == null
    ? CoupleState.none
    : row['status'] == 'active'
        ? CoupleState.active
        : CoupleState.pending;

/// Whether the signed-in user created the invite (as opposed to accepting it).
bool isInviter(Map<String, dynamic> row, String? uid) => row['inviter_id'] == uid;

/// Normalises what a person typed as an invite code (spaces and case do not matter).
String normalizeInviteCode(String s) => s.replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// Friendly text for a Postgres error raised by the couple functions.
String coupleError(Object e) {
  final s = e.toString();
  for (final known in ['Kode undangan tidak valid atau sudah dipakai', 'Kamu sudah punya pasangan atau undangan aktif']) {
    if (s.contains(known)) return known;
  }
  return 'Gagal: $s';
}

extension CoupleRepo on Repo {
  /// The caller's partnership row (pending or active), if any.
  Future<Map<String, dynamic>?> myCouple() async => await db.from('couples').select().maybeSingle();

  Future<Map<String, dynamic>> createInvite() async => await db.from('couples').insert({}).select().single();

  Future<void> acceptInvite(String code) async {
    await db.rpc('accept_couple_invite', params: {'p_code': normalizeInviteCode(code)});
  }

  /// Ends a partnership or cancels a pending invite.
  Future<void> endCouple(String id) => db.from('couples').delete().eq('id', id);

  Future<CoupleSummary?> coupleSummary(DateTime month) async {
    final rows = await db.rpc('couple_summary', params: {'p_month': monthStart(month)});
    return parseCoupleSummary(List<Map<String, dynamic>>.from(rows as List));
  }
}
