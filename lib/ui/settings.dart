import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account.dart';
import '../data/backup.dart';
import '../data/repo.dart';
import '../data/legal.dart';
import '../data/settings.dart';
import 'auth_gate.dart';
import 'legal.dart';
import 'lock.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _s = AppSettings.instance;
  bool _bioAvailable = false, _busy = false;

  @override
  void initState() {
    super.initState();
    _s.biometricAvailable().then((v) {
      if (mounted) setState(() => _bioAvailable = v);
    });
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// Pushes a full-screen PIN prompt and resolves true when [onSubmit] accepted a PIN.
  Future<bool> _prompt(String title, Future<bool> Function(String) onSubmit, {String? subtitle}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => PopScope(
          canPop: true,
          child: Stack(children: [
            PinPad(title: title, subtitle: subtitle, onSubmit: onSubmit, onSuccess: () => Navigator.pop(ctx, true)),
            SafeArea(child: Align(alignment: Alignment.topLeft, child: BackButton(onPressed: () => Navigator.pop(ctx, false)))),
          ]),
        ),
      ),
    );
    return ok == true;
  }

  Future<bool> _verifyCurrent() => _prompt('Masukkan PIN saat ini', (p) async => _s.checkPin(p));

  Future<bool> _createPin() async {
    String? first;
    final ok = await _prompt('Buat PIN', (p) async {
      first = p;
      return true;
    }, subtitle: 'PIN 6 digit untuk membuka Cuanly');
    if (!ok || first == null) return false;
    final entered = first!;
    final again = await _prompt('Ulangi PIN', (p) async => p == entered);
    if (!again) return false;
    await _s.setPin(entered);
    return true;
  }

  Future<void> _togglePin(bool on) async {
    if (on) {
      if (await _createPin() && mounted) _snack('PIN aktif');
    } else {
      if (await _verifyCurrent()) {
        await _s.clearPin();
        if (mounted) _snack('PIN dimatikan');
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _changePin() async {
    if (!await _verifyCurrent() || !mounted) return;
    if (await _createPin() && mounted) _snack('PIN diganti');
  }

  Future<void> _toggleBio(bool on) async {
    if (on && !await _s.authenticateBiometric()) return;
    await _s.setBiometric(on);
    if (mounted) setState(() {});
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      final json = await backupRepo.export();
      final dir = await getTemporaryDirectory();
      final stamp = dateStr(DateTime.now());
      final file = File('${dir.path}/cuanly-backup-$stamp.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Backup Cuanly $stamp',
      ));
    } catch (e) {
      if (mounted) _snack('Gagal backup: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
      if (picked == null) return;
      final tables = decodeBackup(utf8.decode(await picked.readAsBytes()));
      final count = tables.values.fold<int>(0, (a, r) => a + r.length);
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pulihkan data?'),
          content: Text('$count baris dari backup akan digabungkan ke akun ini. '
              'Data yang sudah ada dengan ID sama akan ditimpa; data lain tidak dihapus.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pulihkan')),
          ],
        ),
      );
      if (ok != true) return;
      final n = await backupRepo.restore(tables);
      if (mounted) _snack('$n baris dipulihkan');
    } on FormatException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Gagal memulihkan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? get _email {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  Future<void> _changePassword() async {
    final pass = TextEditingController(), confirm = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Ubah password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru')),
            TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Ulangi password')),
            if (error != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: TextStyle(color: Colors.red.shade700))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                final p = newPasswordProblem(pass.text, confirm.text);
                if (p != null) {
                  set(() => error = p);
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await repo.changePassword(pass.text);
      if (mounted) _snack('Password diperbarui');
    } on AuthException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _deleteAccount() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Hapus akun?'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Semua dompet, transaksi, impian, utang, dan data lain akan dihapus permanen dan tidak bisa dipulihkan. '
                'Buat backup dulu bila perlu.'),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              onChanged: (_) => set(() {}),
              decoration: InputDecoration(labelText: 'Ketik $deleteWord untuk melanjutkan'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              onPressed: deleteConfirmed(c.text) ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Hapus akun'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await repo.deleteMyAccount();
      await _s.clearPin();
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('Gagal menghapus akun: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)));

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        section('Tampilan'),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: _s.themeMode,
          builder: (_, mode, _) => SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistem'), icon: Icon(Icons.brightness_auto)),
              ButtonSegment(value: ThemeMode.light, label: Text('Terang'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Gelap'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {mode},
            onSelectionChanged: (v) => _s.setThemeMode(v.first),
          ),
        ),
        section('Keamanan'),
        Card(
          child: Column(children: [
            SwitchListTile(
              title: const Text('Kunci PIN'),
              subtitle: const Text('Minta PIN saat membuka aplikasi'),
              value: _s.hasPin,
              onChanged: _togglePin,
            ),
            if (_s.hasPin) ...[
              ListTile(
                title: const Text('Ganti PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePin,
              ),
              SwitchListTile(
                title: const Text('Buka dengan sidik jari / wajah'),
                subtitle: Text(_bioAvailable ? 'Alternatif selain PIN' : 'Tidak tersedia di perangkat ini'),
                value: _s.biometric,
                onChanged: _bioAvailable ? _toggleBio : null,
              ),
            ],
          ]),
        ),
        section('Akun'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Email'),
              subtitle: Text(_email ?? '-'),
            ),
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('Ubah password'),
              onTap: _busy ? null : _changePassword,
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
              title: Text('Hapus akun', style: TextStyle(color: Colors.red.shade700)),
              subtitle: const Text('Hapus akun dan semua datanya secara permanen'),
              onTap: _busy ? null : _deleteAccount,
            ),
          ]),
        ),
        section('Tentang'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Kebijakan privasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Kebijakan privasi', sections: privacyPolicy))),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Syarat layanan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Syarat layanan', sections: termsOfService))),
            ),
          ]),
        ),
        section('Data'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Backup data'),
              subtitle: const Text('Simpan semua data ke berkas JSON'),
              onTap: _busy ? null : _backup,
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Pulihkan dari backup'),
              subtitle: const Text('Gabungkan berkas backup ke akun ini'),
              onTap: _busy ? null : _restore,
            ),
          ]),
        ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
      ]),
    );
  }
}
