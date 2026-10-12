// Make.com webhook endpoints. Every value comes from an environment variable:
//   local:    artifacts/questionnaire/.env.local
//   deployed: Vercel → Project → Settings → Environment Variables
// There are deliberately no hardcoded fallbacks, so client data can't reach another firm's Make scenario.

export const WEBHOOKS = {
  smokeball: import.meta.env.VITE_WEBHOOK_URL ?? '',
  sendFormEmail: import.meta.env.VITE_SEND_FORM_EMAIL_WEBHOOK ?? '',
  reminder: import.meta.env.VITE_REMINDER_WEBHOOK ?? '',
  emailConfirmation: import.meta.env.VITE_EMAIL_CONFIRMATION_WEBHOOK ?? '',
  sendBack: import.meta.env.VITE_SEND_BACK_WEBHOOK ?? '',
  sendInquiryForm: import.meta.env.VITE_SEND_INQUIRY_FORM_WEBHOOK ?? '',
  sendIntakeForm: import.meta.env.VITE_SEND_INTAKE_FORM_WEBHOOK ?? '',
  clio: import.meta.env.VITE_CLIO_WEBHOOK ?? '',
};

const missing = Object.entries(WEBHOOKS)
  .filter(([, url]) => !url)
  .map(([name]) => name);

if (missing.length > 0) {
  console.warn('Webhook env vars not set:', missing.join(', '));
}
