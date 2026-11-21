import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
String rp(num v) => _rp.format(v);

num? parseAmount(String s) => num.tryParse(s.replaceAll('.', '').replaceAll(',', '').trim());

/// Asks for a single amount. Returns null when cancelled or invalid.
Future<num?> askAmount(BuildContext context, String title) async {
  final c = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'Rp ')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
      ],
    ),
  );
  if (ok != true) return null;
  final v = parseAmount(c.text);
  return (v == null || v <= 0) ? null : v;
}

/// Runs [action], shows an error snackbar on failure, then calls [after].
Future<void> guarded(BuildContext context, Future<void> Function() action, VoidCallback after) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
  after();
}

class Async<T> extends StatelessWidget {
  const Async({super.key, required this.future, required this.builder});
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (c, s) {
          if (s.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: ${s.error}')));
          // `done` rather than `hasData`: a future that completes with null (e.g. "no partner yet") is still a result.
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          return builder(c, s.data as T);
        },
      );
}

/// Shows a delete confirmation dialog. Returns true only when confirmed.
Future<bool> confirmDelete(BuildContext context, String title, {String? message, String confirmLabel = 'Hapus'}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
        ],
      ),
    ) ??
    false;

/// Bold heading for a block of content; keeps section spacing uniform across screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 0, 4),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          ?action,
        ]),
      );
}

/// Friendly placeholder for a screen or list with nothing in it yet.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: C.fg(context).withValues(alpha: .35)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: C.fg(context).withValues(alpha: .7))),
          ]),
        ),
      );
}
