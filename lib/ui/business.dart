import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/business.dart';
import '../data/repo.dart';
import '../data/tracker.dart';
import 'common.dart';
import 'theme.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  int _gen = 0; // bumped after a sale so the report tab reloads

  Future<void> _settings() async {
    final s = await BusinessSettings.load();
    if (!mounted) return;
    final name = TextEditingController(text: s.name);
    final footer = TextEditingController(text: s.footer);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan struk'),
        content: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama usaha')),
          TextField(controller: footer, decoration: const InputDecoration(labelText: 'Catatan bawah struk')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) await BusinessSettings(name: name.text, footer: footer.text).save();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Mode usaha'),
            actions: [IconButton(tooltip: 'Pengaturan struk', icon: const Icon(Icons.receipt_long_outlined), onPressed: _settings)],
            bottom: const TabBar(tabs: [Tab(text: 'Kasir'), Tab(text: 'Produk'), Tab(text: 'Laporan')]),
          ),
          body: TabBarView(children: [
            PosTab(onSold: () => setState(() => _gen++)),
            const ProductsTab(),
            ReportTab(key: ValueKey(_gen)),
          ]),
        ),
      );
}

// ---------------------------------------------------------------- Kasir

class PosTab extends StatefulWidget {
  const PosTab({super.key, required this.onSold});
  final VoidCallback onSold;

  @override
  State<PosTab> createState() => _PosTabState();
}

class _PosTabState extends State<PosTab> {
  late final Future<List<Map<String, dynamic>>> _products = repo.products();
  final _cart = Cart();
  final _received = TextEditingController();
  String _method = 'cash';
  bool _busy = false;

