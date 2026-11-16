import 'repo.dart';

/// One transfer that settles part of a trip: [from] pays [to] [amount].
typedef Settlement = ({String from, String to, num amount});

class TripSplit {
  const TripSplit({required this.total, required this.perPerson, required this.balances, required this.settlements});
  final num total, perPerson;

  /// Positive: the person paid more than their share and is owed money. Negative: they owe.
  final Map<String, num> balances;
  final List<Settlement> settlements;
}

/// Splits [expenses] (maps with `amount` and `paidBy`) equally between [people].
/// Expenses paid by someone who is not in [people] still count toward the total.
TripSplit splitTrip(List<String> people, List<Map<String, dynamic>> expenses) {
  num total = 0;
  final paid = {for (final p in people) p: 0 as num};
  for (final e in expenses) {
    final amt = (e['amount'] as num?) ?? 0;
    if (amt <= 0) continue;
    total += amt;
    final who = e['paidBy'];
    if (paid.containsKey(who)) paid[who] = paid[who]! + amt;
  }
  final each = people.isEmpty ? 0 : total / people.length;
  final balances = {for (final p in people) p: paid[p]! - each};

  // Greedy settlement: the biggest debtor pays the biggest creditor until everyone is square.
  final debtors = [for (final e in balances.entries) if (e.value < -0.5) (name: e.key, left: -e.value)]
    ..sort((a, b) => b.left.compareTo(a.left));
  final creditors = [for (final e in balances.entries) if (e.value > 0.5) (name: e.key, left: e.value)]
    ..sort((a, b) => b.left.compareTo(a.left));
  final d = [for (final x in debtors) [x.name, x.left]];
  final c = [for (final x in creditors) [x.name, x.left]];
  final out = <Settlement>[];
  var i = 0, j = 0;
  while (i < d.length && j < c.length) {
    final pay = (d[i][1] as num) < (c[j][1] as num) ? d[i][1] as num : c[j][1] as num;
    out.add((from: d[i][0] as String, to: c[j][0] as String, amount: pay.round()));
    d[i][1] = (d[i][1] as num) - pay;
    c[j][1] = (c[j][1] as num) - pay;
    if ((d[i][1] as num) < 0.5) i++;
    if ((c[j][1] as num) < 0.5) j++;
  }
  return TripSplit(total: total, perPerson: each, balances: balances, settlements: out);
}

/// Why a trip cannot be saved, or null when it is valid.
String? validateTrip(String name, List<String> people, List<Map<String, dynamic>> expenses) {
  if (name.trim().isEmpty) return 'Nama perjalanan wajib diisi';
  final names = [for (final p in people) p.trim()];
  if (names.any((n) => n.isEmpty)) return 'Nama peserta tidak boleh kosong';
  if (names.length < 2) return 'Minimal 2 peserta';
  if (names.toSet().length != names.length) return 'Nama peserta harus berbeda';
  if (expenses.isEmpty) return 'Tambahkan minimal satu pengeluaran';
  for (final e in expenses) {
    if (((e['amount'] as num?) ?? 0) <= 0) return 'Jumlah pengeluaran harus lebih dari 0';
    if (!names.contains(e['paidBy'])) return 'Pilih siapa yang membayar tiap pengeluaran';
  }
  return null;
}

extension TravelRepo on Repo {
  Future<List<Map<String, dynamic>>> trips() async =>
      List<Map<String, dynamic>>.from(await db.from('travel_splits').select().order('created_at', ascending: false));

  Future<void> addTrip(String name, List<String> people, List<Map<String, dynamic>> expenses) {
    final total = splitTrip(people, expenses).total;
    return db.from('travel_splits').insert({
      'trip_name': name.trim(),
      'total_amount': total,
      'participants': [for (final p in people) {'name': p}],
      'expenses': expenses,
    });
  }

  Future<void> deleteTrip(String id) => db.from('travel_splits').delete().eq('id', id);
}

/// Participant names of a stored trip row.
List<String> tripPeople(Map<String, dynamic> trip) =>
    [for (final p in (trip['participants'] as List? ?? const [])) (p as Map)['name'] as String];

List<Map<String, dynamic>> tripExpenses(Map<String, dynamic> trip) =>
    [for (final e in (trip['expenses'] as List? ?? const [])) Map<String, dynamic>.from(e as Map)];
