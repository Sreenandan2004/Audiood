import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audiood/pages/about_page.dart';

void main() {
  testWidgets('AboutPage renders app version and branding', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    expect(find.text('Audiood'), findsWidgets);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('CORE CAPABILITIES'), findsOneWidget);
  });
}
