# Setup Guide: Intake Dashboard

## 1. Prerequisites

- Node.js 20 or later
- pnpm. Run `corepack enable`; the version is pinned in `package.json`. The root `preinstall` rejects npm and yarn.
- A Supabase project for this instance
- A Vercel account with the repo connected
- A Make.com organisation with the webhook scenarios
- Optional: LibreOffice, for PDF output

## 2. Local install

```bash
git clone <your-repo-url>
cd <repo-folder>
corepack enable
pnpm install
```

## 3. Supabase

1. Create a project.
2. In the SQL editor, run `supabase_schema.sql`, then `supabase_rls_public_forms.sql`.
3. Copy the project URL and anon key from *Project Settings → API*.
4. Create the lawyer and admin accounts (see the `lawyers` table in `supabase_schema.sql`).

## 4. Configure the firm

Edit `artifacts/questionnaire/src/config/firm.config.ts`. This one file sets:

- firm name, tagline, email, phone, address, website
- brand colours (primary, dark, light, secondary)
- logo and hero image paths
- CRM provider (`clio`, `smokeball`, or `none`)

Replace `artifacts/questionnaire/public/logo.png` with the firm's logo. The file currently holds WKO Intelligence defaults.

## 5. Environment variables

Local: create `artifacts/questionnaire/.env.local` from `.env.example`.
Deployed: add the same names in Vercel (section 7).

| Name | Required | Read by | Value |
|---|---|---|---|
| `VITE_SUPABASE_URL` | Yes | Frontend | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Yes | Frontend | Supabase anon key |
| `SUPABASE_URL` | Yes | `api/*` | Same URL |
| `SUPABASE_ANON_KEY` | Yes | `api/*` | Same key |
| `APP_URL` | Yes | `api/send-back-form.js` | Public domain, for example `https://intake.wkointelligence.com` |
| `VITE_WEBHOOK_URL` | Yes | Frontend | Make: completed form and CRM send |
| `VITE_SEND_FORM_EMAIL_WEBHOOK` | Yes | Frontend | Make: form link email |
| `VITE_REMINDER_WEBHOOK` | Yes | Frontend | Make: overdue reminders |
| `VITE_EMAIL_CONFIRMATION_WEBHOOK` | Yes | Frontend | Make: client confirmation email |
| `VITE_SEND_BACK_WEBHOOK` | Yes | Frontend and `api/send-back-form.js` | Make: send-back email |
| `VITE_SEND_INQUIRY_FORM_WEBHOOK` | Yes | Frontend | Make: inquiry submission |
| `VITE_SEND_INTAKE_FORM_WEBHOOK` | Yes | Frontend | Make: intake submission |
| `VITE_CLIO_WEBHOOK` | Yes | Frontend | Make: dashboard to Clio |
| `MAKE_CLIO_MULTIPART_WEBHOOK` | Yes | `api/send-to-clio-multipart.ts` | Make: document upload to Clio (server only) |
| `SKIP_PDF_GENERATION` | No | `api/generate-document.ts` | `true` if LibreOffice is not installed |

If a webhook variable is missing, the browser console shows `Webhook env vars not set: <names>`, and the matching action fails. Set every variable the features you use need.

Do not reuse any value from another firm's deployment.

## 6. Run locally

```bash
cd artifacts/questionnaire
pnpm run dev        # http://localhost:3000
pnpm run build      # production build to dist/
```

To run the Vercel functions locally, install the CLI (`npm i -g vercel`), run `vercel link` in the repo root, then `vercel dev`.

## 7. Deploy to Vercel

### 7.1 Create the project

1. In Vercel, select **Add New → Project**.
2. Import the firm's repository.
3. Framework preset: **Other**. Leave the root directory as the repo root. `vercel.json` sets the build command and output directory.
4. Install command: `pnpm install` (override if Vercel picks npm).

### 7.2 Add environment variables

1. Open **Project → Settings → Environment Variables**.
2. For each variable in section 5, add the name and value, and select **Production**, **Preview**, and **Development**.
3. Set `APP_URL` to the firm's public domain. `VERCEL_URL` is the deployment hostname, not the custom domain, so form links need `APP_URL`.

### 7.3 Deploy and attach the domain

1. Click **Deploy**.
2. Open **Project → Settings → Domains**, add the firm's domain, and follow the DNS instructions Vercel shows.
3. After DNS verifies, redeploy so the custom domain is used.

### 7.4 Smoke test

- `/lead-inquiry` loads.
- `/intake-form` loads.
- The dashboard loads and login works.
- One inquiry submission reaches Supabase and the Make scenario.

If the build fails with "Use pnpm instead", the install command isn't using pnpm. Set it in the Vercel project settings.

## 8. Make.com

1. Import the blueprints from the repo root into the firm's Make organisation. Each scenario gets a new webhook URL.
2. Reconnect the email, Clio, and any other modules to the firm's accounts.
3. Copy each webhook URL into the matching variable in section 5, locally and in Vercel.
4. Test with one complete intake before going live.

## Post-setup checklist

- [ ] `firm.config.ts` values are final (address, phone, colours, logo, CRM provider)
- [ ] Logo, hero image, and OpenGraph image replaced in `artifacts/questionnaire/public/`
- [ ] Git history is fresh, and no `.env` files are tracked
- [ ] Demo-mode bypass in `AppRouter.tsx` removed
- [ ] Row-level security enabled on client data tables
- [ ] All webhook variables from section 5 set in Vercel
- [ ] Domain resolves with HTTPS
- [ ] One full flow tested: inquiry → intake → webhook → document
