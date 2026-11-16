import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/settings.dart';
import 'ui/auth_gate.dart';
import 'ui/lock.dart';
import 'ui/theme.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _key = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await AppSettings.instance.load();
  if (_url.isNotEmpty && _key.isNotEmpty) {
    await Supabase.initialize(url: _url, publishableKey: _key);
  }
  runApp(const CuanlyApp());
}

class CuanlyApp extends StatelessWidget {
  const CuanlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.instance.themeMode,
      builder: (_, mode, _) => MaterialApp(
      title: 'Cuanly',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      builder: (_, child) => LockGate(child: child!),
      home: _url.isEmpty
          ? const _MissingConfig()
          : const AuthGate(),
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
