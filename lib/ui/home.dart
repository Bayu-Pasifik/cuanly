import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard.dart';
import 'dreams.dart';
import 'debts.dart';
import 'transactions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _i = 0;

  static const _titles = ['Ringkasan', 'Transaksi', 'Impian', 'Utang'];

  @override
  Widget build(BuildContext context) {
    final pages = const [DashboardPage(), TransactionsPage(), DreamsPage(), DebtsPage()];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_i]),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _i, children: pages),
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
