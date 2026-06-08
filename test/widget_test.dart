// This is a basic Flutter widget test.
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audiood/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  testWidgets('Audiood smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // It starts with a CircularProgressIndicator while loading profiles
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the asynchronous filesystem I/O run in the event loop
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    // Re-render the widget tree after the future completes
    await tester.pump();

    // Verify that the CircularProgressIndicator is gone
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Verify that we display the default profile "ZONAL"
    expect(find.text('ZONAL'), findsOneWidget);

    // Clean up any remaining timers (like the 500ms delay in initShareHandler)
    await tester.pump(const Duration(seconds: 1));
  });
}
