-- 011_reviews.sql
-- 17 reviews (12 approved, 3 pending, 2 rejected) + review_images

INSERT INTO public.reviews (id, user_id, order_id, note, description, status, moderated_by, created_at) VALUES
  -- Approved reviews (12)
  ('0b000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000007', '08000000-0000-0000-0000-000000000001', 5, 'Tout était parfait pour notre mariage, le menu prestige a ravi tous nos invités. Service impeccable.', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-01-20 10:00:00+00'),
  ('0b000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000008', '08000000-0000-0000-0000-000000000002', 4, 'Le cocktail entreprise était excellent, très professionnel. Juste un peu d''attente au début.', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-02-05 16:00:00+00'),
  ('0b000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000009', '08000000-0000-0000-0000-000000000003', 5, 'Menu Saint-Valentin exceptionnel, présentation magnifique.', 'approved', 'a0000000-0000-0000-0000-000000000003', '2026-02-16 20:00:00+00'),
  ('0b000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000010', '08000000-0000-0000-0000-000000000004', 4, 'Belle fête d''anniversaire, le buffet était copieux et varié.', 'approved', 'a0000000-0000-0000-0000-000000000003', '2026-03-05 14:00:00+00'),
  ('0b000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000011', '08000000-0000-0000-0000-000000000005', 5, 'Le menu terroir bordelais nous a transportés, les produits sont de grande qualité.', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-03-28 12:00:00+00'),
  ('0b000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000007', NULL, 3, 'La qualité est là mais le rapport qualité/prix pourrait être amélioré.', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-04-10 10:00:00+00'),
  ('0b000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000012', NULL, 5, 'Meilleur traiteur que nous ayons jamais essayé, nous sommes fans !', 'approved', 'a0000000-0000-0000-0000-000000000003', '2026-04-12 09:00:00+00'),
  ('0b000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000008', NULL, 4, 'Excellente surprise, les saveurs sont au rendez-vous même sans produits animaux.', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-04-15 17:00:00+00'),
  ('0b000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000013', NULL, 4, 'Ponctuel, professionnel, et le plat du jour était délicieux.', 'approved', 'a0000000-0000-0000-0000-000000000003', '2026-04-18 11:00:00+00'),
  ('0b000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-000000000014', NULL, 5, 'Menu baptême douceur très bien adapté, personnel aux petits soins.', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-04-20 15:00:00+00'),
  ('0b000000-0000-0000-0000-00000000000b', 'a0000000-0000-0000-0000-000000000009', NULL, 2, 'Commande livrée en retard et plats tièdes. Habituellement meilleur.', 'approved', 'a0000000-0000-0000-0000-000000000002', '2026-04-22 19:00:00+00'),
  ('0b000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000010', NULL, 4, 'Enfin un traiteur qui prend le sans gluten au sérieux !', 'approved', 'a0000000-0000-0000-0000-000000000003', '2026-04-25 10:00:00+00'),
  -- Pending reviews (3)
  ('0b000000-0000-0000-0000-00000000000d', 'a0000000-0000-0000-0000-000000000011', NULL, 4, 'Bonne prestation dans l''ensemble, je recommande.', 'pending', NULL, '2026-04-28 14:00:00+00'),
  ('0b000000-0000-0000-0000-00000000000e', 'a0000000-0000-0000-0000-000000000012', NULL, 5, 'Rien à redire, tout était absolument parfait du début à la fin.', 'pending', NULL, '2026-04-29 08:00:00+00'),
  ('0b000000-0000-0000-0000-00000000000f', 'a0000000-0000-0000-0000-000000000013', NULL, 3, 'Les quantités étaient un peu justes pour le prix demandé.', 'pending', NULL, '2026-04-30 16:00:00+00'),
  -- Rejected reviews (2)
  ('0b000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000014', NULL, 1, 'azerty12345 test content', 'rejected', 'a0000000-0000-0000-0000-000000000002', '2026-04-15 10:00:00+00'),
  ('0b000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000011', NULL, 1, 'XXX contenu supprimé par la modération XXX', 'rejected', 'a0000000-0000-0000-0000-000000000002', '2026-04-20 12:00:00+00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.review_images (id, review_id, image_url) VALUES
  ('06000000-0000-0000-0000-000000000001', '0b000000-0000-0000-0000-000000000001', '/images/reviews/mariage-table.jpg'),
  ('06000000-0000-0000-0000-000000000002', '0b000000-0000-0000-0000-000000000001', '/images/reviews/mariage-dessert.jpg'),
  ('06000000-0000-0000-0000-000000000003', '0b000000-0000-0000-0000-000000000003', '/images/reviews/valentines.jpg'),
  ('06000000-0000-0000-0000-000000000004', '0b000000-0000-0000-0000-000000000005', '/images/reviews/terroir-plat.jpg'),
  ('06000000-0000-0000-0000-000000000005', '0b000000-0000-0000-0000-000000000007', '/images/reviews/amazing-spread.jpg')
ON CONFLICT (id) DO NOTHING;
