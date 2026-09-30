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

  // Helper to load app into Dashboard
  Future<void> loadDashboard(WidgetTester tester) async {
    await loadLoginScreen(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'pilot@moneypilot.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
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

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log In'), findsWidgets);
  });

  // =========================================================================
  // LOGIN SCREEN TESTS
  // =========================================================================

  testWidgets('Login: renders and validates empty/invalid email and empty password', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    expect(find.text('Welcome Back'), findsOneWidget);

    // Tap Log In with empty fields
    final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Enter invalid email format
    await tester.enterText(find.byType(TextFormField).at(0), 'invalidemailformat');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('Login: password visibility toggle works', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    final passwordFieldFinder = find.byType(TextField).at(1);
    TextField passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isTrue);

    // Tap toggle visibility icon
    final visibilityIcon = find.byIcon(Icons.visibility_off_outlined);
    expect(visibilityIcon, findsOneWidget);
    await tester.tap(visibilityIcon);
    await tester.pumpAndSettle();

    passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isFalse);
  });

  testWidgets('Login: valid form allows login and navigates to Dashboard', (WidgetTester tester) async {
    await loadLoginScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'pilot@moneypilot.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome aboard!'), findsOneWidget);
    expect(find.text('FINANCIAL OVERVIEW'), findsOneWidget);
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

    expect(find.text('Welcome aboard!'), findsOneWidget);
    expect(find.text('FINANCIAL OVERVIEW'), findsOneWidget);
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

  // =========================================================================
  // MAIN APP SHELL & DASHBOARD TESTS
  // =========================================================================

  testWidgets('Main Shell: bottom navigation renders 5 destinations and switches branches', (WidgetTester tester) async {
    await loadDashboard(tester);

    // Verify all 5 bottom nav items are rendered
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Reports'), findsWidgets);

    // Switch to Transactions tab via bottom nav
    await tester.tap(find.widgetWithText(AnimatedContainer, 'Transactions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transaction_search_field')), findsOneWidget);

    // Switch to Budget tab
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Budget Target'), findsOneWidget);

    // Switch to Goals tab
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
    expect(find.text('Goals coming soon'), findsOneWidget);

    // Switch to Reports tab
    await tester.tap(find.widgetWithText(AnimatedContainer, 'Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Reports coming soon'), findsOneWidget);

    // Switch back to Home (Dashboard)
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome aboard!'), findsOneWidget);
  });

  testWidgets('Dashboard: header, balance cards, cashflow chart, transactions, budgets, goals render', (WidgetTester tester) async {
    await loadDashboard(tester);

    // Greeting & Header
    expect(find.text('MoneyPilot'), findsWidgets);
    expect(find.text('Welcome aboard!'), findsOneWidget);

    // Quick Actions
    expect(find.text('+ Add Entry'), findsOneWidget);

    // Financial Overview & Metric Cards
    expect(find.text('FINANCIAL OVERVIEW'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Net Balance / Savings'), findsOneWidget);

    // Cash Flow Chart
    expect(find.text('Weekly Cash Flow'), findsOneWidget);
    expect(find.text('Inflow'), findsOneWidget);
    expect(find.text('Outflow'), findsOneWidget);

    // Recent Transactions
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('Salary'), findsWidgets);
    expect(find.text('Keells Supermarket'), findsOneWidget);
    expect(find.text('Uber'), findsOneWidget);
    expect(find.text('Dialog'), findsOneWidget);
    expect(find.text('Coffee Shop'), findsOneWidget);

    // Monthly Budget preview
    expect(find.text('Monthly Budget'), findsOneWidget);
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('Transportation'), findsWidgets);
    expect(find.text('Entertainment'), findsOneWidget);

    // Goals preview
    expect(find.text('Financial Goals'), findsOneWidget);
    expect(find.text('Emergency Flight Reserve'), findsOneWidget);
    expect(find.text('Japan Vacation'), findsOneWidget);
  });

  testWidgets('Dashboard: Quick Action (+ Add Entry) navigates to /transactions/add', (WidgetTester tester) async {
    await loadDashboard(tester);

    final addEntryButton = find.byKey(const Key('quick_action_add_entry'));
    final inkWell = find.descendant(of: addEntryButton, matching: find.byType(InkWell));
    (tester.widget(inkWell) as InkWell).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.byKey(const Key('save_transaction_button')), findsOneWidget);
  });

  testWidgets('Dashboard: Profile button navigates to /profile and returns', (WidgetTester tester) async {
    await loadDashboard(tester);

    final profileButton = find.byKey(const Key('dashboard_profile_button'));
    expect(profileButton, findsOneWidget);
    (tester.widget(profileButton) as IconButton).onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Pilot Profile'), findsOneWidget);
    expect(find.text('Chief Pilot'), findsOneWidget);
    expect(find.text('pilot@moneypilot.com'), findsOneWidget);
    expect(find.text('FLIGHT CAPTAIN'), findsOneWidget);

    // Back to dashboard
    await tester.tap(find.text('Back to Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome aboard!'), findsOneWidget);
  });

  testWidgets('Profile: Log Out action terminates session and navigates to Login', (WidgetTester tester) async {
    await loadDashboard(tester);

    final profileButton = find.byKey(const Key('dashboard_profile_button'));
    expect(profileButton, findsOneWidget);
    (tester.widget(profileButton) as IconButton).onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Pilot Profile'), findsOneWidget);
    final logoutButton = find.byKey(const Key('profile_logout_button'));
    expect(logoutButton, findsOneWidget);

    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log In'), findsWidgets);
  });
}
