import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/app.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper to load app landed on Login screen with realistic mobile viewport
  Future<void> loadLoginScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    FlutterSecureStorage.setMockInitialValues({
      'moneypilot_has_seen_onboarding': 'true',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MoneyPilotApp(),
      ),
    );

    // Advance splash delay
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
  }

  // =========================================================================
  // SPLASH & ONBOARDING SUITE
  // =========================================================================

  testWidgets('First install: Splash renders, waits, then routes to Onboarding walkthrough', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MoneyPilotApp(),
      ),
    );

    expect(find.text('MONEYPILOT'), findsOneWidget);
    expect(find.text('Navigate your finances with precision'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('MoneyPilot'), findsWidgets);
    expect(find.text('Take Command of Every Rupee'), findsOneWidget);
    expect(find.text('REAL-TIME TRACKING'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Onboarding walkthrough navigation and completion flow to Register', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    FlutterSecureStorage.setMockInitialValues({});

    late ProviderContainer container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container = ProviderContainer(),
        child: const MoneyPilotApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Take Command of Every Rupee'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Navigate Clear of Overspending'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Soar Towards Your Life Goals'), findsOneWidget);

    await tester.tap(find.text('Get Started with MoneyPilot'));
    await tester.pumpAndSettle();

    final secureStorage = container.read(secureStorageProvider);
    expect(await secureStorage.hasSeenOnboarding(), isTrue);
    expect(find.text('Create Account'), findsWidgets);
  });

  testWidgets('Onboarding skip button marks onboarding complete and navigates to Login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    FlutterSecureStorage.setMockInitialValues({});

    late ProviderContainer container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container = ProviderContainer(),
        child: const MoneyPilotApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    final secureStorage = container.read(secureStorageProvider);
    expect(await secureStorage.hasSeenOnboarding(), isTrue);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Returning user routes directly from Splash to Login', (WidgetTester tester) async {
    await loadLoginScreen(tester);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  // =========================================================================
  // LOGIN SCREEN TESTS
  // =========================================================================

  testWidgets('Login: renders and validates empty/invalid email and empty password', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log in to navigate your financial flight path'), findsOneWidget);

    // Tap Log In with empty form
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Enter invalid email format
    final emailField = find.byType(TextFormField).at(0);
    await tester.enterText(emailField, 'invalid-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Login: password visibility toggle works', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    final passwordFieldFinder = find.byType(TextField).at(1);
    final initialField = tester.widget<TextField>(passwordFieldFinder);
    expect(initialField.obscureText, isTrue);

    // Initial icon is visibility_off_outlined
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    final revealedField = tester.widget<TextField>(passwordFieldFinder);
    expect(revealedField.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    // Tap again to obscure
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    final obscuredAgainField = tester.widget<TextField>(passwordFieldFinder);
    expect(obscuredAgainField.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('Login: valid form allows login and navigates to Dashboard', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'pilot@moneypilot.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard coming soon'), findsOneWidget);
  });

  // =========================================================================
  // REGISTER SCREEN TESTS
  // =========================================================================

  testWidgets('Register: renders and validates required fields and invalid email', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    // Navigate to Register
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsWidgets);

    // Tap Create Account with empty fields
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);

    // Enter invalid email and short password
    await tester.enterText(find.byType(TextFormField).at(0), 'Thidas');
    await tester.enterText(find.byType(TextFormField).at(1), 'notanemail');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.enterText(find.byType(TextFormField).at(3), '123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('Register: validates password mismatch', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Thidas');
    await tester.enterText(find.byType(TextFormField).at(1), 'thidas@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'securePass1');
    await tester.enterText(find.byType(TextFormField).at(3), 'securePass2');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Register: valid registration form allows submission to Dashboard', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Thidas Rathnayake');
    await tester.enterText(find.byType(TextFormField).at(1), 'thidas@moneypilot.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'correctHorseBattery');
    await tester.enterText(find.byType(TextFormField).at(3), 'correctHorseBattery');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard coming soon'), findsOneWidget);
  });

  // =========================================================================
  // FORGOT PASSWORD TESTS
  // =========================================================================

  testWidgets('Forgot Password: validates invalid email and displays confirmation on valid email', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);

    // Submit empty
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);

    // Submit invalid
    await tester.enterText(find.byType(TextFormField).first, 'bademail');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address'), findsOneWidget);

    // Submit valid email
    await tester.enterText(find.byType(TextFormField).first, 'pilot@moneypilot.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Check Your Inbox'), findsOneWidget);
    expect(find.text('Password reset instructions have been sent to your email.'), findsOneWidget);

    // Return to Login
    await tester.tap(find.text('Return to Login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  // =========================================================================
  // NAVIGATION SUITE
  // =========================================================================

  testWidgets('Navigation: Login to Register and back to Login', (WidgetTester tester) async {
    await loadLoginScreen(tester);
    expect(find.text('Welcome Back'), findsOneWidget);

    // Go to Register
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsWidgets);

    // Return to Login via bottom link
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
