# WKO Intelligence — Intake Dashboard

White-label intake system for law firms. It covers the public lead inquiry, the estate planning intake questionnaire, a lawyer dashboard, and Word document generation from intake data.

This repository is the **master template**. Each law firm gets its own copy and deployment. All firm-specific settings live in one file: `artifacts/questionnaire/src/config/firm.config.ts`.

## What it does

- **Lead inquiry** (`/lead-inquiry`): a short qualifying form. Non-qualifying answers save partial data and show a follow-up message.
- **Intake questionnaire** (`/intake-form`): the full estate planning questionnaire. A completed form triggers a confirmation webhook.
- **Lawyer dashboard** (`/`): view leads and forms, send forms back to clients, and generate documents.
- **Document generation**: fills `.docx` templates from intake data. Returns a PDF when LibreOffice is available.
- **Automation**: Make.com webhooks send confirmation emails, reminders, and CRM (Clio) hand-offs.

## Stack

| Layer | Technology |
|---|---|
| Frontend | React 19, TypeScript, Vite 7, Tailwind CSS 4 |
| Standalone forms | Static HTML (`lead-inquiry.html`, `intake-form.html`) |
| Serverless API | Vercel Functions in `api/` |
| Database and auth | Supabase (PostgreSQL, email/password auth) |
| Documents | docxtemplater, pizzip, optional LibreOffice for PDF |
| Automation | Make.com webhooks |
| Hosting | Vercel |

## Repository layout

```
artifacts/questionnaire/
  src/config/firm.config.ts     ← firm name, contact, colours, logo, CRM flag (edit per client)
  src/constants/colors.js       brand tokens, read from firm.config.ts
  src/config/webhooks.ts        Make webhook URLs, read from environment variables
  src/AppRouter.tsx             client-side routes
  src/pages/                    dashboard, login, sign-up, screening form
  public/intake-form.html       intake questionnaire
  public/lead-inquiry.html      lead inquiry form
  public/logo.png               firm logo (replace per client)

api/                            Vercel functions
  submit-form.js                save inquiry data
  submit-intake.js              save intake data
  get-form.js                   load saved form data
  send-back-form.js             send a form back to the client
  generate-document.ts          build .docx (and optional PDF)
  send-to-clio-multipart.ts     forward a generated document to Make for Clio
  templates/                    .docx templates

supabase_schema.sql             base tables
supabase_rls_public_forms.sql   row-level security for public forms
vercel.json                     build, output, rewrites
```

## Quick start

See [docs/SETUP.md](docs/SETUP.md) for the full guide.

```bash
corepack enable
pnpm install
cd artifacts/questionnaire
cp .env.example .env.local     # then fill in the values
pnpm run dev                   # http://localhost:3000
```

## Client onboarding checklist

Three steps to spin up a new firm instance:

1. **Clone the repo** into a new repository for the firm, for example `github.com/WKO-Intelligence/<firm>-intake`. Don't push changes back to the master template.
2. **Update configuration**:
   - Edit `artifacts/questionnaire/src/config/firm.config.ts` with the firm's name, contact details, colours, logo path, and CRM provider.
   - Replace `artifacts/questionnaire/public/logo.png` with the firm's logo.
   - Create the firm's Supabase project and Make scenarios, then set the environment variables listed in `.env.example`.
3. **Deploy to Vercel**: import the new repo, add the environment variables, attach the firm's domain, and deploy. Full steps are in [docs/SETUP.md](docs/SETUP.md#6-deploy-to-vercel).

Then run the post-setup checklist in [docs/SETUP.md](docs/SETUP.md#post-setup-checklist).

## Environment variables

The full list with descriptions is in `artifacts/questionnaire/.env.example`. Never commit `.env*` files with real values.

Anything prefixed `VITE_` is bundled into the browser, so it must not hold secrets.

## Security notes

- Dashboard login uses Supabase Auth (email and password). Access to data depends on row-level security, so enable it on every table holding client data. See `supabase_rls_public_forms.sql`.
- `AppRouter.tsx` contains a demo-mode check based on `localStorage`. Remove it before a client goes live.
