// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =======================================================================
//
// THIS IS THE CORRECTED IMPORT PATH.
// Notice the '/src/' which matches your project structure.
//
import 'package:al_faruk_app/main.dart';
//
// =======================================================================

void main() {
  testWidgets('App starts and renders without crashing',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // It must be wrapped in a ProviderScope because MyApp is a ConsumerWidget.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the app shows a loading indicator at first,
    // which is the expected behavior from the AuthGate.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
