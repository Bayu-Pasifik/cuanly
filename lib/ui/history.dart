import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'common.dart';

/// Bottom sheet listing history rows (newest first) with delete.
/// Returns true when something was deleted so the caller can reload.
Future<bool> showHistory(
  BuildContext context, {
  required String title,
  required Future<List<Map<String, dynamic>>> Function() load,
  required String dateKey,
  required Future<void> Function(Map<String, dynamic>) onDelete,
  required num total, // running total on the parent row, to show untracked older amounts
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HistorySheet(title: title, load: load, dateKey: dateKey, onDelete: onDelete, total: total),
  );
  return changed ?? false;
}

class _HistorySheet extends StatefulWidget {
  const _HistorySheet({
    required this.title,
    required this.load,
    required this.dateKey,
    required this.onDelete,
    required this.total,
  });

  final String title, dateKey;
  final Future<List<Map<String, dynamic>>> Function() load;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  final num total;

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  late Future<List<Map<String, dynamic>>> _f = widget.load();
  bool _changed = false;
  late num _total = widget.total; // reduced locally as rows are deleted

  Future<void> _delete(Map<String, dynamic> r) async {
    if (!await confirmDelete(context, 'Hapus catatan ${rp(r['amount'])}?',
        message: 'Total akan dikurangi sebesar jumlah ini.')) {
      return;
    }
    if (!mounted) return;
    var ok = true;
    await guarded(context, () async {
      try {
        await widget.onDelete(r);
      } catch (_) {
        ok = false;
        rethrow;
      }
    }, () {});
    if (ok) _total -= r['amount'] as num;
    _changed = true;
    if (mounted) {
      setState(() {
        _f = widget.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.pop(context, _changed);
        },
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
              ),
              Flexible(
                child: Async<List<Map<String, dynamic>>>(
                  future: _f,
                  builder: (_, rows) {
                    final tracked = rows.fold<num>(0, (p, r) => p + (r['amount'] as num));
                    final older = _total - tracked;
                    if (rows.isEmpty && older <= 0) {
                      return const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada riwayat.'));
                    }
                    return ListView(shrinkWrap: true, children: [
                      for (final r in rows)
                        ListTile(
                          title: Text(rp(r['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(DateFormat('d MMM y', 'id_ID').format(DateTime.parse(r[widget.dateKey]))),
                          trailing: IconButton(
                              tooltip: 'Hapus', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(r)),
                        ),
                      if (older > 0)
                        ListTile(
                          title: Text(rp(older), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: const Text('Sebelum riwayat dicatat'),
                        ),
                    ]);
                  },
                ),
              ),
            ]),
          ),
        ),
      );
}
