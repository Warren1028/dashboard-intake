# WKO Intelligence: Intake Dashboard (white-label master template)

**Purpose**: Intake system for law firms. Covers the public lead inquiry, the estate planning intake questionnaire, a lawyer dashboard, and Word document generation.

**Model**: This repo is the master template. WKO Intelligence owns it. Each firm that buys the system gets a cloned repo and its own Vercel deployment. Firm-specific values live in one file.

**Repo**: https://github.com/Warren1028/dashboard-intake
**Demo site**: https://intake.wkointelligence.com
**Current date**: 2026-10-12

## Stack

- **Frontend**: React 19, TypeScript, Vite 7, Tailwind CSS 4 (`artifacts/questionnaire`)
- **Standalone forms**: static HTML in `artifacts/questionnaire/public/`
- **Serverless API**: Vercel Functions in `api/`
- **Database and auth**: Supabase (PostgreSQL, email/password auth)
- **Documents**: docxtemplater and pizzip (`.docx`), optional LibreOffice (PDF)
- **Automation**: Make.com webhooks (emails, reminders, CRM hand-off)
- **Hosting**: Vercel. `vercel.json` builds `artifacts/questionnaire` into `dist`.
- **Package manager**: pnpm only. The root `preinstall` rejects npm and yarn.

## Commands

```bash
pnpm install
cd artifacts/questionnaire
pnpm run dev         # http://localhost:3000
pnpm run build       # production build to dist/
pnpm run typecheck   # reports pre-existing errors, see Known issues
```

## Firm configuration (single source of truth)

**`artifacts/questionnaire/src/config/firm.config.ts`** holds every firm-specific value:

- `name`, `tagline`, `email`, `phone`, `address`, `website`
- `colors`: primary, primaryDark, primaryLight, secondary, secondaryLight
- `images`: logo and hero paths in `public/`
- `crm.provider`: `'clio' | 'smokeball' | 'none'`

Consumers of this file:
- `src/constants/colors.js` (the `C` brand object used across the UI)
- `src/main.tsx` (sets `--firm-*` CSS variables used by `dashboard.css`)
- `src/pages/DashboardV2.tsx`, `LoginPage.tsx`, `ScreeningForm.tsx` (logo and name)
- `src/lib/templates.ts` (`FIRM_INFO`)
- `api/generate-document.ts` (Word document `Firm.*` variables)
- `vite.config.ts` (fills `__FIRM_NAME__` into `index.html` at build and dev time)

**Rule**: don't hardcode a firm name, colour, or logo anywhere else. Import from `firm.config.ts`.

Secrets and per-deployment URLs are **not** in this file. They are environment variables (see below).

## Environment

Templates are in `artifacts/questionnaire/.env.example`. Never commit `.env*` files; `.gitignore` excludes them.

- `VITE_*` values are bundled into the browser. Never put secrets in them.
- Server functions read the same names through `process.env`. Vercel sets both.

Required: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `APP_URL`.
Webhooks (frontend): `VITE_WEBHOOK_URL`, `VITE_SEND_FORM_EMAIL_WEBHOOK`, `VITE_REMINDER_WEBHOOK`, `VITE_EMAIL_CONFIRMATION_WEBHOOK`, `VITE_SEND_BACK_WEBHOOK`, `VITE_SEND_INQUIRY_FORM_WEBHOOK`, `VITE_SEND_INTAKE_FORM_WEBHOOK`, `VITE_CLIO_WEBHOOK`.
Webhooks (server): `MAKE_CLIO_MULTIPART_WEBHOOK`.

Webhook URLs are read in `src/config/webhooks.ts`. **Don't add fallback URLs.** A fallback can send client data to another firm's Make scenario. Missing values are logged to the console as `Webhook env vars not set`.

## Structure

