import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account.dart';
import '../data/repo.dart';
import 'home.dart';
import 'login.dart';
import 'theme.dart';

/// Chooses between login, the app, and the "new password" screen opened from a reset-password email link.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _sub;
  bool _recovery = false;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((s) {
      if (!mounted) return;
      setState(() {
        if (s.event == AuthChangeEvent.passwordRecovery) _recovery = true;
        if (s.event == AuthChangeEvent.signedOut) _recovery = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) return const LoginPage();
    if (_recovery) return ResetPasswordPage(onDone: () => setState(() => _recovery = false));
    return const HomePage();
  }
}

/// Why the two typed passwords cannot be used, or null when they are fine.
String? newPasswordProblem(String password, String confirm) =>
    passwordProblem(password) ?? (password != confirm ? 'Konfirmasi password tidak sama' : null);

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final p = newPasswordProblem(_pass.text, _confirm.text);
    if (p != null) {
      setState(() => _error = p);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.changePassword(_pass.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password diperbarui')));
      widget.onDone();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Password baru'), automaticallyImplyLeading: false),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('Buat password baru untuk akunmu.'),
          const SizedBox(height: 16),
          TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password baru', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ulangi password', border: OutlineInputBorder())),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: C.coral, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan password')),
        ]),
      );
}
