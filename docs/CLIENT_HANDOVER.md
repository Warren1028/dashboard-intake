# Client Handover Guide

Use this when a law firm buys the intake system. Work through it in order. Each firm gets its own copy of the repo, its own Supabase project, its own Make scenarios, and its own Vercel deployment.

Before you start, read [CLAUDE.md](../CLAUDE.md) for how the code is organised, and [docs/SETUP.md](SETUP.md) and [docs/SUPABASE.md](SUPABASE.md) for the detailed steps.

---

## Part 1: Before the first meeting

- [ ] Agree the scope: which forms, which CRM (Clio, Smokeball, or none), and who the users are (admins and lawyers).
- [ ] Collect from the firm:
  - Firm name, tagline, email, phone, address, website
  - Logo (PNG or SVG, transparent background)
  - Brand colours (primary, dark, light, and a secondary accent)
  - Lawyer names and emails, exactly as they should appear in the "Person responsible" dropdown
  - Which Word templates they use (the document generator ships with the standard set)
- [ ] Confirm the firm's domain, for example `intake.<firm>.com.au`.
- [ ] Check that the firm has accounts for Vercel, GitHub, Supabase, and Make, or agree who will create them.

## Part 2: Create the firm's copy of the code

1. Create a new GitHub repository for the firm, for example `<firm>-intake`. Keep it private.
2. Copy the master template:
   ```bash
   git clone https://github.com/Warren1028/dashboard-intake.git <firm>-intake
   cd <firm>-intake
   git remote set-url origin https://github.com/<org>/<firm>-intake.git
   git push -u origin main
   ```
3. Do not carry over the demo data (`supabase_demo_data.sql`). Delete it from the firm's copy.
4. Check that the repo has no `.env` files: `git ls-files | grep -i env` should show only `.env.example`.

## Part 3: Configure the firm

1. Edit `artifacts/questionnaire/src/config/firm.config.ts`:
   - `name`, `tagline`, `email`, `phone` (leave empty to hide), `address`, `website`
   - `colors`: primary, primaryDark, primaryLight, secondary, secondaryLight
   - `images.logo`: for example `'/logo.png'`. Leave empty to show the firm name as text.
   - `crm.provider`: `'clio'`, `'smokeball'`, or `'none'`
2. Replace `artifacts/questionnaire/public/logo.png` with the firm's logo. Use `favicon.svg`, or replace it too.
3. Update the firm details in `api/generate-document.ts` if they changed. These come from the same config file, so this should be automatic.
4. Commit and push.

## Part 4: Supabase

Follow [docs/SUPABASE.md](SUPABASE.md). In short:

- [ ] Create a new project in the firm's region. Save the database password.
- [ ] Run `supabase_schema.sql` in the SQL Editor. Check that the last query lists 12 policies.
- [ ] Create each lawyer as an Auth user, with **Auto Confirm** on, then insert a matching row in `lawyers`. Use the exact names from the dropdown and set `is_admin` for admins.
- [ ] Set Authentication → URL Configuration: Site URL and Redirect URLs use the firm's domain.
- [ ] Copy the Project URL, the anon key, and the service role key. Keep the service role key secret.
- [ ] **Do not** run `supabase_demo_data.sql`.

## Part 5: Make.com

The blueprints in the repo root (`Email Confirmation`, `Sending Intake Form`, `Sending Reminders`) are starting points. They were built for an earlier firm.

- [ ] Import each blueprint into the firm's Make organisation.
- [ ] Review each one. Change the sender name, email wording, and firm details to match this firm.
- [ ] Connect the email, Clio or Smokeball, and any other modules to the firm's own accounts.
- [ ] Copy each scenario's webhook URL into the matching variable (table in Part 6).
- [ ] Test each scenario with one real submission before go-live.

## Part 6: Vercel

Follow section 7 of [docs/SETUP.md](SETUP.md). In short:

1. **Add New → Project**, import the firm's repo.
2. Root Directory: **`./`** (the repo root). Do not select `artifacts/questionnaire`.
3. Preset: **Other**. Leave Build, Output, and Install settings as defined in `vercel.json`, except set the Install Command to `pnpm install`.
4. Add these environment variables for Production and Preview:

