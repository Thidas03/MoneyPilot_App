# MoneyPilot 🚀

A modern, full-featured personal finance and expense management application built with **Flutter**, **Riverpod**, and **Supabase**. MoneyPilot empowers users to track income and expenses, establish category budgets, set savings goals, manage bill reminders, and generate exportable PDF financial reports with interactive analytics.

---

## ✨ Features

- **📊 Dynamic Financial Dashboard**
  - Instant overview of Total Balance, Monthly Income, Monthly Expenses, and Total Savings.
  - Recent transaction feed and interactive budget health cards.
  - Quick action shortcuts for instant entry recording.

- **💳 Transaction Management**
  - Full CRUD operations for income and expense transactions.
  - Search, filter by transaction type, and date ranges.
  - Multi-attribute tagging: category, payment method, date, and custom notes.

- **🎯 Category Budgets & Smart Alerts**
  - Monthly budget ceilings configured per expense category.
  - Real-time spend tracking and percentage progress bars.
  - HCI-optimized warnings for near-limit (80%+) and over-budget states.

- **🏆 Savings Goals & Contributions**
  - Track targets with target dates and automatic progress calculation.
  - Deposit contributions directly into specific goals with timestamped logs.
  - Milestone celebrations and "Goal Achieved" badges upon completion.

- **🔔 Bill & Payment Reminders**
  - Never miss a bill or recurring payment.
  - Configurable recurrence frequencies: *One-time*, *Weekly*, *Monthly*, *Yearly*.
  - Quick toggle to mark bills as paid or overdue.

- **📈 Analytics, Visual Charts & PDF Reports**
  - Visual cash flow trends and category spending distribution powered by `fl_chart`.
  - Date-period filtering (Weekly, Monthly, Quarterly, Yearly, Custom).
  - High-resolution, professional PDF financial summary report generation and direct printing via `pdf` and `printing`.

- **🎨 Modern Glassmorphic Design System**
  - Sleek dark and light mode themes built using custom design tokens.
  - Fluid micro-animations, glass cards, and curated typography via Google Fonts (Outfit / Inter).

- **🔒 Enterprise-Grade Security & Authentication**
  - Secure authentication (Sign Up, Sign In, Password Reset) via Supabase Auth.
  - Complete Row-Level Security (RLS) guaranteeing strict per-user data isolation.
  - Sensitive token persistence using hardware-backed Flutter Secure Storage.

---

## 🛠️ Tech Stack

