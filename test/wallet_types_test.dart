import 'package:cuanly/data/wallet_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('codes are unique and cover the Mucuans asset types', () {
    final codes = [for (final t in walletTypes) t.code];
    expect(codes.toSet().length, codes.length);
    expect(codes, containsAll(['regular', 'saving', 'credit_card', 'investment', 'business', 'debt_book']));
  });

  test('walletType falls back to regular for unknown or missing codes', () {
    expect(walletType('credit_card').label, 'Kartu kredit');
    expect(walletType('mystery').code, 'regular');
    expect(walletType(null).code, 'regular');
  });
}
