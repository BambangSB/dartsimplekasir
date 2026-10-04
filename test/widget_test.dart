import 'package:flutter_test/flutter_test.dart';
import 'package:simple_kasir/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SimpleKasirApp());
    expect(find.text('Kasir UMKM'), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
