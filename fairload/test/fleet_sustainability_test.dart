import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairload/presentation/screens/fleet_sustainability_screen.dart';

void main() {
  testWidgets('FleetSustainabilityScreen renders Saved Recruiting New Rider Cost perspective by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FleetSustainabilityScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Saved Recruiting New Rider Cost is active and visible
    expect(find.text('SAVED RECRUITING NEW RIDER COST'), findsOneWidget);
    expect(find.text('RIDER RECRUITING'), findsOneWidget);
    expect(find.text('BATTERY HARDWARE'), findsOneWidget);
    expect(find.text('COMBINED ROI'), findsOneWidget);
    expect(find.text('RIDER ATTRITION & RECRUITMENT ROI METRICS'), findsOneWidget);
    expect(find.text('Avoided New Recruits'), findsOneWidget);
    expect(find.text('New Rider CAC Saved'), findsOneWidget);
    expect(find.text('Annual Churn Slashed'), findsOneWidget);
    expect(find.text('NEW RIDER RECRUITMENT COST BREAKDOWN (₹6,500 CAC)'), findsOneWidget);

    // Switch to Battery Hardware perspective
    await tester.tap(find.text('BATTERY HARDWARE'));
    await tester.pumpAndSettle();

    expect(find.text('AVOIDED PACK LOSSES'), findsOneWidget);
    expect(find.text('PHYSICAL ESG & ENVIRONMENTAL DIVIDEND'), findsOneWidget);
    expect(find.text('Avoided Pack Scraps'), findsOneWidget);

    // Switch to Combined ROI perspective
    await tester.tap(find.text('COMBINED ROI'));
    await tester.pumpAndSettle();

    expect(find.text('SAVED RECRUITING + PACKS'), findsOneWidget);
    expect(find.text('DUAL PLATFORM SYNERGIES: HR RECRUITING + HARDWARE ASSET ROI'), findsOneWidget);
  });
}
