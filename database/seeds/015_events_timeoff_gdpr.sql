-- 015_events_timeoff_gdpr.sql
-- Events, delivery assignments, time-off requests, GDPR, user addresses, sessions

-- Delivery assignments (for orders in delivering/delivered/completed states)
INSERT INTO public.delivery_assignments (id, order_id, delivery_person_id, status, assigned_at, picked_up_at, delivered_at, client_rating, delivery_notes) VALUES
  ('da000000-0000-0000-0000-000000000001', '08000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000005', 'delivered', '2026-01-15 09:00:00+00', '2026-01-15 10:00:00+00', '2026-01-15 12:30:00+00', 5, 'Livraison mariage sans accroc'),
  ('da000000-0000-0000-0000-000000000002', '08000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000005', 'delivered', '2026-02-01 17:00:00+00', '2026-02-01 17:30:00+00', '2026-02-01 19:00:00+00', 4, NULL),
  ('da000000-0000-0000-0000-000000000003', '08000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000005', 'delivered', '2026-04-20 10:00:00+00', '2026-04-20 10:30:00+00', '2026-04-20 12:00:00+00', NULL, NULL),
  ('da000000-0000-0000-0000-000000000004', '08000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000005', 'delivered', '2026-04-25 11:00:00+00', '2026-04-25 11:30:00+00', '2026-04-25 13:00:00+00', 5, 'Client très satisfait'),
  ('da000000-0000-0000-0000-000000000005', '08000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000005', 'in_transit', '2026-05-01 09:00:00+00', '2026-05-01 10:00:00+00', NULL, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- Events (mix of company, order-related, time-off, general)
INSERT INTO public.events (id, title, description, start_date, end_date, all_day, event_type, user_id, order_id, created_by) VALUES
  -- Order events (auto-generated from orders)
  ('e0000000-0000-0000-0000-000000000001', 'Mariage Dupont – 50 pers.', 'Livraison menu prestige', '2026-01-15 10:00', '2026-01-15 14:00', false, 'order', 'a0000000-0000-0000-0000-000000000007', '08000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002'),
  ('e0000000-0000-0000-0000-000000000002', 'Cocktail Entreprise Martin', 'Cocktail dînatoire 20 pers.', '2026-02-01 17:00', '2026-02-01 21:00', false, 'order', 'a0000000-0000-0000-0000-000000000008', '08000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002'),
  ('e0000000-0000-0000-0000-000000000003', 'Saint-Valentin Bernard', 'Dîner romantique 2 pers.', '2026-02-14 19:00', '2026-02-14 22:00', false, 'order', 'a0000000-0000-0000-0000-000000000009', '08000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003'),
  ('e0000000-0000-0000-0000-000000000004', 'Anniversaire Petit', 'Buffet anniversaire 15 pers.', '2026-03-01 11:00', '2026-03-01 16:00', false, 'order', 'a0000000-0000-0000-0000-000000000010', '08000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003'),
  ('e0000000-0000-0000-0000-000000000005', 'Livraison Moreau', 'Menu terroir 10 pers.', '2026-03-25 18:00', '2026-03-25 21:00', false, 'order', 'a0000000-0000-0000-0000-000000000011', '08000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000002'),
  -- Company events
  ('e0000000-0000-0000-0000-000000000006', 'Réunion d''équipe', 'Point hebdomadaire sur les commandes', '2026-05-05 09:00', '2026-05-05 10:00', false, 'meeting', NULL, NULL, 'a0000000-0000-0000-0000-000000000002'),
  ('e0000000-0000-0000-0000-000000000007', 'Formation hygiène HACCP', 'Formation obligatoire annuelle', '2026-05-12 09:00', '2026-05-12 17:00', true, 'training', NULL, NULL, 'a0000000-0000-0000-0000-000000000002'),
  ('e0000000-0000-0000-0000-000000000008', 'Inventaire mensuel', 'Inventaire stock cuisine', '2026-05-31 08:00', '2026-05-31 12:00', false, 'task', NULL, NULL, 'a0000000-0000-0000-0000-000000000004'),
  ('e0000000-0000-0000-0000-000000000009', 'Fermeture annuelle', 'Congés d''été', '2026-08-01 00:00', '2026-08-15 23:59', true, 'holiday', NULL, NULL, 'a0000000-0000-0000-0000-000000000002'),
  ('e0000000-0000-0000-0000-00000000000a', 'Salon du Mariage', 'Stand Vite & Gourmand', '2026-09-15 09:00', '2026-09-17 18:00', true, 'external', NULL, NULL, 'a0000000-0000-0000-0000-000000000002'),
  -- Upcoming order events
  ('e0000000-0000-0000-0000-00000000000b', 'Livraison prép. commande #8', 'Menu halal 10 pers. Toulouse', '2026-05-10 16:00', '2026-05-10 20:00', false, 'order', 'a0000000-0000-0000-0000-000000000013', '08000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000004'),
  ('e0000000-0000-0000-0000-00000000000c', 'Livraison anniversaire #11', 'Baptême 15 pers. Lyon', '2026-06-01 11:00', '2026-06-01 14:00', false, 'order', 'a0000000-0000-0000-0000-000000000009', '08000000-0000-0000-0000-00000000000b', 'a0000000-0000-0000-0000-000000000003')
ON CONFLICT (id) DO NOTHING;

-- Time-off requests
INSERT INTO public.time_off_requests (id, user_id, start_date, end_date, type, reason, status, decided_by, requested_at) VALUES
  ('13000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000004', '2026-06-15', '2026-06-20', 'vacation', 'Vacances programmées', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-04-01 10:00:00+00'),
  ('13000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000005', '2026-07-01', '2026-07-15', 'vacation', 'Congés d''été', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-04-10 09:00:00+00'),
  ('13000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', '2026-08-01', '2026-08-15', 'vacation', 'Fermeture annuelle', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-04-15 10:00:00+00'),
  ('13000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000004', '2026-09-10', '2026-09-12', 'personal', 'Rendez-vous médical', 'pending', NULL, '2026-04-28 14:00:00+00'),
  ('13000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000005', '2026-05-20', '2026-05-20', 'personal', 'Raison personnelle', 'rejected', 'a0000000-0000-0000-0000-000000000002', '2026-04-25 11:00:00+00'),
  ('13000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000004', '2026-12-23', '2026-12-26', 'vacation', 'Congé Noël', 'pending', NULL, '2026-04-30 09:00:00+00')
ON CONFLICT (id) DO NOTHING;

-- User addresses
INSERT INTO public.user_addresses (id, user_id, label, street_address, city, postal_code, country, is_default) VALUES
  ('14000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000007', 'Domicile', '10 rue de la Paix', 'Paris', '75001', 'France', true),
  ('14000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000008', 'Bureau', '5 avenue des Champs-Élysées', 'Paris', '75008', 'France', true),
  ('14000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000009', 'Maison', '3 place Bellecour', 'Lyon', '69002', 'France', true),
  ('14000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000010', 'Domicile', '12 rue Sainte-Catherine', 'Bordeaux', '33000', 'France', true),
  ('14000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000007', 'Bureau', '25 boulevard Haussmann', 'Paris', '75009', 'France', false)
ON CONFLICT (id) DO NOTHING;

-- User sessions (recent)
INSERT INTO public.user_sessions (id, user_id, session_token, ip_address, user_agent, expires_at) VALUES
  ('16000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'session-admin-token-001', '192.168.1.1', 'Mozilla/5.0 Chrome/125', now() + interval '7 days'),
  ('16000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000007', 'session-alice-token-001', '83.150.12.45', 'Mozilla/5.0 Firefox/128', now() + interval '7 days')
ON CONFLICT (id) DO NOTHING;

-- User consents (GDPR)
INSERT INTO public.user_consents (id, user_id, consent_type, is_granted, ip_address) VALUES
  ('15000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000007', 'cookies_analytics', true,  '83.150.12.45'),
  ('15000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000007', 'newsletter',        true,  '83.150.12.45'),
  ('15000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000008', 'cookies_analytics', true,  '90.120.5.78'),
  ('15000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000008', 'newsletter',        true,  '90.120.5.78'),
  ('15000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000009', 'cookies_analytics', false, '176.30.8.12'),
  ('15000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000010', 'cookies_analytics', true,  '81.65.200.3')
ON CONFLICT (id) DO NOTHING;

-- GDPR data deletion request (1 from soft-deleted user)
INSERT INTO public.data_deletion_requests (id, user_id, reason, status, processed_by, processed_at) VALUES
  ('dd000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000014', 'Je souhaite exercer mon droit à l''effacement conformément au RGPD.', 'pending', NULL, NULL)
ON CONFLICT (id) DO NOTHING;
