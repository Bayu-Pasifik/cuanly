import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _signup = false, _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_signup) {
        final r = await auth.signUp(
          email: _email.text.trim(),
          password: _pass.text,
          emailRedirectTo: 'com.cuanly.app://login-callback/',
        );
        if (r.session == null && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Cek email untuk konfirmasi akun.')));
        }
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _pass.text);
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: C.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: C.fg(context), width: 3),
                    boxShadow: [BoxShadow(color: C.fg(context), offset: const Offset(4, 4))],
                  ),
                  child: const Icon(Icons.savings_rounded, size: 52, color: C.ink),
                ),
                const SizedBox(height: 20),
                Text('Cuanly',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Atur uangmu, capai impianmu.', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  for (final c in [C.mint, C.pink, C.lilac, C.sky])
                    Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: C.ink, width: 1.5))),
                ]),
                const SizedBox(height: 28),
                TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _busy ? null : _submit, child: Text(_signup ? 'Daftar' : 'Masuk'))),
                TextButton(
                    onPressed: () => setState(() => _signup = !_signup),
                    child: Text(_signup ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar')),
              ]),
            ),
          ),
        ),
      );
}
