-- 008_promotions.sql
-- 7 promotions + user_promotions assignments

INSERT INTO public.promotions (id, title, description, type, image_url, is_public, start_date, end_date, created_by) VALUES
  -- Active public
  ('04000000-0000-0000-0000-000000000001', 'Grand Opening – 15% sur tout !', 'Profitez de notre offre de lancement', 'banner', '/images/promotions/opening.jpg', true, '2025-01-01', '2027-12-31', 'a0000000-0000-0000-0000-000000000002'),
  ('04000000-0000-0000-0000-000000000002', 'Menu du mois à -10%', 'Découvrez le menu sélectionné chaque mois', 'popup', '/images/promotions/monthly.jpg', true, '2026-05-01', '2026-05-31', 'a0000000-0000-0000-0000-000000000002'),
  ('04000000-0000-0000-0000-000000000003', 'Happy Hour Cocktails', '2 cocktails achetés = 1 offert', 'banner', '/images/promotions/happyhour.jpg', true, '2026-01-01', '2026-12-31', 'a0000000-0000-0000-0000-000000000003'),
  -- Future
  ('04000000-0000-0000-0000-000000000004', 'Promo Rentrée 2026', 'Spécial rentrée des classes', 'banner', NULL, true, '2026-09-01', '2026-09-30', 'a0000000-0000-0000-0000-000000000002'),
  ('04000000-0000-0000-0000-000000000005', 'Black Friday Gourmand', '-25% sur tous les menus', 'popup', '/images/promotions/blackfriday.jpg', true, '2026-11-25', '2026-11-30', 'a0000000-0000-0000-0000-000000000002'),
  -- VIP private
  ('04000000-0000-0000-0000-000000000006', 'Offre VIP Fidélité', 'Offre exclusive pour nos clients fidèles', 'banner', NULL, false, '2026-01-01', '2027-01-01', 'a0000000-0000-0000-0000-000000000002'),
  -- Expired
  ('04000000-0000-0000-0000-000000000007', 'Promo Noël 2024', 'Offre terminée', 'popup', NULL, true, '2024-12-15', '2025-01-05', 'a0000000-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;

-- VIP promotion assigned only to loyal clients
INSERT INTO public.user_promotions (user_id, promotion_id) VALUES
  ('a0000000-0000-0000-0000-000000000007', '04000000-0000-0000-0000-000000000006'),
  ('a0000000-0000-0000-0000-000000000008', '04000000-0000-0000-0000-000000000006'),
  ('a0000000-0000-0000-0000-000000000009', '04000000-0000-0000-0000-000000000006')
ON CONFLICT DO NOTHING;
