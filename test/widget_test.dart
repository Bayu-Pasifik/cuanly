import 'package:flutter_test/flutter_test.dart';
import 'package:cuanly/main.dart';

void main() {
  testWidgets('shows config hint without Supabase keys', (tester) async {
    await tester.pumpWidget(const CuanlyApp());
    expect(find.textContaining('Supabase belum dikonfigurasi'), findsOneWidget);
  });
}
