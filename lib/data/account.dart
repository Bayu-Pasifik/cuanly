import 'package:supabase_flutter/supabase_flutter.dart';

import 'repo.dart';

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool isValidEmail(String s) => _emailRe.hasMatch(s.trim());

const minPasswordLength = 6;

/// Why [password] is unacceptable, or null when fine.
String? passwordProblem(String password) =>
    password.length < minPasswordLength ? 'Password minimal $minPasswordLength karakter' : null;

const _commonDomains = ['gmail.com', 'yahoo.com', 'yahoo.co.id', 'outlook.com', 'hotmail.com', 'icloud.com', 'ymail.com'];

int _distance(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = <int>[i];
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur.add([prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y));
    }
    prev = cur;
  }
  return prev.last;
}

/// A corrected address when the domain looks like a typo of a common provider (gmial.com -> gmail.com), else null.
String? suggestEmailFix(String email) {
  final e = email.trim().toLowerCase();
  final at = e.lastIndexOf('@');
  if (at <= 0 || at == e.length - 1) return null;
  final domain = e.substring(at + 1);
  if (_commonDomains.contains(domain)) return null;
  String? best;
  var bestDist = 3;
  for (final d in _commonDomains) {
    final dist = _distance(domain, d);
    if (dist < bestDist) {
      best = d;
      bestDist = dist;
    }
  }
  // Distance 1-2 only; anything further is probably a real, different domain.
  return best == null ? null : '${e.substring(0, at)}@$best';
}

/// Account deletion must be confirmed by typing this word.
const deleteWord = 'HAPUS';

bool deleteConfirmed(String typed) => typed.trim().toUpperCase() == deleteWord;

extension AccountRepo on Repo {
  /// Permanently removes the signed-in account and all its data (server function `delete_my_account`).
  Future<void> deleteMyAccount() async {
    await db.rpc('delete_my_account');
  }

  Future<void> changePassword(String newPassword) async {
    await db.auth.updateUser(UserAttributes(password: newPassword));
  }
}