| Domain | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (Dart SDK `^3.13.3`) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev) (`^3.4.3`) |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) (`^18.0.1`) |
| **Backend & Database** | [Supabase Flutter](https://supabase.com) (`^2.17.2`) (PostgreSQL + RLS + Auth) |
| **Charts & Graphs** | [FL Chart](https://pub.dev/packages/fl_chart) (`^1.2.0`) |
| **PDF Generation** | [pdf](https://pub.dev/packages/pdf) (`^3.13.1`) & [printing](https://pub.dev/packages/printing) (`^5.15.1`) |
| **Secure Storage** | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (`^11.1.1`) |
| **Typography** | [google_fonts](https://pub.dev/packages/google_fonts) (`^8.2.1`) |

---

## 📂 Project Architecture

MoneyPilot follows a **feature-first, modular architecture**:

```text
MoneyPilot/
├── assets/
│   └── images/
│       └── logo.png              # Primary brand identity asset
├── lib/
│   ├── app.dart                  # Top-level MaterialApp & router config
│   ├── main.dart                 # Application entry point & Supabase init
│   ├── core/
│   │   ├── network/              # REST & HTTP client configurations
│   │   ├── routing/              # GoRouter route declarations & navigation shell
│   │   ├── storage/              # Secure token and session persistence
│   │   ├── supabase/             # Supabase client singleton & environment configuration
│   │   ├── theme/                # Custom dark/light glassmorphic design system
│   │   └── utils/                # Date, currency, and string formatters
│   ├── features/
│   │   ├── auth/                 # Sign-in, Sign-up, Forgot Password, Auth controller
│   │   ├── budgets/              # Budget models, repositories, providers & screens
│   │   ├── categories/           # Category models & repositories (12 system presets)
│   │   ├── dashboard/            # Central financial overview screen
│   │   ├── goals/                # Savings goals, contributions & detail views
│   │   ├── navigation/           # Bottom navigation shell
│   │   ├── onboarding/           # First-launch welcome walkthrough
│   │   ├── profile/              # User profile management & account settings
│   │   ├── reminders/            # Bill & subscription recurring reminders
│   │   ├── reports/              # Analytics charts, summaries & PDF export service
│   │   └── transactions/         # Transaction CRUD, filters & forms
│   └── shared/
│       └── widgets/              # Reusable UI primitives (GlassCard, CustomButton, etc.)
├── supabase/
│   ├── README.md                 # Supabase setup guide
│   ├── schema.sql                # Complete PostgreSQL schema (tables, RLS, triggers)
│   └── migrations/               # Versioned migration scripts
└── test/                         # Comprehensive suite (186 unit, widget & integration tests)
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`3.24.x` or later recommended, Dart SDK `^3.13.3`)
- [Git](https://git-scm.com/)
- An active [Supabase](https://supabase.com) account (free tier works great)
- An IDE (VS Code with Flutter extension or Android Studio)

---

### Step 1: Clone the Repository

```bash
git clone https://github.com/Thidas03/MoneyPilot_App.git
cd MoneyPilot
```

---

### Step 2: Install Dependencies

Fetch all required Flutter and Dart packages:

```bash
flutter pub get
```

---

### Step 3: Setup Supabase Database

1. Go to [Supabase](https://supabase.com) and create a new project (e.g., `MoneyPilot`).
2. Open your project dashboard and navigate to the **SQL Editor** tab.
3. Open [`supabase/schema.sql`](supabase/schema.sql) in this repository, copy its entire content, paste it into the Supabase SQL Editor, and click **Run**.
4. Confirm that the following tables were created with RLS enabled:
   - `profiles`
   - `categories` *(pre-populated with 12 default income/expense categories)*
   - `transactions`
   - `budgets`
   - `savings_goals`
   - `goal_contributions`
   - `reminders`

---

### Step 4: Configure Environment Variables

1. Copy the sample environment file:
   ```bash
   # On macOS / Linux:
   cp .env.example .env

   # On Windows (PowerShell):
   Copy-Item .env.example .env
   ```

2. Open `.env` and fill in your Supabase project credentials (found under **Project Settings -> API**):
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-publishable-key-here
   ```

> [!IMPORTANT]
> Use only the **`anon` / `public`** key in `.env`. Never use or expose your `service_role` secret key in the mobile/client app.

> [!NOTE]
> If credentials are not supplied, MoneyPilot will automatically fall back to **offline / mock mode**, allowing you to explore the UI without an active database connection.

---

### Step 5: Run the Application

Launch MoneyPilot with your `.env` configuration passed via `--dart-define-from-file`:

#### Run in Google Chrome (Web):
```bash
flutter run -d chrome --dart-define-from-file=.env
```

#### Run on Android (Emulator or Connected Device):
```bash
flutter run -d android --dart-define-from-file=.env
```

#### Run on iOS (Simulator or iPhone):
```bash
flutter run -d ios --dart-define-from-file=.env
```

#### Run on Desktop (Windows / macOS / Linux):
```bash
# Windows
flutter run -d windows --dart-define-from-file=.env

# macOS
flutter run -d macos --dart-define-from-file=.env

# Linux
flutter run -d linux --dart-define-from-file=.env
```

---

## 🧪 Testing & Code Quality

MoneyPilot includes an automated test suite comprising **186 tests** covering repository contracts, domain serialization, reactive providers, and user interface workflows.

### Run All Tests
```bash
flutter test
```

### Run Static Analysis / Linter
```bash
flutter analyze
```

---

## 🛡️ Security & Privacy

- **Row-Level Security (RLS)**: Every database table enforces strict row-level security policies (`auth.uid() = user_id`), ensuring no user can read or modify another user's financial records.
- **Hardware-Backed Keystore**: User session tokens and secure keys are encrypted and stored via `FlutterSecureStorage` (iOS Keychain / Android KeyStore / Linux Secret Service).
- **Environment Isolation**: The `.env` file is excluded from git tracking by default to prevent secret exposure.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
