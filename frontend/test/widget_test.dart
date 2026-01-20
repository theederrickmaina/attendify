import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/login.dart';
import 'package:frontend/screens/consent.dart';

void main() {
  testWidgets('App starts with Consent Screen if not accepted', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // Note: SecureStore/APIService mocking is complex in widget tests without dependency injection.
    // For this basic test, we assume the initial state (no token, no consent).

    await tester.pumpWidget(const AttendifyApp());
    await tester.pumpAndSettle();

    // Should see Consent Screen text
    expect(find.textContaining('Consent'), findsOneWidget);
    expect(find.byType(ConsentScreen), findsOneWidget);
  });

  testWidgets('Login screen has username and password fields', (
    WidgetTester tester,
  ) async {
    // Isolated Login Screen test
    await tester.pumpWidget(MaterialApp(home: LoginScreen(onLoggedIn: () {})));

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(
      find.byType(ElevatedButton),
      findsNothing,
    ); // It's a NeumoButton which might be different or Custom
    expect(find.text('Login'), findsOneWidget);
  });
}
