import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui/home.dart';
import 'ui/login.dart';
import 'ui/theme.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _key = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  if (_url.isNotEmpty && _key.isNotEmpty) {
    await Supabase.initialize(url: _url, anonKey: _key);
  }
  runApp(const CuanlyApp());
}

class CuanlyApp extends StatelessWidget {
  const CuanlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuanly',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: _url.isEmpty
          ? const _MissingConfig()
          : StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              builder: (_, __) =>
                  Supabase.instance.client.auth.currentSession == null ? const LoginPage() : const HomePage(),
            ),
    );
  }
}

class _MissingConfig extends StatelessWidget {
  const _MissingConfig();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase belum dikonfigurasi.\nJalankan dengan --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
