-- ==============================================================================
-- MoneyPilot Complete Database Schema (Supabase SQL Editor Ready)
-- ==============================================================================
-- To apply: Copy and paste the contents of this file into your Supabase Dashboard
-- SQL Editor (https://supabase.com/dashboard/project/_/sql) and click "Run".
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USER PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    avatar_url TEXT,
    currency_code TEXT NOT NULL DEFAULT 'LKR',
    currency_symbol TEXT NOT NULL DEFAULT 'Rs.',
    flight_badge TEXT NOT NULL DEFAULT 'ACTIVE MEMBER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Auto-provision user profile when a new user signs up in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, avatar_url)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        new.email,
        new.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'both')),
    icon TEXT NOT NULL DEFAULT 'category_outlined',
    color_hex TEXT NOT NULL DEFAULT '#64748B',
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_categories_user_name_type UNIQUE NULLS NOT DISTINCT (user_id, name, type)
);

CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id, is_system);

-- Seed system default categories
INSERT INTO public.categories (name, type, icon, color_hex, is_system)
VALUES
    ('Salary', 'income', 'account_balance_wallet_outlined', '#10B981', TRUE),
    ('Investments', 'income', 'trending_up_outlined', '#06B6D4', TRUE),
    ('Rent/Mortgage', 'expense', 'home_outlined', '#6366F1', TRUE),
    ('Groceries', 'expense', 'shopping_cart_outlined', '#F59E0B', TRUE),
    ('Utilities', 'expense', 'flash_on_outlined', '#EAB308', TRUE),
    ('Dining Out', 'expense', 'restaurant_outlined', '#F97316', TRUE),
    ('Transportation', 'expense', 'directions_car_outlined', '#3B82F6', TRUE),
    ('Entertainment', 'expense', 'movie_outlined', '#EC4899', TRUE),
    ('Shopping', 'expense', 'shopping_bag_outlined', '#8B5CF6', TRUE),
    ('Health/Medical', 'expense', 'medical_services_outlined', '#EF4444', TRUE),
    ('Education', 'expense', 'school_outlined', '#14B8A6', TRUE),
    ('Misc', 'both', 'category_outlined', '#64748B', TRUE)
ON CONFLICT DO NOTHING;