  Future<void> _pay() async {
    if (_cart.isEmpty) return;
    final received = parseAmount(_received.text);
    if (_method == 'cash' && received != null && changeFor(_cart.total, received) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang yang diterima kurang dari total.')));
      return;
    }
    setState(() => _busy = true);
    final s = await BusinessSettings.load();
    final lines = [for (final l in _cart.lines) CartLine(productId: l.productId, name: l.name, price: l.price, cost: l.cost, qty: l.qty)];
    try {
      await repo.recordSale(_cart, _method);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan penjualan: $e')));
      }
      return;
    }
    final text = receiptText(
      businessName: s.name,
      footer: s.footer,
      lines: lines,
      method: _method,
      date: DateTime.now(),
      received: _method == 'cash' ? received : null,
    );
    setState(() {
      _cart.clear();
      _received.clear();
      _busy = false;
    });
    widget.onSold();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Penjualan tersimpan'),
        content: SingleChildScrollView(child: Text(text, style: const TextStyle(fontFamily: 'monospace'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          FilledButton.icon(
            onPressed: () => SharePlus.instance.share(ShareParams(text: text)),
            icon: const Icon(Icons.share),
            label: const Text('Bagikan struk'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final received = parseAmount(_received.text);
    final change = (_method == 'cash' && received != null) ? changeFor(_cart.total, received) : null;
    return Async<List<Map<String, dynamic>>>(
      future: _products,
      builder: (_, products) => ListView(padding: const EdgeInsets.all(16), children: [
        if (products.isEmpty)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Belum ada produk. Tambahkan di tab Produk dulu.', textAlign: TextAlign.center))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in products)
              ActionChip(
                label: Text('${p['name']}  ${rp(p['price'] as num)}'),
                onPressed: () => setState(() => _cart.add(p)),
              ),
          ]),
        const SizedBox(height: 12),
        const Text('Keranjang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        if (_cart.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Ketuk produk untuk menambah.')),
        for (final l in _cart.lines)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(l.name),
            subtitle: Text('${rp(l.price)} x ${l.qty} = ${rp(l.subtotal)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  tooltip: 'Kurangi',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() => _cart.setQty(l.productId, l.qty - 1))),
              Text('${l.qty}', style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                  tooltip: 'Tambah',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _cart.setQty(l.productId, l.qty + 1))),
            ]),
          ),
        if (!_cart.isEmpty) ...[
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(rp(_cart.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          ]),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [for (final e in paymentMethods.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          if (_method == 'cash') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _received,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Uang diterima (opsional)', prefixText: 'Rp '),
            ),
            if (change != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Kembalian ${rp(change)}', style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _pay, child: Text('Bayar ${rp(_cart.total)}')),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- Produk

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  late Future<List<Map<String, dynamic>>> _f = repo.products();

  void _reload() => setState(() {
        _f = repo.products();
      });

  Future<void> _edit([Map<String, dynamic>? p]) async {
    final name = TextEditingController(text: p?['name']);
    final price = TextEditingController(text: p == null ? '' : (p['price'] as num).round().toString());
    final cost = TextEditingController(text: p == null ? '' : (p['cost'] as num).round().toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p == null ? 'Produk baru' : 'Ubah produk'),
        content: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
          TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga jual', prefixText: 'Rp ')),
          TextField(
              controller: cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga modal (opsional)', prefixText: 'Rp ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    final pr = parseAmount(price.text);
    if (ok != true || name.text.trim().isEmpty || pr == null || pr < 0 || !mounted) return;
    await guarded(context, () => repo.saveProduct(p, name.text, pr, parseAmount(cost.text) ?? 0), _reload);
  }

  @override
  Widget build(BuildContext context) => Async<List<Map<String, dynamic>>>(
        future: _f,
        builder: (_, rows) => ListView(padding: const EdgeInsets.all(16), children: [
          FilledButton.icon(onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Tambah produk')),
          if (rows.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada produk.', textAlign: TextAlign.center)),
          for (final p in rows)
            Card(
              child: ListTile(
                onTap: () => _edit(p),
                title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('Modal ${rp(p['cost'] as num)}  -  Untung ${rp((p['price'] as num) - (p['cost'] as num))}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(rp(p['price'] as num), style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(
                    tooltip: 'Arsipkan',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () async {
                      if (!await confirmDelete(context, 'Arsipkan "${p['name']}"?', message: 'Riwayat penjualan tetap tersimpan.', confirmLabel: 'Arsipkan')) return;
                      if (!context.mounted) return;
                      await guarded(context, () => repo.archiveProduct(p['id']), _reload);
                    },
                  ),
                ]),
              ),
            ),
        ]),
      );
}

// ---------------------------------------------------------------- Laporan

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<List<Map<String, dynamic>>>> _f = _load();

  Future<List<List<Map<String, dynamic>>>> _load() => Future.wait([repo.salesIn(_month), repo.businessExpensesIn(_month)]);

  void _reload() => setState(() {
        _f = _load();
      });

  void _go(int d) {
    _month = DateTime(_month.year, _month.month + d);
    _reload();
  }

  Future<void> _addExpense() async {
    final desc = TextEditingController();
    final amt = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Biaya usaha'),
        content: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
          TextField(controller: desc, decoration: const InputDecoration(labelText: 'Keterangan (sewa, listrik, ...)')),
          TextField(
              controller: amt,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    final v = parseAmount(amt.text);
    if (ok != true || desc.text.trim().isEmpty || v == null || v <= 0 || !mounted) return;
    await guarded(context, () => repo.addBusinessExpense(desc.text, v, DateTime.now()), _reload);
  }

  @override
  Widget build(BuildContext context) => Async<List<List<Map<String, dynamic>>>>(
        future: _f,
        builder: (_, data) {
          final sales = data[0], expenses = data[1];
          final r = businessReport(sales, expenses);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(tooltip: 'Bulan sebelumnya', onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left)),
              Text(monthLabel(_month), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(tooltip: 'Bulan berikutnya', onPressed: () => _go(1), icon: const Icon(Icons.chevron_right)),
            ]),
            BusinessReportCard(report: r),
            if (r.top.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Produk terlaris', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              for (final p in r.top)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: Text('${p.qty} terjual'),
                  trailing: Text(rp(p.revenue), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('Biaya usaha', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              TextButton.icon(onPressed: _addExpense, icon: const Icon(Icons.add), label: const Text('Tambah')),
            ]),
            if (expenses.isEmpty) const Text('Belum ada biaya bulan ini.'),
            for (final e in expenses)
              Dismissible(
                key: ValueKey(e['id']),
                background: Container(color: Colors.red.shade100),
                confirmDismiss: (_) => confirmDelete(context, 'Hapus biaya "${e['description']}"?'),
                onDismissed: (_) => guarded(context, () => repo.deleteBusinessExpense(e['id']), _reload),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e['description']),
                  subtitle: Text(e['spent_on']),
                  trailing: Text(rp(e['amount'] as num)),
                ),
              ),
            const SizedBox(height: 12),
            Text('Penjualan (${sales.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            if (sales.isEmpty) const Text('Belum ada penjualan bulan ini.'),
            for (final s in sales)
              Dismissible(
                key: ValueKey(s['id']),
                background: Container(color: Colors.red.shade100),
                confirmDismiss: (_) => confirmDelete(context, 'Hapus penjualan ini?', message: 'Laporan laba ikut berubah.'),
                onDismissed: (_) => guarded(context, () => repo.deleteSale(s['id']), _reload),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(rp(s['total'] as num), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${s['sold_on']}  -  ${paymentMethods[s['payment_method']] ?? s['payment_method']}  -  '
                      '${((s['items'] as List?) ?? const []).length} item'),
                ),
              ),
          ]);
        },
      );
}

class BusinessReportCard extends StatelessWidget {
  const BusinessReportCard({super.key, required this.report});
  final BusinessReport report;

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, fontSize: bold ? 18 : null)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final r = report;
    final loss = r.netProfit < 0;
    return PastelCard(
      color: loss ? C.coral : C.mint,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _row('Omzet (${r.saleCount} penjualan)', rp(r.revenue)),
          _row('Modal barang terjual', '-${rp(r.cogs)}'),
          _row('Laba kotor', rp(r.grossProfit)),
          _row('Biaya usaha', '-${rp(r.expenses)}'),
          const Divider(),
          _row(loss ? 'Rugi bersih' : 'Laba bersih', loss ? '-${rp(-r.netProfit)}' : rp(r.netProfit), bold: true),
          if (r.margin != null) _row('Margin', '${(r.margin! * 100).toStringAsFixed(1)}%'),
        ]),
      ),
    );
  }
}
