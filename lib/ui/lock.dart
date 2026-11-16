import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/settings.dart';
import 'theme.dart';

/// How long the app may stay in the background before the PIN is asked again.
const lockGrace = Duration(seconds: 30);

/// Covers [child] with a PIN pad while locked. Locks again after [lockGrace] in the background.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final _s = AppSettings.instance;
  late bool _locked = _s.hasPin;
  StreamSubscription<AuthState>? _authSub;
  DateTime? _leftAt;

  bool get _signedIn {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false; // Supabase not configured
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `hidden` fires before `paused`; the system biometric dialog only triggers `inactive`, so ignore that.
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // Short trips (share sheet, file picker) must not demand the PIN again.
      final away = _leftAt == null ? Duration.zero : DateTime.now().difference(_leftAt!);
      _leftAt = null;
      if (_s.hasPin && !_locked && away >= lockGrace) setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Overlay (not a route replacement) so it also covers pushed pages such as Pengaturan.
    final showLock = _locked && _s.hasPin && _signedIn;
    return Stack(fit: StackFit.expand, children: [
      Offstage(offstage: showLock, child: widget.child),
      if (showLock)
        PinPad(
          title: 'Masukkan PIN',
          onSubmit: (pin) async => _s.checkPin(pin),
          onSuccess: () => setState(() => _locked = false),
          allowBiometric: _s.biometric,
        ),
    ]);
  }
}

/// Numeric keypad that collects 4-6 digits. [onSubmit] returns true when the PIN is accepted.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onSubmit,
    required this.onSuccess,
    this.allowBiometric = false,
    this.length = 6,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Future<bool> Function(String pin) onSubmit;
  final VoidCallback onSuccess;
  final bool allowBiometric;
  final int length;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _wrong = false, _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.allowBiometric) WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
  }

  Future<void> _bio() async {
    if (await AppSettings.instance.authenticateBiometric() && mounted) widget.onSuccess();
  }

  Future<void> _tap(String d) async {
    if (_busy || _pin.length >= widget.length) return;
    setState(() {
      _pin += d;
      _wrong = false;
    });
    if (_pin.length == widget.length) {
      _busy = true;
      final ok = await widget.onSubmit(_pin);
      _busy = false;
      if (!mounted) return;
      if (ok) {
        widget.onSuccess();
      } else {
        setState(() {
          _pin = '';
          _wrong = true;
        });
      }
    }
  }

  void _back() {
    if (_pin.isNotEmpty && !_busy) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final fg = C.fg(context);
    Widget key(String label, {VoidCallback? onTap, Widget? child}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: onTap == null
                  ? const SizedBox()
                  : Material(
                      color: Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18), side: BorderSide(color: fg, width: 2)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: onTap,
                        child: Center(
                            child: child ??
                                Text(label, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: fg))),
                      ),
                    ),
            ),
          ),
        );

    Widget row(List<String> ds) => Row(children: [for (final d in ds) key(d, onTap: () => _tap(d))]);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_rounded, size: 48, color: fg),
                const SizedBox(height: 12),
                Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.subtitle!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < widget.length; i++)
                    Container(
                      key: ValueKey('pin-dot-$i'),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length ? fg : Colors.transparent,
                        border: Border.all(color: _wrong ? C.coral : fg, width: 2),
                      ),
                    ),
                ]),
                SizedBox(
                  height: 28,
                  child: _wrong
                      ? const Center(child: Text('PIN salah', style: TextStyle(color: C.coral, fontWeight: FontWeight.w700)))
                      : null,
                ),
                row(['1', '2', '3']),
                row(['4', '5', '6']),
                row(['7', '8', '9']),
                Row(children: [
                  key('', onTap: widget.allowBiometric ? _bio : null, child: Icon(Icons.fingerprint, size: 30, color: fg)),
                  key('0', onTap: () => _tap('0')),
                  key('', onTap: _back, child: Icon(Icons.backspace_outlined, color: fg)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