-- 4. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_category ON public.transactions(user_id, category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_type_date ON public.transactions(user_id, type, transaction_date DESC);

-- 5. BUDGETS TABLE
CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    period TEXT NOT NULL DEFAULT 'monthly' CHECK (period IN ('weekly', 'monthly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_budgets_user_cat_period UNIQUE (user_id, category_id, start_date, period)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_period ON public.budgets(user_id, start_date, end_date);

-- 6. SAVINGS GOALS & CONTRIBUTIONS
CREATE TABLE IF NOT EXISTS public.savings_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    target_amount NUMERIC(14, 2) NOT NULL CHECK (target_amount > 0),
    current_amount NUMERIC(14, 2) NOT NULL DEFAULT 0.00 CHECK (current_amount >= 0),
    target_date DATE NOT NULL,
    icon TEXT NOT NULL DEFAULT 'flag_rounded',
    color_hex TEXT NOT NULL DEFAULT '#005C46',
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'paused')),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_goals_user ON public.savings_goals(user_id, status);

CREATE TABLE IF NOT EXISTS public.goal_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID NOT NULL REFERENCES public.savings_goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    contribution_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal ON public.goal_contributions(goal_id, contribution_date DESC);

CREATE OR REPLACE FUNCTION public.sync_goal_current_amount()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.savings_goals
        SET current_amount = current_amount + NEW.amount,
            updated_at = now()
        WHERE id = NEW.goal_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.savings_goals
        SET current_amount = GREATEST(0.00, current_amount - OLD.amount),
            updated_at = now()
        WHERE id = OLD.goal_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_goal_contribution_change ON public.goal_contributions;
CREATE TRIGGER on_goal_contribution_change
    AFTER INSERT OR DELETE ON public.goal_contributions
    FOR EACH ROW EXECUTE FUNCTION public.sync_goal_current_amount();

-- 7. REMINDERS TABLE
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    amount NUMERIC(14, 2) CHECK (amount IS NULL OR amount > 0),
    due_date TIMESTAMPTZ NOT NULL,
    frequency TEXT NOT NULL DEFAULT 'once' CHECK (frequency IN ('once', 'daily', 'weekly', 'monthly', 'yearly')),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_due ON public.reminders(user_id, due_date ASC, is_completed);

-- 8. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Categories Policies
DROP POLICY IF EXISTS "Users view system and own categories" ON public.categories;
CREATE POLICY "Users view system and own categories" ON public.categories
    FOR SELECT USING (is_system = TRUE OR user_id = auth.uid());

DROP POLICY IF EXISTS "Users insert own categories" ON public.categories;
CREATE POLICY "Users insert own categories" ON public.categories
    FOR INSERT WITH CHECK (user_id = auth.uid() AND is_system = FALSE);

DROP POLICY IF EXISTS "Users update own categories" ON public.categories;
CREATE POLICY "Users update own categories" ON public.categories
    FOR UPDATE USING (user_id = auth.uid() AND is_system = FALSE);

DROP POLICY IF EXISTS "Users delete own categories" ON public.categories;
CREATE POLICY "Users delete own categories" ON public.categories
    FOR DELETE USING (user_id = auth.uid() AND is_system = FALSE);

-- Transactions Policies
DROP POLICY IF EXISTS "Users manage own transactions" ON public.transactions;
CREATE POLICY "Users manage own transactions" ON public.transactions
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Budgets Policies
DROP POLICY IF EXISTS "Users manage own budgets" ON public.budgets;
CREATE POLICY "Users manage own budgets" ON public.budgets
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Savings Goals Policies
DROP POLICY IF EXISTS "Users manage own goals" ON public.savings_goals;
CREATE POLICY "Users manage own goals" ON public.savings_goals
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own goal contributions" ON public.goal_contributions;
CREATE POLICY "Users manage own goal contributions" ON public.goal_contributions
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Reminders Policies
DROP POLICY IF EXISTS "Users manage own reminders" ON public.reminders;
CREATE POLICY "Users manage own reminders" ON public.reminders
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 9. ANALYTICAL VIEWS
CREATE OR REPLACE VIEW public.budget_overview 
WITH (security_invoker = true) AS
SELECT 
    b.id AS budget_id,
    b.user_id,
    b.category_id,
    c.name AS category_name,
    c.icon AS category_icon,
    c.color_hex AS category_color,
    b.amount AS budget_limit,
    COALESCE(SUM(t.amount), 0.00) AS spent,
    GREATEST(0.00, b.amount - COALESCE(SUM(t.amount), 0.00)) AS remaining,
    CASE 
        WHEN b.amount > 0 THEN LEAST(1.0, COALESCE(SUM(t.amount), 0.00) / b.amount)
        ELSE 0.0 
    END AS progress,
    b.period,
    b.start_date,
    b.end_date
FROM public.budgets b
JOIN public.categories c ON b.category_id = c.id
LEFT JOIN public.transactions t ON t.user_id = b.user_id 
    AND t.category_id = b.category_id 
    AND t.type = 'expense'
    AND t.transaction_date >= b.start_date 
    AND t.transaction_date <= (b.end_date + INTERVAL '1 day' - INTERVAL '1 millisecond')
GROUP BY b.id, b.user_id, b.category_id, c.name, c.icon, c.color_hex, b.amount, b.period, b.start_date, b.end_date;

CREATE OR REPLACE VIEW public.monthly_financial_summary 
WITH (security_invoker = true) AS
SELECT 
    user_id,
    date_trunc('month', transaction_date) AS summary_month,
    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0.00) AS total_income,
    COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0.00) AS total_expense,
    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0.00) AS net_savings,
    CASE 
        WHEN SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) > 0 
        THEN ROUND((COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0.00) / SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END)) * 100, 1)
        ELSE 0.0 
    END AS savings_rate
FROM public.transactions
GROUP BY user_id, date_trunc('month', transaction_date);

