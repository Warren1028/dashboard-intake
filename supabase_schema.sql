-- ─── WKO Intelligence intake: database schema ──────────────────────────────
-- Run once in the Supabase SQL Editor for each new firm project.
-- Safe to re-run: uses IF NOT EXISTS and DROP POLICY IF EXISTS.
--
-- Tables: lawyers, screening_submissions, forms
-- Access model:
--   * Lawyers (signed in with Supabase Auth) see their own records. Admins see all.
--   * Public pages (inquiry and intake) and Make.com never touch these tables directly.
--     They go through the /api functions, which use the service role key and bypass RLS.

-- ─── Helper: updated_at trigger ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ─── lawyers ────────────────────────────────────────────────────────────────
-- id matches auth.users.id for lawyers who have signed up.
-- Lawyers pre-created by an admin get a generated id until they sign up.
CREATE TABLE IF NOT EXISTS lawyers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email      TEXT UNIQUE,
  full_name  TEXT NOT NULL,
  is_admin   BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS lawyers_updated_at ON lawyers;
CREATE TRIGGER lawyers_updated_at BEFORE UPDATE ON lawyers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ─── screening_submissions ──────────────────────────────────────────────────
-- Leads captured by the screening form, before they are qualified.
CREATE TABLE IF NOT EXISTS screening_submissions (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lawyer_id          UUID REFERENCES lawyers(id) ON DELETE SET NULL,
  contact_type       TEXT NOT NULL CHECK (contact_type IN ('person', 'firm')),
  contact_data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  client_name        TEXT,
  client_email       TEXT,
  lead_type          TEXT,
  region             TEXT,
  person_responsible TEXT,
  referral_type      TEXT,
  billing_type       TEXT,
  status             TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'qualified', 'rejected', 'deprioritized')),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS screening_submissions_updated_at ON screening_submissions;
CREATE TRIGGER screening_submissions_updated_at BEFORE UPDATE ON screening_submissions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ─── forms ──────────────────────────────────────────────────────────────────
-- One row per client intake. Created when a lead is qualified.
-- form_data holds the inquiry and intake answers: {"inquiry": {...}, "intake": {...}, "metadata": {...}}
CREATE TABLE IF NOT EXISTS forms (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lawyer_id           UUID REFERENCES lawyers(id) ON DELETE SET NULL,
  client_name         TEXT NOT NULL,
  client_email        TEXT,
  lead_type           TEXT,
  region              TEXT,
  referral_type       TEXT,
  billing_type        TEXT,
  person_responsible  TEXT,
  status              TEXT NOT NULL DEFAULT 'appointment_sent'
                      CHECK (status IN (
                        'appointment_sent', 'scheduled', 'pending_intake', 'overdue',
                        'completed', 'completed_intake', 'submitted', 'deprioritized'
                      )),
  progress_pct        INT NOT NULL DEFAULT 0 CHECK (progress_pct BETWEEN 0 AND 100),
  form_data           JSONB NOT NULL DEFAULT '{}'::jsonb,
  unique_link         TEXT NOT NULL UNIQUE,
  last_accessed       TIMESTAMPTZ NOT NULL DEFAULT now(),
  reminder_3d_sent    TIMESTAMPTZ,
  reminder_1w_sent    TIMESTAMPTZ,
  reminder_2w_sent    TIMESTAMPTZ,
  marked_complete_at  TIMESTAMPTZ,
  submitted_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS forms_updated_at ON forms;
CREATE TRIGGER forms_updated_at BEFORE UPDATE ON forms
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ─── Indexes ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_lawyers_full_name             ON lawyers (full_name);
CREATE INDEX IF NOT EXISTS idx_screening_lawyer              ON screening_submissions (lawyer_id);
CREATE INDEX IF NOT EXISTS idx_screening_status              ON screening_submissions (status);
CREATE INDEX IF NOT EXISTS idx_screening_email               ON screening_submissions ((contact_data->>'email'));
CREATE INDEX IF NOT EXISTS idx_forms_lawyer                  ON forms (lawyer_id);
CREATE INDEX IF NOT EXISTS idx_forms_status                  ON forms (status);
CREATE INDEX IF NOT EXISTS idx_forms_created_at              ON forms (created_at DESC);

-- ─── Row-level security ─────────────────────────────────────────────────────
ALTER TABLE lawyers               ENABLE ROW LEVEL SECURITY;
ALTER TABLE screening_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE forms                 ENABLE ROW LEVEL SECURITY;

-- True when the signed-in user is an admin. SECURITY DEFINER avoids recursion
-- when the policies on lawyers look up lawyers.
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM lawyers WHERE id = auth.uid() AND is_admin);
$$;

