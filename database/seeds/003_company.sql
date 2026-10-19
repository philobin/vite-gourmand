-- 003_company.sql
-- Seed company "Vite & Gourmand" + working hours + owners

-- UUID for the company
INSERT INTO public.companies (
  id, name, slogan, description, first_opening_date,
  address, city, postal_code, country, phone, email, website,
  siret, is_active
) VALUES (
  'c0000000-0000-0000-0000-000000000001',
  'Vite & Gourmand',
  'L''art du traiteur à votre service',
  'Traiteur événementiel basé à Bordeaux, spécialisé dans la cuisine française raffinée pour tous vos événements.',
  '2001-03-15',
  '15 Rue Sainte-Catherine',
  'Bordeaux',
  '33000',
  'France',
  '05 56 00 00 01',
  'contact@vitegourmand.fr',
  'https://vitegourmand.fr',
  '12345678901234',
  true
) ON CONFLICT (siret) DO NOTHING;

-- Working hours
INSERT INTO public.working_hours (id, day, opening, closing) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Lundi', '09:00', '18:00'),
  ('a1000000-0000-0000-0000-000000000002', 'Mardi', '09:00', '18:00'),
  ('a1000000-0000-0000-0000-000000000003', 'Mercredi', '09:00', '18:00'),
  ('a1000000-0000-0000-0000-000000000004', 'Jeudi', '09:00', '18:00'),
  ('a1000000-0000-0000-0000-000000000005', 'Vendredi', '09:00', '20:00'),
  ('a1000000-0000-0000-0000-000000000006', 'Samedi', '10:00', '22:00'),
  ('a1000000-0000-0000-0000-000000000007', 'Dimanche', '10:00', '16:00')
ON CONFLICT (day) DO UPDATE SET opening = EXCLUDED.opening, closing = EXCLUDED.closing;

-- Link working hours to company
INSERT INTO public.company_working_hours (company_id, working_hours_id)
SELECT 'c0000000-0000-0000-0000-000000000001', id FROM public.working_hours
ON CONFLICT DO NOTHING;

-- Company owners
INSERT INTO public.company_owners (company_id, user_id, role, is_primary) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'owner', true),
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'co-owner', false)
ON CONFLICT DO NOTHING;
