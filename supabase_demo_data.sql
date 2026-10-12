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

-- 3b. Answers for each demo form (Initial Outreach = inquiry, Intake = intake)
-- Scheduled: inquiry only
UPDATE forms SET form_data = $j${"inquiry":{"client_name":"Thomas Reid","client_email":"thomas.reid@example.com","client_phone":"0400 121 343","client_state":"VIC","inquiry_reason":"Put a will or estate plan in place","goal":"A will — who receives what","complexity_flags":["Planning with a partner"],"asset_flags":["Property in my name","Superannuation"],"executor_confidence":"I know exactly who","gifts_volume":"A few","funeral_wishes":["Clear wishes on burial or cremation"],"additional_notes":"Would like to talk about a trust for the kids."}}$j$::jsonb WHERE unique_link = 'demo-sched-001';

-- Pending intake: Alice Chen (inquiry + partial intake)
UPDATE forms SET form_data = $j${"inquiry":{"client_name":"Alice Chen","client_email":"alice.chen@example.com","client_phone":"0400 222 333","client_state":"NSW","inquiry_reason":"Update an existing one","goal":"Protecting an inheritance rather than paying it out directly","complexity_flags":["Children under 18"],"asset_flags":["Property in my name"],"executor_confidence":"Not sure yet","gifts_volume":"A few","funeral_wishes":["Haven't thought about it yet"],"additional_notes":"Please keep it simple."},"intake":{"client_name":"Alice Chen","client_address":"14 Harbour View Rd, Mosman NSW 2088","client_state":"NSW","client_marital_status":"Single","client_occupation":"Architect","scenario":"Single","governing_jurisdiction":"NSW","has_minors":"Yes","guardian_initial":"Ben Chen","guardian_backup":"Mei Chen","exec_initial_name":"Ben Chen","exec_initial_relationship":"Brother","exec_initial_address":"3/22 Ocean St, Bondi NSW 2026","beneficiary1":"Ben Chen","beneficiary1_pct":"50","beneficiary2":"Mei Chen","beneficiary2_pct":"50","beneficiary_count":"2"},"metadata":{"current_step":4}}$j$::jsonb, progress_pct = 45 WHERE unique_link = 'demo-pend-001';

-- Pending intake: Bob Wilson (couple, further along)
UPDATE forms SET form_data = $j${"inquiry":{"client_name":"Bob Wilson","client_email":"bob.wilson@example.com","client_phone":"0400 444 555","client_state":"QLD","inquiry_reason":"Put a will or estate plan in place","goal":"A will — who receives what","complexity_flags":["Planning with a partner","Children from a previous relationship"],"asset_flags":["Jointly owned property","Superannuation"],"executor_confidence":"I'd like guidance","gifts_volume":"Quite a number","funeral_wishes":["Organ or tissue donor"],"additional_notes":"Blended family, two adult children from my first marriage."},"intake":{"client_name":"Bob Wilson","client_address":"8 Palm Ave, Noosa Heads QLD 4567","client_state":"QLD","client_marital_status":"Married","client_occupation":"Engineer","scenario":"Couple","spouse_name":"Jenna Wilson","spouse_occupation":"Teacher","governing_jurisdiction":"QLD","has_minors":"No","exec_initial_name":"Jenna Wilson","exec_initial_relationship":"Spouse","exec_backup":"Sam Wilson","beneficiary1":"Jenna Wilson","beneficiary1_pct":"50","beneficiary2":"Sam Wilson","beneficiary2_pct":"25","beneficiary3":"Ruby Wilson","beneficiary3_pct":"25","beneficiary_count":"3","organ_donation":"Yes"},"metadata":{"current_step":10}}$j$::jsonb, progress_pct = 78 WHERE unique_link = 'demo-pend-002';

-- Overdue: Emma White (intake stalled)
UPDATE forms SET form_data = $j${"inquiry":{"client_name":"Emma White","client_email":"emma.white@example.com","client_phone":"0400 666 777","client_state":"VIC","inquiry_reason":"Update an existing one","goal":"Protecting an inheritance rather than paying it out directly","complexity_flags":["A dependant with a disability or care needs"],"asset_flags":["Mostly savings and personal belongings"],"executor_confidence":"Not sure yet, I'd like it explained","gifts_volume":"A few","funeral_wishes":["Clear wishes on burial or cremation"],"additional_notes":"Please call after 5pm."},"intake":{"client_name":"Emma White","client_address":"55 Lygon St, Brunswick VIC 3056","client_state":"VIC","client_marital_status":"Single","client_occupation":"Nurse","scenario":"Single","governing_jurisdiction":"VIC","has_minors":"No","exec_initial_name":"Liam White","exec_initial_relationship":"Brother"},"metadata":{"current_step":3}}$j$::jsonb WHERE unique_link = 'demo-over-001';

