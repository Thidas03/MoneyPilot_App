-- Migration: Add note column to savings_goals
ALTER TABLE public.savings_goals ADD COLUMN IF NOT EXISTS note TEXT;
