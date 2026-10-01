# MoneyPilot — Supabase Database Setup & Migration Guide

This directory contains the database schema and migrations for MoneyPilot.

## Files

- `schema.sql`: Complete PostgreSQL schema ready to be copied into the Supabase SQL Editor for a fresh database.
- `migrations/20260929_init_moneypilot_schema.sql`: Initial versioned migration file.
- `migrations/20261001_add_note_to_savings_goals.sql`: Adds the `note` column to `savings_goals`.

---

### Updating an Existing Database (Migration)
If you already have a running Supabase project:
1. In the Supabase Dashboard, go to **SQL Editor** -> **New Query**.
2. Run the SQL statement from `migrations/20261001_add_note_to_savings_goals.sql`:
   ```sql
   ALTER TABLE public.savings_goals ADD COLUMN IF NOT EXISTS note TEXT;
   ```
3. Click **Run**.

## Step-by-Step Setup Guide

### 1. Create a Supabase Project
1. Log into [Supabase](https://supabase.com).
2. Click **New Project** and name it `MoneyPilot` (or your preferred name).
3. Select your preferred database region and set a strong database password.

### 2. Apply Database Schema
1. In your Supabase Project Dashboard, navigate to the **SQL Editor** on the left navigation menu.
2. Click **New Query**.
3. Open `supabase/schema.sql` in this repo, copy its entire contents, paste it into the SQL Editor, and click **Run**.
4. Confirm in the **Table Editor** that the following tables exist:
   - `profiles`
   - `categories` (with 12 default system categories seeded)
   - `transactions`
   - `budgets`
   - `savings_goals`
   - `goal_contributions`
   - `reminders`

### 3. Configure Client Credentials
1. In the Supabase Dashboard, go to **Project Settings** (gear icon) -> **API**.
2. Copy:
   - **Project URL** (e.g. `https://your-project.supabase.co`)
   - **Project API Keys** -> `anon` / `public` key (safe for mobile/web clients).
   *(NEVER copy or use the `service_role` secret key in the Flutter app).*
3. Create your local `.env` file from the template:
   ```bash
   cp .env.example .env
   ```
4. Paste your URL and Anon Key into `.env`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-publishable-key
   ```
5. Run MoneyPilot with the environment configuration:
   ```bash
   flutter run -d chrome --dart-define-from-file=.env
   ```
