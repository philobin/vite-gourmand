-- 014_support_notifications.sql
-- 6 support tickets, contact messages, notifications, user messages

-- Contact messages (both from visitors and logged-in users)
INSERT INTO public.contact_messages (id, name, email, subject, message, user_id, created_at) VALUES
  ('c3000000-0000-0000-0000-000000000001', 'Alice Dupont', 'alice.dupont@email.com', 'Demande de devis mariage', 'Bonjour, nous souhaitons organiser notre mariage pour 80 personnes en septembre 2026. Pouvez-vous nous envoyer un devis ?', 'a0000000-0000-0000-0000-000000000007', '2026-01-10 10:00:00+00'),
  ('c3000000-0000-0000-0000-000000000002', 'Visiteur Lambda', 'visiteur@example.com', 'Question allergènes', 'Bonjour, est-il possible d''adapter vos menus pour une personne allergique aux fruits à coque et au lait ?', NULL, '2026-02-15 14:00:00+00'),
  ('c3000000-0000-0000-0000-000000000003', 'Bob Martin', 'bob.martin@email.com', 'Réclamation livraison', 'Le matériel de la dernière commande n''a pas été récupéré à la date prévue.', 'a0000000-0000-0000-0000-000000000008', '2026-03-20 09:00:00+00'),
  ('c3000000-0000-0000-0000-000000000004', 'Claire Bernard', 'claire.bernard@email.com', 'Partenariat', 'Bonjour, je représente un vignoble et j''aimerais discuter d''un partenariat.', 'a0000000-0000-0000-0000-000000000009', '2026-04-01 11:00:00+00'),
  ('c3000000-0000-0000-0000-000000000005', 'Pro Event Corp', 'contact@proevent.com', 'Demande événement entreprise', 'Nous cherchons un traiteur pour notre gala annuel de 200 personnes.', NULL, '2026-04-10 16:00:00+00'),
  ('c3000000-0000-0000-0000-000000000006', 'David Petit', 'david.petit@email.com', 'Problème facturation', 'La facture reçue ne correspond pas au montant convenu.', 'a0000000-0000-0000-0000-000000000010', '2026-04-25 08:00:00+00')
ON CONFLICT (id) DO NOTHING;

-- Support tickets
INSERT INTO public.support_tickets (id, ticket_number, contact_message_id, user_id, subject, status, priority, assigned_to, created_at) VALUES
  ('50000000-0000-0000-0000-000000000001', 'TK202601-ABC001', 'c3000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000007', 'Demande de devis mariage',     'resolved',    'medium', 'a0000000-0000-0000-0000-000000000003', '2026-01-10 10:05:00+00'),
  ('50000000-0000-0000-0000-000000000002', 'TK202602-DEF002', 'c3000000-0000-0000-0000-000000000002', NULL,                                  'Question allergènes',           'resolved',    'low',    'a0000000-0000-0000-0000-000000000004', '2026-02-15 14:05:00+00'),
  ('50000000-0000-0000-0000-000000000003', 'TK202603-GHI003', 'c3000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000008', 'Réclamation livraison',         'in_progress', 'high',   'a0000000-0000-0000-0000-000000000005', '2026-03-20 09:05:00+00'),
  ('50000000-0000-0000-0000-000000000004', 'TK202604-JKL004', 'c3000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000009', 'Partenariat',                   'open',        'medium', NULL, '2026-04-01 11:05:00+00'),
  ('50000000-0000-0000-0000-000000000005', 'TK202604-MNO005', 'c3000000-0000-0000-0000-000000000005', NULL,                                  'Demande événement entreprise', 'open',        'high',   'a0000000-0000-0000-0000-000000000002', '2026-04-10 16:05:00+00'),
  ('50000000-0000-0000-0000-000000000006', 'TK202604-PQR006', 'c3000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000010', 'Problème facturation',          'open',        'high',   'a0000000-0000-0000-0000-000000000002', '2026-04-25 08:05:00+00')
ON CONFLICT (id) DO NOTHING;

