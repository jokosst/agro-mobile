import 'package:flutter_test/flutter_test.dart';
import 'package:agro_mobile/main.dart';

void main() {
  testWidgets('Agrocom app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgrocomApp());
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(AgrocomApp), findsOneWidget);
  });
}
