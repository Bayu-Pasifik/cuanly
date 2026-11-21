import 'package:cuanly/ui/common.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _type(String text, {String old = ''}) =>
    const AmountFormatter().formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)),
    );

void main() {
  test('groups digits with dots as the user types', () {
    expect(_type('1000000').text, '1.000.000');
    expect(_type('1000').text, '1.000');
    expect(_type('999').text, '999');
  });

  test('regroups when a digit is added to an already formatted value', () {
    expect(_type('1.0000', old: '1.000').text, '10.000');
  });

  test('ignores non-digits and empties cleanly', () {
    expect(_type('12ab').text, '12');
    expect(_type('').text, '');
  });

  test('keeps caret at the end when typing at the end', () {
    final v = _type('1000000');
    expect(v.selection.baseOffset, v.text.length);
  });

  test('fmtAmount output still parses back', () {
    expect(parseAmount(fmtAmount(1234567)), 1234567);
  });
}