-- Completed intake: Carol Davis (full intake)
UPDATE forms SET form_data = $j${"inquiry":{"client_name":"Carol Davis","client_email":"carol.davis@example.com","client_phone":"0400 888 999","client_state":"NSW","inquiry_reason":"Put a will or estate plan in place","goal":"A will — who receives what","complexity_flags":["Children under 18"],"asset_flags":["Property in my name","Superannuation"],"executor_confidence":"I know exactly who","gifts_volume":"A few","funeral_wishes":["Clear wishes on burial or cremation"],"additional_notes":"None."},"intake":{"client_name":"Carol Davis","client_former_names":"None","client_address":"21 Pitt Street, Parramatta NSW 2150","client_state":"NSW","client_marital_status":"Single","client_occupation":"Accountant","scenario":"Single","governing_jurisdiction":"NSW","signing_date":"2026-11-20","will_custody":"Firm","doc_will":"Yes","doc_epa":"Yes","doc_acd":"Yes","has_minors":"Yes","guardian_initial":"Helen Davis","guardian_backup":"Peter Davis","exec_initial_name":"Helen Davis","exec_initial_relationship":"Sister","exec_initial_address":"9 Ruby St, Epping NSW 2121","exec_backup":"Peter Davis","exec_joint":"No","beneficiary1":"Helen Davis","beneficiary1_pct":"60","beneficiary2":"Peter Davis","beneficiary2_pct":"40","beneficiary_count":"2","calamity1":"Helen Davis","calamity1_pct":"100","calamity_count":"1","funeral_other":"Simple service","burial_or_cremation":"Cremation","organ_donation":"Yes","has_company":"No","has_life_tenancy":"No","has_sdt":"No","add_to_wills_register":"Yes","no_contest_clause":"Yes","mirror_or_independent":"Independent"},"metadata":{"current_step":14}}$j$::jsonb WHERE unique_link = 'demo-comp-001';

-- Submitted: David Miller (full intake)
UPDATE forms SET form_data = $j${"inquiry":{"client_name":"David Miller","client_email":"david.miller@example.com","client_phone":"0400 101 202","client_state":"QLD","inquiry_reason":"Put a will or estate plan in place","goal":"A will — who receives what","complexity_flags":["Planning with a partner"],"asset_flags":["Overseas assets"],"executor_confidence":"I'd rather my family decided","gifts_volume":"None, divide by share","funeral_wishes":["Organ or tissue donor"],"additional_notes":"None."},"intake":{"client_name":"David Miller","client_address":"3 Marina Dr, Hope Island QLD 4212","client_state":"QLD","client_marital_status":"Married","client_occupation":"Surveyor","scenario":"Couple","spouse_name":"Anna Miller","spouse_occupation":"Pharmacist","governing_jurisdiction":"QLD","signing_date":"2026-12-04","will_custody":"Home safe","doc_will":"Yes","doc_epa":"Yes","has_minors":"No","exec_initial_name":"Anna Miller","exec_initial_relationship":"Spouse","exec_initial_address":"3 Marina Dr, Hope Island QLD 4212","exec_backup":"Tom Miller","exec_joint":"Yes","beneficiary1":"Anna Miller","beneficiary1_pct":"100","beneficiary_count":"1","calamity1":"Tom Miller","calamity1_pct":"100","calamity_count":"1","burial_or_cremation":"Burial","organ_donation":"Yes","has_company":"No","has_life_tenancy":"No","has_sdt":"No","add_to_wills_register":"Yes","no_contest_clause":"No","mirror_or_independent":"Mirror"},"metadata":{"current_step":14,"will_pdf_path":"/wills/will_demo_sub_001.pdf"}}$j$::jsonb WHERE unique_link = 'demo-sub-001';

-- 4. Check the result
SELECT status, count(*) FROM forms WHERE unique_link LIKE 'demo-%' GROUP BY status ORDER BY status;
SELECT status, count(*) FROM screening_submissions WHERE contact_data->>'email' LIKE '%@example.com' GROUP BY status ORDER BY status;
