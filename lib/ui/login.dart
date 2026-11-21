import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account.dart';
import 'theme.dart';

/// Where email links (confirm account, reset password) send the user back to the app.
const authRedirect = 'com.cuanly.app://login-callback/';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _signup = false, _busy = false;
  String? _error;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _error = 'Format email belum benar');
      return;
    }
    if (_signup) {
      final p = passwordProblem(_pass.text);
      if (p != null) {
        setState(() => _error = p);
        return;
      }
    } else if (_pass.text.isEmpty) {
      setState(() => _error = 'Password wajib diisi');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signup) {
        final r = await _auth.signUp(email: email, password: _pass.text, emailRedirectTo: authRedirect);
        if (r.session == null && mounted) await _checkEmail(email);
      } else {
        await _auth.signInWithPassword(email: email, password: _pass.text);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shown after sign-up when the project requires email confirmation.
  Future<void> _checkEmail(String email) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cek email kamu'),
          content: Text('Kami mengirim tautan konfirmasi ke $email. Buka tautannya di HP ini untuk masuk.'),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _auth.resend(type: OtpType.signup, email: email, emailRedirectTo: authRedirect);
                  if (mounted) _snack('Email konfirmasi dikirim ulang');
                } on AuthException catch (e) {
                  if (mounted) _snack(e.message);
                }
              },
              child: const Text('Kirim ulang'),
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );

  Future<void> _forgot() async {
    final c = TextEditingController(text: _email.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa password?'),
        content: Column(mainAxisSize: MainAxisSize.min, spacing: 12, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Masukkan email akunmu. Kami kirim tautan untuk membuat password baru.'),
          TextField(controller: c, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim tautan')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final email = c.text.trim();
    if (!isValidEmail(email)) {
      _snack('Format email belum benar');
      return;
    }
    try {
      await _auth.resetPasswordForEmail(email, redirectTo: authRedirect);
      if (mounted) _snack('Jika email terdaftar, tautan reset sudah dikirim.');
    } on AuthException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fix = suggestEmailFix(_email.text);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 20),
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
              Text('Cuanly', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
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
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              if (fix != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _email.text = fix),
                    child: Text('Maksudmu $fix?'),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: C.coral, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _busy ? null : _submit, child: Text(_signup ? 'Daftar' : 'Masuk')),
              ),
              if (!_signup) TextButton(onPressed: _forgot, child: const Text('Lupa password?')),
              TextButton(
                onPressed: () => setState(() {
                  _signup = !_signup;
                  _error = null;
                }),
                child: Text(_signup ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
