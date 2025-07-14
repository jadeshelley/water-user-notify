// This is a basic Flutter widget test for the Water User Notify app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:water_user_notify/main.dart';
import 'package:water_user_notify/providers/water_management_provider.dart';

void main() {
  testWidgets('Water User Notify app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Just verify the app starts without crashing
    // This is a basic smoke test to ensure the app can be built and displayed
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
