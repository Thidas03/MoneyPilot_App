-- Migration: Update profiles badge default and update legacy flight captain rows
ALTER TABLE public.profiles ALTER COLUMN flight_badge SET DEFAULT 'ACTIVE MEMBER';
UPDATE public.profiles SET flight_badge = 'ACTIVE MEMBER' WHERE flight_badge = 'FLIGHT CAPTAIN' OR flight_badge IS NULL;
