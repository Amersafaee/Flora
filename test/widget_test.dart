import 'package:flutter_test/flutter_test.dart';
import 'package:digital_conservatory/main.dart';

void main() {
  testWidgets('DigitalConservatoryApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DigitalConservatoryApp());
    expect(find.byType(DigitalConservatoryApp), findsOneWidget);
  });
}
