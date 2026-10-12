# Supabase Setup

One Supabase project per firm. Don't share a project between firms.

## 1. Create the project

1. Go to supabase.com → **New project**.
2. Choose a name (for example `wko-intake-demo`), a strong database password (save it in your password manager), and the region closest to the firm (Sydney for Australian firms).
3. Wait for the project to finish provisioning.

## 2. Copy the three keys

Go to **Project Settings → API**:

| Key | Where it goes | Secret? |
|---|---|---|
| Project URL | `VITE_SUPABASE_URL` and `SUPABASE_URL` | No |
| `anon` `public` key | `VITE_SUPABASE_ANON_KEY` | No. The browser uses it, and RLS limits what it can do. |
| `service_role` key | `SUPABASE_SERVICE_ROLE_KEY` only | **Yes.** Bypasses RLS. Set it in Vercel and `.env.local`. Never put it in a `VITE_` variable or commit it. |

## 3. Create the tables

1. Open **SQL Editor → New query**.
2. Paste the full contents of `supabase_schema.sql` from the repo root and click **Run**.
3. The last query lists the policies. You should see 12 rows across `forms`, `lawyers`, and `screening_submissions`.

The script is safe to re-run.

## 4. Tables

### `lawyers`

One row per lawyer who can sign in to the dashboard.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Same as the Supabase Auth user id once the lawyer has signed up |
| `email` | text, unique | |
| `full_name` | text | Used to match the "Person responsible" dropdown. Must match exactly. |
| `is_admin` | boolean | Admins see all leads and forms, and can qualify leads |
| `created_at`, `updated_at` | timestamptz | |

### `screening_submissions`

Leads from the screening form, before they are qualified.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `lawyer_id` | uuid → `lawyers.id` | Lawyer the lead is assigned to |
| `contact_type` | text | `person` or `firm` |
| `contact_data` | jsonb | Name, email, mobile, and other fields from the form |
| `client_name`, `client_email` | text | Used for firm contacts |
| `lead_type`, `region`, `referral_type`, `billing_type`, `person_responsible` | text | Copied to the form when the lead is qualified |
| `status` | text | `pending`, `qualified`, `rejected`, or `deprioritized` |

### `forms`

One row per client intake, created when a lead is qualified.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | Used in form links as `lead_id` |
| `lawyer_id` | uuid → `lawyers.id` | |
| `client_name`, `client_email` | text | |
| `lead_type`, `region`, `referral_type`, `billing_type`, `person_responsible` | text | |
| `status` | text | Flow: `appointment_sent` → `scheduled` → `pending_intake` → `completed_intake` → `submitted`. Also `completed`, `overdue`, `deprioritized`. |
| `progress_pct` | int | 0 to 100 |
| `form_data` | jsonb | `{ "inquiry": {...}, "intake": {...}, "metadata": {...} }` |
| `unique_link` | text, unique | Random token for the client's form link |
| `last_accessed` | timestamptz | |
| `reminder_3d_sent`, `reminder_1w_sent`, `reminder_2w_sent` | timestamptz | Set when each reminder is sent |
| `marked_complete_at`, `submitted_at` | timestamptz | |

## 5. How access works

- **Lawyers** sign in with Supabase Auth in the browser. The `authenticated` role can read and change only their own leads and forms. Admins can access everything.
- **Public pages** (`/lead-inquiry`, `/intake-form`) call the `/api` functions. Those functions use the service role key on the server. The public browser code never reads or writes `forms` directly.
- **Anon key** can read only `lawyers.id` and `lawyers.full_name`, which the sign-up page needs. Emails stay private.

## 6. Authentication settings

Go to **Authentication**:

1. **Providers → Email**: enabled.
2. **Sign In / Providers → Confirm email**: keep on, so new lawyers verify their address. Turn it off only for testing.
3. **URL Configuration**:
   - **Site URL**: the firm's public domain, for example `https://intake.wkointelligence.com`
   - **Redirect URLs**: add the same domain, plus `http://localhost:3000` for local testing.

## 7. Create the first admin

Use the sign-up page for the first admin, or create the user directly:

1. Go to **Authentication → Users → Add user → Create new user**. Enter the admin's email and a password, and tick **Auto Confirm User**.
2. Copy the new user's **UID**.
3. In **SQL Editor**, run:

```sql
insert into lawyers (id, email, full_name, is_admin)
values ('<paste the UID here>', 'admin@firm.com', 'Admin Name', true);
```

4. Add other lawyers the same way, with `is_admin = false`. Use each lawyer's exact name as it appears in the "Person responsible" dropdown.

**Note:** Sign-up can't claim a `lawyers` row that an admin created earlier with a different id. The row-level security rules only let a lawyer edit their own row. Create lawyer rows with their Auth user id, as above.

## 8. Set the Vercel environment variables

In Vercel → Project → Settings → Environment Variables, add these for Production, Preview, and Development:

```
VITE_SUPABASE_URL          = https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY     = <anon public key>
SUPABASE_URL              = https://<project-ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY = <service_role key>
```

Then redeploy. Vite reads the `VITE_` values at build time, so a redeploy is required.

## 9. Test

1. Open `/` and sign in as the admin. The dashboard should load with no errors.
2. Create a test lead in the screening form, qualify it, and check that a row appears in `forms` with status `appointment_sent`.
3. Open `/lead-inquiry?lead_id=<forms.id>` and submit it. The status should change to `scheduled`.
4. Open `/intake-form?lead_id=<forms.id>`, answer a question, and wait a moment. Then check `form_data` in the Table Editor.

If a step fails, check **Logs** in Supabase and the Vercel function logs.

## 10. Security checklist

- [ ] The `service_role` key appears only in Vercel and `.env.local`, not in any `VITE_` variable
- [ ] The Supabase keys from the old St Ives project are rotated or the project is deleted
- [ ] Row-level security is enabled on `lawyers`, `screening_submissions`, and `forms` (the schema script does this)
- [ ] The demo login in `LoginPage.tsx` (`test@test.com`) is removed before a real client goes live
- [ ] Email confirmation is on for lawyer sign-ups

## Known limits

- A lawyer can reassign one of their own forms to another lawyer. The policy doesn't check `lawyer_id` on update. Tighten it if that matters for the firm.
- The `forms` table has no history table. Changes to `form_data` overwrite the previous value.
