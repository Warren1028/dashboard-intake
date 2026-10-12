// ─── BRAND TOKENS ─────────────────────────────────────────────────────────
// Brand values come from src/config/firm.config.ts. Edit that file, not this one.

import { firm } from "../config/firm.config";

export const C = {

  // ── Core brand colours (from website) ──────────────────────────────────────
  teal:       firm.colors.primary,
  tealD:      firm.colors.primaryDark,
  tealL:      firm.colors.primaryLight,
  bg:         "#fafafa",   // clean white background
  bgD:        "#f0f0f0",
  bgBorder:   "#e0e0e0",
  white:      "#ffffff",
  slate:      "#666666",
  slateL:     "#999999",
  slatePale:  "#f5f5f5",

  // ── Website button / text dark ──────────────────────────────────────────────
  charcoal:   "#1a1a1a",   // dark text colour
  charcoalL:  "#4a4a4a",

  // ── Accent (red from branding) ─────────────────────────────────────────────
  warm:       firm.colors.primary,
  warmL:      firm.colors.primaryLight,
  warmPale:   "#fce8ed",
  amber:      firm.colors.primaryDark,

  // ── Typography colours ──────────────────────────────────────────────────────
  text:       "#2b2b2b",
  textL:      "#5a6e74",
  border:     "#b8d8db",

  // ── Status colours ──────────────────────────────────────────────────────────
  red:        "#8B3A3A",
  green:      "#2A6B4A",
  greenL:     "#EAF5EE",

  // ── Typography ──────────────────────────────────────────────────────────────
  fontHeading: "'Comfortaa', 'Open Sans', Helvetica, Arial, sans-serif",
  fontBody:    "'Source Sans 3', 'Open Sans', Helvetica, Arial, sans-serif",
  fontAccent:  "'Open Sans', Helvetica, Arial, Lucida, sans-serif",

  // ── Font sizes ───────────────────────────────────────────────────────────────
  sizeXs:     "10px",
  sizeSm:     "12px",
  sizeBase:   "13px",
  sizeMd:     "15px",
  sizeLg:     "18px",
  sizeXl:     "22px",
  sizeHero:   "28px",

  // ── Letter spacing ──────────────────────────────────────────────────────────
  trackingWide:   "0.08em",
  trackingXWide:  "0.15em",

  // ── Logo & imagery ───────────────────────────────────────────────────────────
  logoUrl:    firm.images.logo,
  logoAlt:    firm.name,
  heroUrl:    firm.images.hero,
};
