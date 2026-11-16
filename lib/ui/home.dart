import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/recurring_repo.dart';
import '../data/reminders.dart';
import '../data/repo.dart';
import 'categories.dart';
import 'dashboard.dart';
import 'dreams.dart';
import 'debts.dart';
import 'recurring.dart';
import 'reports.dart';
import 'transactions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _i = 0;
  int _gen = 0; // bumped to rebuild tabs after background changes

  static const _titles = ['Ringkasan', 'Transaksi', 'Impian', 'Utang'];

  @override
  void initState() {
    super.initState();
    _bookRecurring();
    repo.debts().then(Reminders.sync).catchError((_) {});
  }

  Future<void> _bookRecurring() async {
    try {
      final n = await repo.runDueRecurring();
      if (n > 0 && mounted) {
        setState(() => _gen++);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n transaksi berulang dicatat')));
      }
    } catch (_) {
      // Recurring booking is best effort; the next launch retries.
    }
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => setState(() => _gen++));

  @override
  Widget build(BuildContext context) {
    final pages = const [DashboardPage(), TransactionsPage(), DreamsPage(), DebtsPage()];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_i]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'cat') _open(const CategoriesPage());
              if (v == 'rec') _open(const RecurringPage());
              if (v == 'rep') _open(const ReportsPage());
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rep', child: Text('Laporan')),
              PopupMenuItem(value: 'cat', child: Text('Kategori')),
              PopupMenuItem(value: 'rec', child: Text('Transaksi berulang')),
            ],
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: KeyedSubtree(key: ValueKey('$_i-$_gen'), child: pages[_i]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'Ringkasan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Transaksi'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), label: 'Impian'),
          NavigationDestination(icon: Icon(Icons.handshake_outlined), label: 'Utang'),
        ],
      ),
    );
  }
}