-- Clean slate: drop any policies from earlier versions of this file.
DROP POLICY IF EXISTS "public_submit_form"          ON forms;
DROP POLICY IF EXISTS "lawyers_select_authenticated" ON lawyers;
DROP POLICY IF EXISTS "lawyers_select_anon"          ON lawyers;
DROP POLICY IF EXISTS "lawyers_insert_own"           ON lawyers;
DROP POLICY IF EXISTS "lawyers_update_own"           ON lawyers;
DROP POLICY IF EXISTS "screening_select"             ON screening_submissions;
DROP POLICY IF EXISTS "screening_insert"             ON screening_submissions;
DROP POLICY IF EXISTS "screening_update"             ON screening_submissions;
DROP POLICY IF EXISTS "screening_delete"             ON screening_submissions;
DROP POLICY IF EXISTS "forms_select"                 ON forms;
DROP POLICY IF EXISTS "forms_insert"                 ON forms;
DROP POLICY IF EXISTS "forms_update"                 ON forms;
DROP POLICY IF EXISTS "forms_delete"                 ON forms;

-- lawyers: any signed-in lawyer can read the list (needed for assignment dropdowns).
-- Only the lawyer themselves (or an admin) can change their own row.
CREATE POLICY "lawyers_select_authenticated" ON lawyers
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "lawyers_insert_own" ON lawyers
  FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
CREATE POLICY "lawyers_update_own" ON lawyers
  FOR UPDATE TO authenticated
  USING (id = auth.uid() OR is_admin())
  WITH CHECK (id = auth.uid() OR is_admin());

-- Sign-up looks up a lawyer by full_name before the user is signed in,
-- so anon may read id and full_name only. Email stays private.
REVOKE SELECT ON lawyers FROM anon;
GRANT SELECT (id, full_name) ON lawyers TO anon;
CREATE POLICY "lawyers_select_anon" ON lawyers
  FOR SELECT TO anon USING (true);

-- screening_submissions and forms: a lawyer sees and changes their own
-- records. Admins see and change everything. Any signed-in lawyer can create
-- a record, because screening assigns leads to other lawyers.
CREATE POLICY "screening_select" ON screening_submissions
  FOR SELECT TO authenticated USING (lawyer_id = auth.uid() OR is_admin());
CREATE POLICY "screening_insert" ON screening_submissions
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "screening_update" ON screening_submissions
  FOR UPDATE TO authenticated USING (lawyer_id = auth.uid() OR is_admin())
  WITH CHECK (true);
CREATE POLICY "screening_delete" ON screening_submissions
  FOR DELETE TO authenticated USING (lawyer_id = auth.uid() OR is_admin());

CREATE POLICY "forms_select" ON forms
  FOR SELECT TO authenticated USING (lawyer_id = auth.uid() OR is_admin());
CREATE POLICY "forms_insert" ON forms
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "forms_update" ON forms
  FOR UPDATE TO authenticated USING (lawyer_id = auth.uid() OR is_admin())
  WITH CHECK (true);
CREATE POLICY "forms_delete" ON forms
  FOR DELETE TO authenticated USING (lawyer_id = auth.uid() OR is_admin());

-- No policies for anon on screening_submissions or forms.
-- The /api functions use the service role key, which bypasses RLS.

-- ─── Verify ─────────────────────────────────────────────────────────────────
SELECT tablename, policyname, roles, cmd
FROM pg_policies
WHERE tablename IN ('lawyers', 'screening_submissions', 'forms')
ORDER BY tablename, policyname;
