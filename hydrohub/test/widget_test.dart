//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrohub/main.dart'; // change this to your actual app package

void main() {
  testWidgets('HomePage shows HydroHub and buttons, navigation works',
      (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const HydroHubApp());

    // ✅ Check if "HydroHub" title is present
    expect(find.text('HydroHub'), findsOneWidget);

    // ✅ Check if Sales, Orders, Stocks buttons exist
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Stocks'), findsOneWidget);

    // ✅ Tap on Sales button
    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle(); // Wait for navigation animation

    // ✅ Check if navigated to Sales Page
    expect(find.text('This is the Sales Page'), findsOneWidget);
  });
}
