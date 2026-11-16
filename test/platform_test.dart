import 'package:cuanly/data/backup.dart';
import 'package:cuanly/data/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hashPin is salted and deterministic', () {
    expect(hashPin('123456', 'a'), hashPin('123456', 'a'));
    expect(hashPin('123456', 'a'), isNot(hashPin('123456', 'b')));
    expect(hashPin('123456', 'a'), isNot(hashPin('654321', 'a')));
  });

  test('backup round-trips', () {
    final json = encodeBackup({
      'wallets': [
        {'id': 'w1', 'name': 'BCA', 'balance': 100}
      ],
      'debts': [],
    }, DateTime.utc(2026, 11, 16));
    final back = decodeBackup(json);
    expect(back['wallets']!.single['name'], 'BCA');
    expect(back['debts'], isEmpty);
    expect(back.containsKey('transactions'), isFalse);
  });

  test('decodeBackup rejects foreign or newer files', () {
    expect(() => decodeBackup('not json'), throwsFormatException);
    expect(() => decodeBackup('{"app":"other","tables":{}}'), throwsFormatException);
    expect(() => decodeBackup('{"app":"cuanly","version":99,"tables":{}}'), throwsFormatException);
    expect(() => decodeBackup('{"app":"cuanly","version":1,"tables":{"wallets":[1]}}'), throwsFormatException);
  });
}
