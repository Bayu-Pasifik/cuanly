import 'repo.dart';

enum Risk { low, medium, high, veryHigh }

String riskLabel(Risk r) => switch (r) {
      Risk.low => 'Rendah',
      Risk.medium => 'Sedang',
      Risk.high => 'Tinggi',
      Risk.veryHigh => 'Sangat tinggi',
    };

typedef InvestmentType = ({String code, String name, Risk risk});

const investmentTypes = <InvestmentType>[
  (code: 'RDPU', name: 'Reksa dana pasar uang', risk: Risk.low),
  (code: 'RDPT', name: 'Reksa dana pendapatan tetap', risk: Risk.low),
  (code: 'Emas', name: 'Emas', risk: Risk.medium),
  (code: 'SBCA', name: 'Saham BCA', risk: Risk.high),
  (code: 'SPY', name: 'ETF S&P 500', risk: Risk.high),
  (code: 'QQQ', name: 'ETF Nasdaq 100', risk: Risk.high),
  (code: 'BTC', name: 'Bitcoin', risk: Risk.veryHigh),
  (code: 'Lainnya', name: 'Lainnya', risk: Risk.medium),
];

InvestmentType investmentType(String code) =>
    investmentTypes.firstWhere((t) => t.code == code, orElse: () => investmentTypes.last);

typedef Allocation = ({String type, int percent});

/// Suggested allocations by risk profile.
const riskProfiles = <String, ({String title, String description, List<Allocation> allocation})>{
  'conservative': (
    title: 'Konservatif',
    description: 'Mengutamakan keamanan modal dengan imbal hasil stabil.',
    allocation: [(type: 'RDPU', percent: 50), (type: 'RDPT', percent: 30), (type: 'Emas', percent: 20)],
  ),
  'moderate': (
    title: 'Moderat',
    description: 'Seimbang antara stabilitas dan pertumbuhan.',
    allocation: [
      (type: 'RDPU', percent: 30),
      (type: 'RDPT', percent: 20),
      (type: 'Emas', percent: 20),
      (type: 'SBCA', percent: 20),
      (type: 'SPY', percent: 10),
    ],
  ),
  'aggressive': (
    title: 'Agresif',
    description: 'Mengejar pertumbuhan tinggi dengan fluktuasi besar.',
    allocation: [
      (type: 'SBCA', percent: 30),
      (type: 'SPY', percent: 25),
      (type: 'QQQ', percent: 20),
      (type: 'Emas', percent: 15),
      (type: 'BTC', percent: 10),
    ],
  ),
};

/// Totals over the *active* investments.
class Portfolio {
  const Portfolio({required this.capital, required this.value, required this.byType});
  final num capital, value;

  /// Current value per investment type code, biggest first.
  final List<({String type, num value})> byType;

  num get gain => value - capital;

  /// Gain as a percentage of capital; null when there is no capital.
  double? get gainPercent => capital <= 0 ? null : (gain / capital * 100).toDouble();
}

Portfolio summarize(List<Map<String, dynamic>> rows) {
  num capital = 0, value = 0;
  final by = <String, num>{};
  for (final r in rows) {
    if (r['status'] == 'sold') continue;
    final cap = r['amount'] as num;
    final val = (r['current_value'] as num?) ?? cap;
    capital += cap;
    value += val;
    by[r['investment_type']] = (by[r['investment_type']] ?? 0) + val;
  }
  final list = [for (final e in by.entries) (type: e.key, value: e.value)]..sort((a, b) => b.value.compareTo(a.value));
  return Portfolio(capital: capital, value: value, byType: list);
}

/// Splits [total] by a profile's percentages (rounded to whole rupiah).
List<({String type, num amount})> recommendedAmounts(String profile, num total) => [
      for (final a in riskProfiles[profile]!.allocation) (type: a.type, amount: (total * a.percent / 100).round())
    ];

extension InvestmentRepo on Repo {
  Future<List<Map<String, dynamic>>> investments() async => List<Map<String, dynamic>>.from(
      await db.from('investments').select().order('status').order('purchase_date', ascending: false).order('created_at'));

  Future<void> addInvestment(String type, num amount, num? currentValue, DateTime date, String? notes) =>
      db.from('investments').insert({
        'investment_type': type,
        'amount': amount,
        'current_value': currentValue ?? amount,
        'purchase_date': dateStr(date),
        'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      });

  Future<void> updateInvestmentValue(String id, num value) =>
      db.from('investments').update({'current_value': value}).eq('id', id);

  Future<void> sellInvestment(String id) => db.from('investments').update({'status': 'sold'}).eq('id', id);

  Future<void> deleteInvestment(String id) => db.from('investments').delete().eq('id', id);
}