| Variable | Value |
|---|---|
| `VITE_SUPABASE_URL` | Supabase Project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase anon key |
| `SUPABASE_URL` | Supabase Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (server only, never `VITE_`) |
| `APP_URL` | The firm's public domain, `https://...` |
| `SKIP_PDF_GENERATION` | `true` unless LibreOffice is available |
| `VITE_WEBHOOK_URL` | Make: completed form and CRM send |
| `VITE_SEND_FORM_EMAIL_WEBHOOK` | Make: form link email |
| `VITE_REMINDER_WEBHOOK` | Make: overdue reminders |
| `VITE_EMAIL_CONFIRMATION_WEBHOOK` | Make: client confirmation |
| `VITE_SEND_BACK_WEBHOOK` | Make: send-back email |
| `VITE_SEND_INQUIRY_FORM_WEBHOOK` | Make: inquiry submitted |
| `VITE_SEND_INTAKE_FORM_WEBHOOK` | Make: intake sent |
| `VITE_CLIO_WEBHOOK` | Make: dashboard to Clio |
| `MAKE_CLIO_MULTIPART_WEBHOOK` | Make: document upload to Clio (server only) |

5. Click **Deploy**.
6. Add the firm's domain under **Settings → Domains**, follow Vercel's DNS steps, then redeploy.
7. Any change to a `VITE_` variable needs a redeploy, because Vite reads it at build time.

## Part 7: Test before handover

Run through this list on the live site, with a real lawyer account and a test client.

- [ ] Sign in as a lawyer. The name shows correctly in the top right.
- [ ] Create a lead in the screening form. It appears under Pending Leads with the right lawyer.
- [ ] Qualify the lead. It moves to Pending on the Intake board.
- [ ] Open **View** on the Pending form. The inquiry answers show, and **Send Intake Form** is there.
- [ ] Click **Send Intake Form**. The form moves to Sent. The intake answers show, and there's no button.
- [ ] Open the intake link from the email. Save one answer. The form moves to In Progress.
- [ ] Complete the intake. The form moves to Completed.
- [ ] Generate a document from the Completed form. The firm's details appear in the Word file.
- [ ] Send a form back. Delete a lead. Both work.
- [ ] The lawyer dropdowns list the firm's lawyers, and no one else.
- [ ] No "WKO" or St Ives text is visible anywhere.
- [ ] The Make scenarios received the test submissions.

## Part 8: Handover

- [ ] Transfer ownership of the GitHub repo, Vercel project, Supabase project, and Make organisation to the firm, or agree how you'll access them.
- [ ] Rotate every key that was used during setup, and store the new keys in the firm's password manager.
- [ ] Give the firm an admin login. Delete the test users (`test@test.com` and any sample lawyers).
- [ ] Hand over this checklist, `docs/SETUP.md`, and `docs/SUPABASE.md`.
- [ ] Agree the support route for changes: what you change, and what the firm changes themselves.

---

## Known limits to tell the client

- **Webhook buttons:** the Make-backed buttons do nothing until their webhook variable is set. Set them all before go-live.
- **Sign-up:** a new lawyer can't claim a `lawyers` row that an admin created with a different id. Create lawyer accounts through Auth, then insert the row with that id (see [docs/SUPABASE.md](SUPABASE.md)).
- **Forms table history:** changes to a form overwrite the previous answers. There is no version history.
- **Lead reassignment:** a lawyer can reassign their own forms to another lawyer. Tighten the policy if that matters.
- **Document generator:** the templates are the standard estate planning set. Custom templates need the Word files replaced in `api/templates/`.
- **Demo-only code:** remove any leftover demo-mode code before go-live. The current build has none, but check after any change.
- **Smokeball naming:** some functions are still named Smokeball but forward to Make. This doesn't affect behaviour.

## Things that never go to a client

- `supabase_demo_data.sql` and any demo users
- Your own Supabase, Make, or Vercel logins
- The `_legacy/` folder on your machine (St Ives material and old code)
- Any key or password that was pasted into chat or into a file
