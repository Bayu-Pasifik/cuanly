import 'package:shared_preferences/shared_preferences.dart';

import 'repo.dart';

/// One product line in the cart. Price and cost are copied at sale time so later price edits do not rewrite history.
class CartLine {
  CartLine({required this.productId, required this.name, required this.price, required this.cost, this.qty = 1});
  final String productId, name;
  final num price, cost;
  int qty;

  num get subtotal => price * qty;
  num get costTotal => cost * qty;

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'price': price, 'cost': cost};
}

class Cart {
  final lines = <CartLine>[];

  bool get isEmpty => lines.isEmpty;
  int get count => lines.fold(0, (a, l) => a + l.qty);
  num get total => lines.fold<num>(0, (a, l) => a + l.subtotal);
  num get costTotal => lines.fold<num>(0, (a, l) => a + l.costTotal);

  void add(Map<String, dynamic> product) {
    final i = lines.indexWhere((l) => l.productId == product['id']);
    if (i >= 0) {
      lines[i].qty++;
    } else {
      lines.add(CartLine(
        productId: product['id'],
        name: product['name'],
        price: product['price'] as num,
        cost: (product['cost'] as num?) ?? 0,
      ));
    }
  }

  /// Changes a line's quantity; a quantity below 1 removes the line.
  void setQty(String productId, int qty) {
    final i = lines.indexWhere((l) => l.productId == productId);
    if (i < 0) return;
    if (qty < 1) {
      lines.removeAt(i);
    } else {
      lines[i].qty = qty;
    }
  }

  void clear() => lines.clear();
}

/// Change owed back for a cash payment; null when [received] does not cover [total].
num? changeFor(num total, num received) => received >= total ? received - total : null;

const paymentMethods = {'cash': 'Tunai', 'qris': 'QRIS', 'transfer': 'Transfer'};

class ProductStat {
  const ProductStat(this.name, this.qty, this.revenue);
  final String name;
  final int qty;
  final num revenue;
}

class BusinessReport {
  const BusinessReport({
    required this.revenue,
    required this.cogs,
    required this.expenses,
    required this.saleCount,
    required this.top,
  });
  final num revenue, cogs, expenses;
  final int saleCount;
  final List<ProductStat> top;

  num get grossProfit => revenue - cogs;
  num get netProfit => grossProfit - expenses;

  /// Net profit as a share of revenue (0..1); null without revenue.
  double? get margin => revenue <= 0 ? null : (netProfit / revenue).toDouble();
}

/// Totals over [sales] (rows with `total`, `cost_total`, `items`) and [expenses] (rows with `amount`).
BusinessReport businessReport(List<Map<String, dynamic>> sales, List<Map<String, dynamic>> expenses) {
  num revenue = 0, cogs = 0;
  final qty = <String, int>{}, rev = <String, num>{};
  for (final s in sales) {
    revenue += s['total'] as num;
    cogs += (s['cost_total'] as num?) ?? 0;
    for (final i in (s['items'] as List? ?? const [])) {
      final m = i as Map;
      final n = m['name'] as String;
      final q = (m['qty'] as num).toInt();
      qty[n] = (qty[n] ?? 0) + q;
      rev[n] = (rev[n] ?? 0) + (m['price'] as num) * q;
    }
  }
  final top = [for (final n in qty.keys) ProductStat(n, qty[n]!, rev[n]!)]
    ..sort((a, b) => b.revenue.compareTo(a.revenue));
  return BusinessReport(
    revenue: revenue,
    cogs: cogs,
    expenses: expenses.fold<num>(0, (a, e) => a + (e['amount'] as num)),
    saleCount: sales.length,
    top: top.take(5).toList(),
  );
}

String _rp(num v) => 'Rp ${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

/// Plain-text receipt, meant for sharing (WhatsApp, etc.).
String receiptText({
  required String businessName,
  String footer = '',
  required List<CartLine> lines,
  required String method,
  required DateTime date,
  num? received,
}) {
  final total = lines.fold<num>(0, (a, l) => a + l.subtotal);
  final b = StringBuffer()
    ..writeln(businessName.isEmpty ? 'Struk' : businessName)
    ..writeln('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}')
    ..writeln('--------------------------------');
  for (final l in lines) {
    b.writeln('${l.name}\n  ${l.qty} x ${_rp(l.price)} = ${_rp(l.subtotal)}');
  }
  b
    ..writeln('--------------------------------')
    ..writeln('TOTAL: ${_rp(total)}')
    ..writeln('Bayar (${paymentMethods[method] ?? method})${received != null ? ': ${_rp(received)}' : ''}');
  final change = received == null ? null : changeFor(total, received);
  if (change != null && method == 'cash') b.writeln('Kembali: ${_rp(change)}');
  if (footer.trim().isNotEmpty) b..writeln('--------------------------------')..writeln(footer.trim());
  return b.toString().trimRight();
}

/// Shop name and receipt footer, kept on the device.
class BusinessSettings {
  const BusinessSettings({this.name = '', this.footer = 'Terima kasih!'});
  final String name, footer;

  static Future<BusinessSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return BusinessSettings(name: p.getString('biz_name') ?? '', footer: p.getString('biz_footer') ?? 'Terima kasih!');
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('biz_name', name.trim());
    await p.setString('biz_footer', footer.trim());
  }
}

extension BusinessRepo on Repo {
  Future<List<Map<String, dynamic>>> products({bool activeOnly = true}) async {
    var q = db.from('business_products').select();
    if (activeOnly) q = q.eq('active', true);
    return List<Map<String, dynamic>>.from(await q.order('name'));
  }

  Future<void> saveProduct(Map<String, dynamic>? existing, String name, num price, num cost) => existing == null
      ? db.from('business_products').insert({'name': name.trim(), 'price': price, 'cost': cost})
      : db.from('business_products').update({'name': name.trim(), 'price': price, 'cost': cost}).eq('id', existing['id']);

  /// Soft delete: past sales keep their item names and prices.
  Future<void> archiveProduct(String id) => db.from('business_products').update({'active': false}).eq('id', id);

  Future<void> recordSale(Cart cart, String method, {String? note}) => db.from('business_sales').insert({
        'total': cart.total,
        'cost_total': cart.costTotal,
        'payment_method': method,
        'items': [for (final l in cart.lines) l.toJson()],
        'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
        'sold_on': dateStr(DateTime.now()),
      });

  Future<List<Map<String, dynamic>>> salesIn(DateTime month) async => List<Map<String, dynamic>>.from(await db
      .from('business_sales')
      .select()
      .gte('sold_on', monthStart(month))
      .lt('sold_on', monthStart(DateTime(month.year, month.month + 1)))
      .order('sold_on', ascending: false)
      .order('created_at', ascending: false));

  Future<void> deleteSale(String id) => db.from('business_sales').delete().eq('id', id);

  Future<List<Map<String, dynamic>>> businessExpensesIn(DateTime month) async =>
      List<Map<String, dynamic>>.from(await db
          .from('business_expenses')
          .select()
          .gte('spent_on', monthStart(month))
          .lt('spent_on', monthStart(DateTime(month.year, month.month + 1)))
          .order('spent_on', ascending: false)
          .order('created_at', ascending: false));

  Future<void> addBusinessExpense(String description, num amount, DateTime date) => db
      .from('business_expenses')
      .insert({'description': description.trim(), 'amount': amount, 'spent_on': dateStr(date)});

  Future<void> deleteBusinessExpense(String id) => db.from('business_expenses').delete().eq('id', id);
}
