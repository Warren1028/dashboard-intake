-- ─── Demo data for client presentations ─────────────────────────────────────
-- Run in the Supabase SQL Editor AFTER supabase_schema.sql and after creating
-- the lawyers (Test Admin, Sample Lawyer 1, Sample Lawyer 2).
-- Safe to re-run: removes only rows marked as demo, then inserts them again.
-- All names and emails are fictional (example.com).

-- 1. Remove earlier demo rows
DELETE FROM forms WHERE unique_link LIKE 'demo-%';
DELETE FROM screening_submissions WHERE contact_data->>'email' LIKE '%@example.com';

-- 2. Leads (screening_submissions)
INSERT INTO screening_submissions
  (lawyer_id, contact_type, contact_data, client_name, client_email,
   lead_type, region, person_responsible, referral_type, billing_type, status, created_at)
VALUES
  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 1'), 'person',
   '{"name":"Olivia Harper","email":"olivia.harper@example.com","mobile":"0400 111 222","title":"Ms"}',
   'Olivia Harper', 'olivia.harper@example.com', 'Direct', 'NSW', 'Sample Lawyer 1', 'Google', 'Fixed fee', 'pending', now() - interval '1 day'),

  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 2'), 'person',
   '{"name":"Daniel Brooks","email":"daniel.brooks@example.com","mobile":"0400 333 444","title":"Mr"}',
   'Daniel Brooks', 'daniel.brooks@example.com', 'Referral', 'VIC', 'Sample Lawyer 2', 'Accountant', 'Hourly', 'pending', now() - interval '3 days'),

  ((SELECT id FROM lawyers WHERE full_name = 'Test Admin'), 'person',
   '{"name":"Priya Nair","email":"priya.nair@example.com","mobile":"0400 555 666","title":"Ms"}',
   'Priya Nair', 'priya.nair@example.com', 'Referral', 'QLD', 'Test Admin', 'Existing client', 'Fixed fee', 'qualified', now() - interval '6 days'),

  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 1'), 'person',
   '{"name":"Marcus Lee","email":"marcus.lee@example.com","mobile":"0400 777 888","title":"Mr"}',
   'Marcus Lee', 'marcus.lee@example.com', 'Direct', 'NSW', 'Sample Lawyer 1', 'Website', 'Hourly', 'rejected', now() - interval '10 days'),

  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 2'), 'firm',
   '{"firmName":"Example Accounting Pty Ltd","contactName":"Grace Kim","email":"grace.kim@example.com","mobile":"0400 999 000"}',
   'Grace Kim', 'grace.kim@example.com', 'Referral', 'VIC', 'Sample Lawyer 2', 'Accountant', 'Fixed fee', 'pending', now() - interval '2 days');

-- 3. Client forms (forms)
-- Statuses cover each stage of the Kanban board.
INSERT INTO forms
  (lawyer_id, client_name, client_email, lead_type, region, referral_type, billing_type,
   person_responsible, status, progress_pct, form_data, unique_link,
   last_accessed, marked_complete_at, submitted_at, created_at, reminder_3d_sent)
VALUES
  -- Appointment sent (inquiry not yet answered)
  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 1'), 'Hannah Clarke', 'hannah.clarke@example.com',
   'Direct', 'NSW', 'Google', 'Fixed fee', 'Sample Lawyer 1', 'appointment_sent', 0, '{}',
   'demo-appt-001', now() - interval '2 days', NULL, NULL, now() - interval '2 days', NULL),

  -- Scheduled (inquiry answered, waiting for intake)
  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 2'), 'Thomas Reid', 'thomas.reid@example.com',
   'Referral', 'VIC', 'Accountant', 'Hourly', 'Sample Lawyer 2', 'scheduled', 0,
   '{"inquiry":{"goal":"Put a will or estate plan in place","state":"VIC","assets":"Family home, super"}}',
   'demo-sched-001', now() - interval '4 days', NULL, NULL, now() - interval '5 days', NULL),

  -- Pending intake (intake in progress)
  ((SELECT id FROM lawyers WHERE full_name = 'Test Admin'), 'Alice Chen', 'alice.chen@example.com',
   'Direct', 'NSW', 'Website', 'Fixed fee', 'Test Admin', 'pending_intake', 45,
   '{"inquiry":{"goal":"Update an existing one","state":"NSW"}}',
   'demo-pend-001', now() - interval '1 day', NULL, NULL, now() - interval '9 days', NULL),

  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 1'), 'Bob Wilson', 'bob.wilson@example.com',
   'Referral', 'QLD', 'Existing client', 'Hourly', 'Sample Lawyer 1', 'pending_intake', 78,
   '{"inquiry":{"goal":"Put a will or estate plan in place","state":"QLD"}}',
   'demo-pend-002', now() - interval '2 days', NULL, NULL, now() - interval '12 days', NULL),

  -- Overdue (intake stalled, reminder sent)
  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 2'), 'Emma White', 'emma.white@example.com',
   'Direct', 'VIC', 'Google', 'Fixed fee', 'Sample Lawyer 2', 'overdue', 25,
   '{"inquiry":{"goal":"Update an existing one","state":"VIC"}}',
   'demo-over-001', now() - interval '15 days', NULL, NULL, now() - interval '20 days', now() - interval '5 days'),

  -- Completed intake (waiting for lawyer review)
  ((SELECT id FROM lawyers WHERE full_name = 'Test Admin'), 'Carol Davis', 'carol.davis@example.com',
   'Referral', 'NSW', 'Accountant', 'Fixed fee', 'Test Admin', 'completed_intake', 100,
   '{"inquiry":{"goal":"Put a will or estate plan in place","state":"NSW"}}',
   'demo-comp-001', now() - interval '2 days', now() - interval '2 days', NULL, now() - interval '14 days', NULL),

  -- Submitted
  ((SELECT id FROM lawyers WHERE full_name = 'Sample Lawyer 1'), 'David Miller', 'david.miller@example.com',
   'Direct', 'QLD', 'Google', 'Hourly', 'Sample Lawyer 1', 'submitted', 100,
   '{"inquiry":{"goal":"Put a will or estate plan in place","state":"QLD"}}',
   'demo-sub-001', now() - interval '7 days', now() - interval '8 days', now() - interval '7 days', now() - interval '30 days', NULL);

-- 4. Check the result
SELECT status, count(*) FROM forms WHERE unique_link LIKE 'demo-%' GROUP BY status ORDER BY status;
SELECT status, count(*) FROM screening_submissions WHERE contact_data->>'email' LIKE '%@example.com' GROUP BY status ORDER BY status;
