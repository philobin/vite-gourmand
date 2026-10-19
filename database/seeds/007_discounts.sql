-- 007_discounts.sql
-- 5 discount codes

INSERT INTO public.discounts (id, code, description, type, value, min_order_amount, max_uses, current_uses, is_active, valid_from, valid_until, created_by) VALUES
  ('dc000000-0000-0000-0000-000000000001', 'BIENVENUE10', 'Réduction de bienvenue 10%', 'percentage', 10.00, 20.00, 500, 47, true, '2025-01-01', '2027-12-31', 'a0000000-0000-0000-0000-000000000002'),
  ('dc000000-0000-0000-0000-000000000002', 'ETE2026', 'Promo été 2026 – 15%', 'percentage', 15.00, 30.00, 200, 12, true, '2026-06-01', '2026-09-30', 'a0000000-0000-0000-0000-000000000002'),
  ('dc000000-0000-0000-0000-000000000003', 'FIDELE50', 'Réduction fidélité 50€', 'fixed_amount', 50.00, 100.00, 100, 5, true, '2025-06-01', '2027-06-01', 'a0000000-0000-0000-0000-000000000002'),
  ('dc000000-0000-0000-0000-000000000004', 'EXPIRE2025', 'Code expiré (test)', 'percentage', 20.00, 0, 100, 30, false, '2024-01-01', '2024-12-31', 'a0000000-0000-0000-0000-000000000002'),
  ('dc000000-0000-0000-0000-000000000005', 'NOEL2026', 'Promo Noël – 20%', 'percentage', 20.00, 50.00, 150, 0, true, '2026-12-01', '2027-01-05', 'a0000000-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;