```
api/                          Vercel functions
  submit-form.js                save inquiry data (POST)
  submit-intake.js              save intake data (POST)
  get-form.js                   load saved form data (GET)
  send-back-form.js             send a form back to the client by email (POST)
  validate-intake.js            server-side intake validation
  generate-document.ts          build .docx (and optional PDF) from a form (POST)
  send-to-clio-multipart.ts     forward a generated document to Make for Clio (POST)
  document-processor.ts         shared template and PDF helpers
  templates/                    .docx templates

artifacts/questionnaire/
  index.html                    dashboard entry (title filled from firm config)
  public/intake-form.html       intake questionnaire (/intake-form)
  public/lead-inquiry.html      lead inquiry (/lead-inquiry)
  src/AppRouter.tsx             routes: dashboard, login, sign-up, screening, email verification
  src/pages/                    DashboardV2 (main), LoginPage, SignUp, ScreeningFormV2, EmailVerification
  src/lib/dashboard-actions.ts  dashboard actions (send, remind, delete, complete)
  src/config/firm.config.ts     firm settings (edit per client)
  src/config/webhooks.ts        webhook URLs from env

supabase_schema.sql           base tables
supabase_rls_public_forms.sql row-level security for public form access
vercel.json                   build, output, rewrites
```

The live intake questionnaire is `public/intake-form.html`. It is the only copy of the form in the repo.

Retired code, old documents, and St Ives data are kept in `_legacy/` on the owner's machine. Git ignores that folder, so it never reaches a client repo.

## Data model

**lawyers**: `id`, `email` (unique), `full_name`, `is_admin`, `created_at`

**screening_submissions**: `id`, `lawyer_id`, `contact_type` (`person` | `firm`), `contact_data` (JSONB), `lead_type`, `region`, `person_responsible`, `referral_type`, `billing_type`, `status` (`pending` | `qualified` | `rejected` | `deprioritized`)

**forms**: `id`, `lawyer_id`, `client_name`, `client_email`, `lead_type`, `region`, `referral_type`, `billing_type`, `person_responsible`, `status`, `form_data` (JSONB), `progress_pct`, `unique_link`, `last_accessed`, `reminder_3d_sent`, `reminder_1w_sent`, `reminder_2w_sent`, `marked_complete_at`, `submitted_at`, `created_at`, `updated_at`

Form status flow: `appointment_sent` → `scheduled` → `pending_intake` → `completed_intake` → `submitted`. Any active status can go to `deprioritized`.

## Workflow

1. **Lead created**: staff add a lead in the screening form. Status `pending`.
2. **Qualify** (admin): creates a form with status `appointment_sent` and emails the client a link.
3. **Inquiry** (`/lead-inquiry?lead_id=...`): the client answers the qualifying questions. Non-qualifying answers save partial data. Qualifying submissions move the form to `scheduled`.
4. **Intake** (`/intake-form?lead_id=...`): the client completes the questionnaire. Progress auto-saves through `/api/submit-intake`. The form loads through `/api/get-form`.
5. **Documents**: the lawyer generates a `.docx` from the form. `generate-document` returns it, with a PDF if LibreOffice is available. It can be forwarded to Clio through Make.

Old links to `/?formId=` or `?uniqueLink=` redirect to `/intake-form?lead_id=` (see `FormRedirect` in `AppRouter.tsx`).

## Known issues

- `pnpm run typecheck` reports about 21 errors that predate the template work: implicit `any` in `.jsx` imports, possibly-null `lawyer` in `DashboardV2.tsx`, and a missing `Submission` export in `lib/supabase`.
- **Demo-mode bypass** in `AppRouter.tsx`: `localStorage.supabase_user_id === 'demo-user-id'` skips the session check. Remove before a client goes live.
- The code still uses Smokeball-named functions (`submitFormToSmokeball`, `sendToSmokeball`). They forward to Make. Confirm the target CRM before renaming, and set `crm.provider` to match.
- Logo files in `public/` (`logo.png`, `nautilus-logo.png`, `nautilus-hero.jpg`, `opengraph.jpg`) are placeholders from earlier firms. Replace them per deployment.
- `public/intake-form.html` and `public/lead-inquiry.html` are static and don't read `firm.config.ts`. They contain no firm name, but any future firm-specific text in them must be added by hand.
- Some non-brand UI colours are still hardcoded in components (for example `#4a8fa0`, `#dc3545`). They are generic accents, not firm colours.
- Firm address is a placeholder: `[Firm address]`.
- `artifacts/api-server/` and `lib/db/` belong to a Replit setup and are not used by the Vercel deployment.

## Deployment

Vercel project connected to the firm's repo. Build command, output directory, and rewrites are in `vercel.json`. Environment variables are set in the Vercel project, never in the repo. See `docs/SETUP.md`.
