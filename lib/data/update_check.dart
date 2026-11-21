import 'dart:convert';
import 'dart:io';

const _latestUrl = 'https://api.github.com/repos/Bayu-Pasifik/cuanly/releases/latest';

class UpdateInfo {
  final String version; // latest tag without leading "v"
  final String pageUrl;
  final String? apkUrl;
  final String notes;
  final bool available;
  const UpdateInfo({
    required this.version,
    required this.pageUrl,
    required this.apkUrl,
    required this.notes,
    required this.available,
  });
}

/// Compares dotted versions ("1.5.0" vs "1.10.0"); build suffix ("+6") ignored.
/// Returns >0 when [a] is newer than [b].
int compareVersions(String a, String b) {
  List<int> parse(String v) =>
      v.replaceFirst(RegExp(r'^[vV]'), '').split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final x = parse(a), y = parse(b);
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

UpdateInfo parseRelease(Map<String, dynamic> json, String currentVersion) {
  final tag = (json['tag_name'] as String? ?? '').replaceFirst(RegExp(r'^[vV]'), '');
  String? apk;
  for (final a in (json['assets'] as List? ?? const [])) {
    final name = (a['name'] as String? ?? '').toLowerCase();
    if (name.endsWith('.apk')) {
      apk = a['browser_download_url'] as String?;
      break;
    }
  }
  return UpdateInfo(
    version: tag,
    pageUrl: json['html_url'] as String? ?? 'https://github.com/Bayu-Pasifik/cuanly/releases',
    apkUrl: apk,
    notes: (json['body'] as String? ?? '').trim(),
    available: tag.isNotEmpty && compareVersions(tag, currentVersion) > 0,
  );
}

Future<UpdateInfo> checkForUpdate(String currentVersion) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(Uri.parse(_latestUrl));
    req.headers.set('Accept', 'application/vnd.github+json');
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw HttpException('GitHub ${res.statusCode}');
    final body = await res.transform(utf8.decoder).join();
    return parseRelease(jsonDecode(body) as Map<String, dynamic>, currentVersion);
  } finally {
    client.close();
  }
}
