// ─── FIRM CONFIGURATION ──────────────────────────────────────────────────────
// The single file to edit when deploying this codebase for a new law firm.
// Every screen, email header, and generated Word document reads from here.
//
// Not stored here: Make.com webhook URLs and Supabase keys. Those are secrets
// and are set per deployment as environment variables (see .env.example).

export const firm = {
  // ── Firm details ──────────────────────────────────────────────────────────
  name: 'WKO Intelligence',
  tagline: 'Estate Planning Intake',
  email: 'warrren10.ocampo@gmail.com',
  phone: '',                       // leave empty to hide the phone line
  address: '[Firm address]',
  website: 'https://intake.wkointelligence.com',

  // ── Branding ──────────────────────────────────────────────────────────────
  colors: {
    primary: '#C41E3A',
    primaryDark: '#A01729',
    primaryLight: '#E94D63',
    secondary: '#c9953a',
    secondaryLight: '#ddb96a',
  },
  images: {
    logo: '',                       // e.g. '/logo.png' in public/. Empty shows the firm name as text.
    hero: '/hero.jpg',
  },

  // ── CRM / automation ──────────────────────────────────────────────────────
  // Which CRM the completed-form and document hand-off targets.
  // The matching webhook URLs are set in environment variables.
  crm: {
    provider: 'clio' as 'clio' | 'smokeball' | 'none',
  },
} as const;

export type FirmConfig = typeof firm;