-- Ticket replies
INSERT INTO public.ticket_messages (id, ticket_id, user_id, body, created_at) VALUES
  ('12000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Bonjour Alice, nous vous préparons un devis personnalisé. Votre budget indicatif ?', '2026-01-10 14:00:00+00'),
  ('12000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000007', 'Autour de 8000€ pour 80 personnes.', '2026-01-11 09:00:00+00'),
  ('12000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Parfait, devis envoyé par email. N''hésitez pas si vous avez des questions !', '2026-01-11 15:00:00+00'),
  ('12000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000005', 'Nous contactons le livreur pour planifier la récupération au plus vite.', '2026-03-20 14:00:00+00'),
  ('12000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000002', 'Bonjour David, pouvez-vous nous envoyer la facture en question ?', '2026-04-25 10:00:00+00')
ON CONFLICT (id) DO NOTHING;

-- Notifications
INSERT INTO public.notifications (id, user_id, type, title, body, is_read, link_url, created_at) VALUES
  ('07000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000007', 'order', 'Commande confirmée', 'Votre commande VG-20260101-ABC001 a été acceptée.', true, '/orders/08000000-0000-0000-0000-000000000001', '2026-01-05 14:00:00+00'),
  ('07000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000007', 'order', 'Commande prête', 'Votre commande est prête pour la livraison.', true, '/orders/08000000-0000-0000-0000-000000000001', '2026-01-14 16:00:00+00'),
  ('07000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000007', 'loyalty', 'Points fidélité crédités', '4275 points ont été ajoutés à votre compte.', true, '/loyalty', '2026-01-16 10:00:00+00'),
  ('07000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000008', 'order', 'Commande confirmée', 'Votre commande VG-20260115-DEF002 a été acceptée.', true, '/orders/08000000-0000-0000-0000-000000000002', '2026-01-16 14:00:00+00'),
  ('07000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000002', 'system', 'Nouveau ticket support', 'Ticket TK202604-MNO005 : Demande événement entreprise', false, '/admin/support/50000000-0000-0000-0000-000000000005', '2026-04-10 16:05:00+00'),
  ('07000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000002', 'system', 'Nouveau ticket support', 'Ticket TK202604-PQR006 : Problème facturation', false, '/admin/support/50000000-0000-0000-0000-000000000006', '2026-04-25 08:05:00+00'),
  ('07000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000002', 'review', 'Nouvel avis à modérer', '3 avis en attente de modération.', false, '/admin/reviews?status=pending', '2026-04-30 10:00:00+00'),
  ('07000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000009', 'promotion', 'Nouvelle offre VIP', 'Vous avez accès à une offre exclusive fidélité.', false, '/promotions', '2026-04-01 10:00:00+00'),
  ('07000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000011', 'order', 'Commande en attente', 'Votre commande VG-20260430-KLM013 est en attente de validation.', false, '/orders/08000000-0000-0000-0000-00000000000d', '2026-04-30 08:00:00+00'),
  ('07000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-000000000013', 'order', 'Commande en préparation', 'Votre commande VG-20260420-VWX008 est en cours de préparation.', false, '/orders/08000000-0000-0000-0000-000000000008', '2026-04-22 10:00:00+00')
ON CONFLICT (id) DO NOTHING;

-- User-to-user / admin messages
INSERT INTO public.messages (id, sender_id, recipient_id, body, is_read, sent_at) VALUES
  ('09000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000007', 'Bonjour Alice, votre commande spéciale a été validée !', true,  '2026-01-06 10:00:00+00'),
  ('09000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000002', 'Merci José ! Nous avons hâte.', true,  '2026-01-06 14:00:00+00'),
  ('09000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000008', 'Bonjour Bob, des nouvelles du matériel en attente ?', true,  '2026-03-21 10:00:00+00'),
  ('09000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000002', 'Le livreur passe demain matin !', true,  '2026-03-21 16:00:00+00'),
  ('09000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004', 'Sophie, tu peux préparer les entrées pour la commande de demain ?', true,  '2026-04-19 15:00:00+00'),
  ('09000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003', 'C''est noté Julie, je m''en occupe dès 7h.', true,  '2026-04-19 17:00:00+00'),
  ('09000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000009', 'Claire, votre proposition de partenariat nous intéresse. On en parle ?', false, '2026-04-02 10:00:00+00'),
  ('09000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000012', 'Merci pour votre avis ! Voici un code promo en remerciement : MERCI15', false, '2026-04-13 10:00:00+00'),
  ('09000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000002', 'José, la livraison du 1er mai est en route.', false, '2026-05-01 09:00:00+00'),
  ('09000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000005', 'Parfait Thomas, tiens-moi au courant.', false, '2026-05-01 09:30:00+00')
ON CONFLICT (id) DO NOTHING;
