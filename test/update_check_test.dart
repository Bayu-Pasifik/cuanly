import 'package:cuanly/data/update_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compareVersions', () {
    expect(compareVersions('1.10.0', '1.9.0') > 0, true);
    expect(compareVersions('v1.5.0', '1.5.0+6'), 0);
    expect(compareVersions('1.4.9', '1.5.0') < 0, true);
    expect(compareVersions('1.5', '1.5.0'), 0);
  });

  test('parseRelease picks apk and flags newer', () {
    final info = parseRelease({
      'tag_name': 'v1.6.0',
      'html_url': 'https://x/r',
      'body': 'notes',
      'assets': [
        {'name': 'cuanly-1.6.0.apk', 'browser_download_url': 'https://x/a.apk'}
      ],
    }, '1.5.0');
    expect(info.available, true);
    expect(info.apkUrl, 'https://x/a.apk');
    expect(parseRelease({'tag_name': 'v1.5.0'}, '1.5.0').available, false);
  });
}
