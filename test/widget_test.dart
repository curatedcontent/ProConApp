// This is a basic Flutter widget test for ProCon app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:procon_app_flutter/main.dart';

void main() {
  testWidgets('ProCon app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProConApp());

    // Verify that the app launches
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that we have the bottom navigation tabs
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.list), findsOneWidget);
  });
}
