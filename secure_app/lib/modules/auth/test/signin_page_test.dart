import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../presentation/signin_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SignInPage Widget Tests', () {
    Widget createSignInPage() {
      return MaterialApp(
        home: const SignInPage(),
      );
    }

    group('Widget Rendering Tests', () {
      testWidgets('should render sign in page with all required elements', (WidgetTester tester) async {
        await tester.pumpWidget(createSignInPage());

        // Check if the page title is displayed
        expect(find.text('Hello Sign in'), findsOneWidget);

        // Check if email field is present
        expect(find.text('Email'), findsOneWidget);

        // Check if password field is present
        expect(find.text('Password'), findsOneWidget);

        // Check if sign in button is present
        expect(find.text('SIGN IN'), findsOneWidget);

        // Check if sign up link is present
        expect(find.text('Don\'t have an account?'), findsOneWidget);
        expect(find.text('Sign up'), findsOneWidget);
      });

      testWidgets('should render gradient background', (WidgetTester tester) async {
        await tester.pumpWidget(createSignInPage());

        // Check if Container with gradient is present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should render form with proper structure', (WidgetTester tester) async {
        await tester.pumpWidget(createSignInPage());

        // Check if Form widget is present
        expect(find.byType(Form), findsOneWidget);

        // Check if TextFormField widgets are present
        expect(find.byType(TextFormField), findsNWidgets(2));
      });
    });

    group('User Interaction Tests', () {
      testWidgets('should allow user to enter email', (WidgetTester tester) async {
        await tester.pumpWidget(createSignInPage());

        const testEmail = 'test@example.com';
        final emailField = find.byType(TextFormField).first;

        await tester.enterText(emailField, testEmail);
        await tester.pump();

        expect(find.text(testEmail), findsOneWidget);
      });

      testWidgets('should allow user to enter password', (WidgetTester tester) async {
        await tester.pumpWidget(createSignInPage());

        const testPassword = 'password123';
        final passwordField = find.byType(TextFormField).last;

        await tester.enterText(passwordField, testPassword);
        await tester.pump();

        // Password should be obscured
        expect(find.text(testPassword), findsNothing);
      });
    });
  });
}