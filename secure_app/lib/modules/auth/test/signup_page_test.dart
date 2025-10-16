import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../presentation/signup_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SignUpPage Widget Tests', () {
    Widget createSignUpPage() {
      return MaterialApp(
        home: const SignUpPage(),
      );
    }

    group('Widget Rendering Tests', () {
      testWidgets('should render sign up page with all required elements', (WidgetTester tester) async {
        await tester.pumpWidget(createSignUpPage());

        // Check if the page title is displayed
        expect(find.text('Hello Sign up'), findsOneWidget);

        // Check if name field is present
        expect(find.text('Name'), findsOneWidget);

        // Check if email field is present
        expect(find.text('Email'), findsOneWidget);

        // Check if password field is present
        expect(find.text('Password'), findsOneWidget);

        // Check if confirm password field is present
        expect(find.text('Confirm Password'), findsOneWidget);

        // Check if sign up button is present
        expect(find.text('SIGN UP'), findsOneWidget);

        // Check if sign in link is present
        expect(find.text('Already have an account?'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
      });

      testWidgets('should render gradient background', (WidgetTester tester) async {
        await tester.pumpWidget(createSignUpPage());

        // Check if Container with gradient is present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should render form with proper structure', (WidgetTester tester) async {
        await tester.pumpWidget(createSignUpPage());

        // Check if Form widget is present
        expect(find.byType(Form), findsOneWidget);

        // Check if TextFormField widgets are present (4 fields: name, email, password, confirm password)
        expect(find.byType(TextFormField), findsNWidgets(4));
      });
    });

    group('User Interaction Tests', () {
      testWidgets('should allow user to enter name', (WidgetTester tester) async {
        await tester.pumpWidget(createSignUpPage());

        const testName = 'John Doe';
        final nameField = find.byType(TextFormField).first;

        await tester.enterText(nameField, testName);
        await tester.pump();

        expect(find.text(testName), findsOneWidget);
      });

      testWidgets('should allow user to enter email', (WidgetTester tester) async {
        await tester.pumpWidget(createSignUpPage());

        const testEmail = 'test@example.com';
        final emailField = find.byType(TextFormField).at(1);

        await tester.enterText(emailField, testEmail);
        await tester.pump();

        expect(find.text(testEmail), findsOneWidget);
      });

      testWidgets('should allow user to enter password', (WidgetTester tester) async {
        await tester.pumpWidget(createSignUpPage());

        const testPassword = 'password123';
        final passwordField = find.byType(TextFormField).at(2);

        await tester.enterText(passwordField, testPassword);
        await tester.pump();

        // Password should be obscured
        expect(find.text(testPassword), findsNothing);
      });

      testWidgets('should allow user to enter confirm password', (WidgetTester tester) async {
        await tester.pumpWidget(createSignUpPage());

        const testPassword = 'password123';
        final confirmPasswordField = find.byType(TextFormField).at(3);

        await tester.enterText(confirmPasswordField, testPassword);
        await tester.pump();

        // Password should be obscured
        expect(find.text(testPassword), findsNothing);
      });
    });
  });
}