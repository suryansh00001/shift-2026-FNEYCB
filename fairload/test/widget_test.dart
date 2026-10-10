import 'package:flutter_test/flutter_test.dart';
import 'package:fairload/main.dart';

void main() {
  testWidgets('FairLoad smoke test - App boots with Navigation Bar', (WidgetTester tester) async {
    await tester.pumpWidget(const FairLoadApp());
    await tester.pumpAndSettle();

    // Verify presence of navigation labels
    expect(find.text('COCKPIT'), findsOneWidget);
    expect(find.text('BATTERY'), findsOneWidget);
    expect(find.text('PAYLOAD'), findsOneWidget);
    expect(find.text('DISPUTE'), findsOneWidget);
  });
}
