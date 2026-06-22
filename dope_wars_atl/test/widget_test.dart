import 'package:flutter_test/flutter_test.dart';
import 'package:dope_wars_atl/main.dart';

void main() {
  testWidgets('App boots successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const DopeWarsApp());
    // Verify the app loads without crashing
    expect(find.byType(DopeWarsApp), findsOneWidget);
  });
}
