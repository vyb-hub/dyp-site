-- =============================================
-- DYP — Design Your Packaging
-- Supabase PostgreSQL Schema
-- Run this in: Supabase Dashboard → SQL Editor
-- =============================================

-- ── PROFILES (extends auth.users) ──────────────────────────
CREATE TABLE public.profiles (
  id          UUID        REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email       TEXT        NOT NULL,
  full_name   TEXT,
  role        TEXT        DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── ORDERS ─────────────────────────────────────────────────
CREATE TABLE public.orders (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  ref_id         TEXT        UNIQUE NOT NULL,
  user_id        UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  brand_name     TEXT        NOT NULL,
  business_name  TEXT        NOT NULL,
  contact_name   TEXT        NOT NULL,
  email          TEXT        NOT NULL,
  phone          TEXT,
  product_type   TEXT        NOT NULL CHECK (product_type IN ('bottle', 'can')),
  size           TEXT        NOT NULL,
  design_style   TEXT        NOT NULL,
  label_color    TEXT,
  quantity       INTEGER     NOT NULL CHECK (quantity > 0),
  notes          TEXT,
  logo_url       TEXT,
  status         TEXT        DEFAULT 'new' CHECK (status IN ('new', 'review', 'dispatched', 'closed')),
  admin_notes    TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── ACTIVITY LOGS ──────────────────────────────────────────
CREATE TABLE public.activity_logs (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id    UUID        REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  action      TEXT        NOT NULL,
  old_status  TEXT,
  new_status  TEXT,
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── AUTO-UPDATE updated_at ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ── ROW LEVEL SECURITY ─────────────────────────────────────
ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Helper: is the current user an admin?
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- PROFILES
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT USING (public.is_admin());

-- ORDERS
CREATE POLICY "Users can insert own orders"
  ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own orders"
  ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all orders"
  ON public.orders FOR SELECT USING (public.is_admin());
CREATE POLICY "Admins can update any order"
  ON public.orders FOR UPDATE USING (public.is_admin());

-- ACTIVITY LOGS
CREATE POLICY "Admins can insert logs"
  ON public.activity_logs FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "Admins can view logs"
  ON public.activity_logs FOR SELECT USING (public.is_admin());

-- ── STORAGE BUCKET ──────────────────────────────────────────
-- Run separately in Supabase Dashboard → Storage:
-- 1. Create bucket named "logos" (private)
-- 2. Add policy: allow authenticated users to upload their own logos
--
-- Storage RLS (paste into Storage → Policies → logos bucket):
--
-- INSERT policy:
--   ( (storage.foldername(name))[1] = auth.uid()::text )
--
-- SELECT policy:
--   ( public.is_admin() OR (storage.foldername(name))[1] = auth.uid()::text )
