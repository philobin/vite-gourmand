-- 013_newsletter.sql
-- 10 subscribers (6 registered + 3 anonymous + 1 unsubscribed)

INSERT INTO public.newsletter_subscribers (id, email, user_id, is_active, created_at, unsubscribed_at) VALUES
  -- Registered users
  ('05000000-0000-0000-0000-000000000001', 'jose.admin@vitegourmand.fr', 'a0000000-0000-0000-0000-000000000002', true,  '2025-06-01 10:00:00+00', NULL),
  ('05000000-0000-0000-0000-000000000002', 'julie.chef@vitegourmand.fr', 'a0000000-0000-0000-0000-000000000003', true,  '2025-06-01 10:00:00+00', NULL),
  ('05000000-0000-0000-0000-000000000003', 'alice.dupont@email.com',     'a0000000-0000-0000-0000-000000000007', true,  '2026-01-20 10:00:00+00', NULL),
  ('05000000-0000-0000-0000-000000000004', 'bob.martin@email.com',       'a0000000-0000-0000-0000-000000000008', true,  '2026-02-05 16:00:00+00', NULL),
  ('05000000-0000-0000-0000-000000000005', 'claire.bernard@email.com',   'a0000000-0000-0000-0000-000000000009', true,  '2026-02-16 20:00:00+00', NULL),
  ('05000000-0000-0000-0000-000000000006', 'david.petit@email.com',      'a0000000-0000-0000-0000-000000000010', true,  '2026-03-05 14:00:00+00', NULL),
  -- Anonymous visitors
  ('05000000-0000-0000-0000-000000000007', 'visiteur1@example.com',       NULL, true,  '2026-03-10 09:00:00+00', NULL),
  ('05000000-0000-0000-0000-000000000008', 'visiteur2@example.com',       NULL, true,  '2026-03-15 14:00:00+00', NULL),
  ('05000000-0000-0000-0000-000000000009', 'visiteur3@example.com',       NULL, true,  '2026-04-01 10:00:00+00', NULL),
  -- Unsubscribed
  ('05000000-0000-0000-0000-00000000000a', 'ancien.client@example.com',   NULL, false, '2025-09-01 10:00:00+00', '2026-02-01 10:00:00+00')
ON CONFLICT (id) DO NOTHING;
