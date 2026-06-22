import 'package:flutter_test/flutter_test.dart';
import 'package:dope_wars_atlanta/main.dart';

void main() {
  testWidgets('App boots and shows loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DopeWarsApp());
    expect(find.text('DOPE WARS'), findsOneWidget);
    expect(find.text('ATLANTA'), findsOneWidget);
  });
}
