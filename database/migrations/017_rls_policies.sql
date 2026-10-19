-- 017_rls_policies.sql
-- Row Level Security policies for all domain tables
-- Pattern: public-read tables get anon SELECT, user-owned tables get owner-only, admin tables get admin-only

-- ─── PROFILES ─────────────────────────────────────────────────────
-- Everyone can see active profiles (public directory)
DROP POLICY IF EXISTS profiles_select ON public.profiles;
CREATE POLICY profiles_select ON public.profiles
  FOR SELECT USING (true);

-- Users can update their own profile
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins can do everything
DROP POLICY IF EXISTS profiles_admin ON public.profiles;
CREATE POLICY profiles_admin ON public.profiles
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── COMPANIES (public read, admin write) ─────────────────────────
DROP POLICY IF EXISTS companies_select ON public.companies;
CREATE POLICY companies_select ON public.companies
  FOR SELECT USING (true);

DROP POLICY IF EXISTS companies_admin ON public.companies;
CREATE POLICY companies_admin ON public.companies
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── WORKING HOURS (public read, staff write) ────────────────────
DROP POLICY IF EXISTS working_hours_select ON public.working_hours;
CREATE POLICY working_hours_select ON public.working_hours
  FOR SELECT USING (true);

DROP POLICY IF EXISTS working_hours_staff ON public.working_hours;
CREATE POLICY working_hours_staff ON public.working_hours
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── COMPANY OWNERS (public read, admin write) ───────────────────
DROP POLICY IF EXISTS company_owners_select ON public.company_owners;
CREATE POLICY company_owners_select ON public.company_owners
  FOR SELECT USING (true);

DROP POLICY IF EXISTS company_owners_admin ON public.company_owners;
CREATE POLICY company_owners_admin ON public.company_owners
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── COMPANY WORKING HOURS (public read, admin write) ────────────
DROP POLICY IF EXISTS cwh_select ON public.company_working_hours;
CREATE POLICY cwh_select ON public.company_working_hours
  FOR SELECT USING (true);

DROP POLICY IF EXISTS cwh_admin ON public.company_working_hours;
CREATE POLICY cwh_admin ON public.company_working_hours
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── ALLERGENS (public read, staff write) ─────────────────────────
DROP POLICY IF EXISTS allergens_select ON public.allergens;
CREATE POLICY allergens_select ON public.allergens
  FOR SELECT USING (true);

DROP POLICY IF EXISTS allergens_staff ON public.allergens;
CREATE POLICY allergens_staff ON public.allergens
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── DIETS (public read, staff write) ─────────────────────────────
DROP POLICY IF EXISTS diets_select ON public.diets;
CREATE POLICY diets_select ON public.diets
  FOR SELECT USING (true);

DROP POLICY IF EXISTS diets_staff ON public.diets;
CREATE POLICY diets_staff ON public.diets
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── THEMES (public read, staff write) ────────────────────────────
DROP POLICY IF EXISTS themes_select ON public.themes;
CREATE POLICY themes_select ON public.themes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS themes_staff ON public.themes;
CREATE POLICY themes_staff ON public.themes
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── INGREDIENTS (staff only) ─────────────────────────────────────
DROP POLICY IF EXISTS ingredients_staff ON public.ingredients;
CREATE POLICY ingredients_staff ON public.ingredients
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── DISHES (public read, staff write) ────────────────────────────
DROP POLICY IF EXISTS dishes_select ON public.dishes;
CREATE POLICY dishes_select ON public.dishes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS dishes_staff ON public.dishes;
CREATE POLICY dishes_staff ON public.dishes
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── DISH ALLERGENS (public read, staff write) ───────────────────
DROP POLICY IF EXISTS dish_allergens_select ON public.dish_allergens;
CREATE POLICY dish_allergens_select ON public.dish_allergens
  FOR SELECT USING (true);

DROP POLICY IF EXISTS dish_allergens_staff ON public.dish_allergens;
CREATE POLICY dish_allergens_staff ON public.dish_allergens
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── DISH INGREDIENTS (staff only) ────────────────────────────────
DROP POLICY IF EXISTS dish_ingredients_staff ON public.dish_ingredients;
CREATE POLICY dish_ingredients_staff ON public.dish_ingredients
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── MENUS (public read published, staff full) ───────────────────
DROP POLICY IF EXISTS menus_select_published ON public.menus;
CREATE POLICY menus_select_published ON public.menus
  FOR SELECT USING (status = 'published' OR public.is_staff());

DROP POLICY IF EXISTS menus_staff ON public.menus;
CREATE POLICY menus_staff ON public.menus
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── MENU IMAGES (public read, staff write) ──────────────────────
DROP POLICY IF EXISTS menu_images_select ON public.menu_images;
CREATE POLICY menu_images_select ON public.menu_images
  FOR SELECT USING (true);

DROP POLICY IF EXISTS menu_images_staff ON public.menu_images;
CREATE POLICY menu_images_staff ON public.menu_images
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── MENU INGREDIENTS (staff only) ────────────────────────────────
DROP POLICY IF EXISTS menu_ingredients_staff ON public.menu_ingredients;
CREATE POLICY menu_ingredients_staff ON public.menu_ingredients
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── MENU DISHES (public read, staff write) ──────────────────────
DROP POLICY IF EXISTS menu_dishes_select ON public.menu_dishes;
CREATE POLICY menu_dishes_select ON public.menu_dishes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS menu_dishes_staff ON public.menu_dishes;
CREATE POLICY menu_dishes_staff ON public.menu_dishes
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── DISCOUNTS (admin only) ──────────────────────────────────────
DROP POLICY IF EXISTS discounts_admin ON public.discounts;
CREATE POLICY discounts_admin ON public.discounts
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Allow authenticated users to SELECT (for discount validation at checkout)
DROP POLICY IF EXISTS discounts_select_auth ON public.discounts;
CREATE POLICY discounts_select_auth ON public.discounts
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ─── ORDERS (owner + staff) ──────────────────────────────────────
DROP POLICY IF EXISTS orders_select_own ON public.orders;
CREATE POLICY orders_select_own ON public.orders
  FOR SELECT USING (user_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS orders_insert_own ON public.orders;
CREATE POLICY orders_insert_own ON public.orders
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS orders_update ON public.orders;
CREATE POLICY orders_update ON public.orders
  FOR UPDATE USING (user_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS orders_admin ON public.orders;
CREATE POLICY orders_admin ON public.orders
  FOR DELETE USING (public.is_admin());

-- ─── ORDER MENUS (follow order access) ───────────────────────────
DROP POLICY IF EXISTS order_menus_select ON public.order_menus;
CREATE POLICY order_menus_select ON public.order_menus
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND (user_id = auth.uid() OR public.is_staff()))
  );

DROP POLICY IF EXISTS order_menus_insert ON public.order_menus;
CREATE POLICY order_menus_insert ON public.order_menus
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND user_id = auth.uid())
  );

DROP POLICY IF EXISTS order_menus_staff ON public.order_menus;
CREATE POLICY order_menus_staff ON public.order_menus
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── ORDER TAGS (staff only) ─────────────────────────────────────
DROP POLICY IF EXISTS order_tags_select ON public.order_tags;
CREATE POLICY order_tags_select ON public.order_tags
  FOR SELECT USING (public.is_staff());

DROP POLICY IF EXISTS order_tags_staff ON public.order_tags;
CREATE POLICY order_tags_staff ON public.order_tags
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── ORDER ORDER TAGS (staff only) ───────────────────────────────
DROP POLICY IF EXISTS order_order_tags_staff ON public.order_order_tags;
CREATE POLICY order_order_tags_staff ON public.order_order_tags
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── ORDER STATUS HISTORY (owner read + staff full) ──────────────
DROP POLICY IF EXISTS osh_select ON public.order_status_history;
CREATE POLICY osh_select ON public.order_status_history
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND (user_id = auth.uid() OR public.is_staff()))
  );

DROP POLICY IF EXISTS osh_staff ON public.order_status_history;
CREATE POLICY osh_staff ON public.order_status_history
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── DELIVERY ASSIGNMENTS (staff + delivery person) ──────────────
DROP POLICY IF EXISTS delivery_select ON public.delivery_assignments;
CREATE POLICY delivery_select ON public.delivery_assignments
  FOR SELECT USING (delivery_person_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS delivery_staff ON public.delivery_assignments;
CREATE POLICY delivery_staff ON public.delivery_assignments
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- Delivery person can update own assignments (mark picked_up, delivered)
DROP POLICY IF EXISTS delivery_update_own ON public.delivery_assignments;
CREATE POLICY delivery_update_own ON public.delivery_assignments
  FOR UPDATE USING (delivery_person_id = auth.uid());

-- ─── LOYALTY ACCOUNTS (owner + admin) ────────────────────────────
DROP POLICY IF EXISTS loyalty_select_own ON public.loyalty_accounts;
CREATE POLICY loyalty_select_own ON public.loyalty_accounts
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS loyalty_admin ON public.loyalty_accounts;
CREATE POLICY loyalty_admin ON public.loyalty_accounts
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── LOYALTY TRANSACTIONS (owner + admin) ────────────────────────
DROP POLICY IF EXISTS loyalty_txn_select ON public.loyalty_transactions;
CREATE POLICY loyalty_txn_select ON public.loyalty_transactions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.loyalty_accounts WHERE id = loyalty_account_id AND (user_id = auth.uid() OR public.is_admin()))
  );

DROP POLICY IF EXISTS loyalty_txn_admin ON public.loyalty_transactions;
CREATE POLICY loyalty_txn_admin ON public.loyalty_transactions
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── REVIEWS (public approved, owner own, staff all) ─────────────
DROP POLICY IF EXISTS reviews_select ON public.reviews;
CREATE POLICY reviews_select ON public.reviews
  FOR SELECT USING (status = 'approved' OR user_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS reviews_insert_own ON public.reviews;
CREATE POLICY reviews_insert_own ON public.reviews
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS reviews_update_own ON public.reviews;
CREATE POLICY reviews_update_own ON public.reviews
  FOR UPDATE USING (user_id = auth.uid() AND status = 'pending');

DROP POLICY IF EXISTS reviews_staff ON public.reviews;
CREATE POLICY reviews_staff ON public.reviews
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── REVIEW IMAGES (follow review access) ────────────────────────
DROP POLICY IF EXISTS review_images_select ON public.review_images;
CREATE POLICY review_images_select ON public.review_images
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.reviews WHERE id = review_id AND (status = 'approved' OR user_id = auth.uid() OR public.is_staff()))
  );

DROP POLICY IF EXISTS review_images_insert ON public.review_images;
CREATE POLICY review_images_insert ON public.review_images
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.reviews WHERE id = review_id AND user_id = auth.uid())
  );

DROP POLICY IF EXISTS review_images_staff ON public.review_images;
CREATE POLICY review_images_staff ON public.review_images
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── PROMOTIONS (public see active public, admin write) ──────────
DROP POLICY IF EXISTS promotions_select_public ON public.promotions;
CREATE POLICY promotions_select_public ON public.promotions
  FOR SELECT USING (
    (is_public AND is_active AND (start_date IS NULL OR start_date <= now()) AND (end_date IS NULL OR end_date >= now()))
    OR public.is_admin()
  );

DROP POLICY IF EXISTS promotions_admin ON public.promotions;
CREATE POLICY promotions_admin ON public.promotions
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── USER PROMOTIONS (owner + admin) ─────────────────────────────
DROP POLICY IF EXISTS user_promo_select_own ON public.user_promotions;
CREATE POLICY user_promo_select_own ON public.user_promotions
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS user_promo_update_own ON public.user_promotions;
CREATE POLICY user_promo_update_own ON public.user_promotions
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_promo_admin ON public.user_promotions;
CREATE POLICY user_promo_admin ON public.user_promotions
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── MESSAGES (sender + recipient) ───────────────────────────────
DROP POLICY IF EXISTS messages_select_own ON public.messages;
CREATE POLICY messages_select_own ON public.messages
  FOR SELECT USING (sender_id = auth.uid() OR recipient_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS messages_insert ON public.messages;
CREATE POLICY messages_insert ON public.messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS messages_update_own ON public.messages;
CREATE POLICY messages_update_own ON public.messages
  FOR UPDATE USING (recipient_id = auth.uid());

DROP POLICY IF EXISTS messages_admin ON public.messages;
CREATE POLICY messages_admin ON public.messages
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── NOTIFICATIONS (owner + admin) ───────────────────────────────
DROP POLICY IF EXISTS notifications_select_own ON public.notifications;
CREATE POLICY notifications_select_own ON public.notifications
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS notifications_update_own ON public.notifications;
CREATE POLICY notifications_update_own ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS notifications_admin ON public.notifications;
CREATE POLICY notifications_admin ON public.notifications
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── CONTACT MESSAGES (anyone can insert, admin read) ────────────
DROP POLICY IF EXISTS contact_insert ON public.contact_messages;
CREATE POLICY contact_insert ON public.contact_messages
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS contact_select_admin ON public.contact_messages;
CREATE POLICY contact_select_admin ON public.contact_messages
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS contact_admin ON public.contact_messages;
CREATE POLICY contact_admin ON public.contact_messages
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── SUPPORT TICKETS (creator + assigned + admin) ────────────────
DROP POLICY IF EXISTS tickets_select ON public.support_tickets;
CREATE POLICY tickets_select ON public.support_tickets
  FOR SELECT USING (user_id = auth.uid() OR assigned_to = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS tickets_staff ON public.support_tickets;
CREATE POLICY tickets_staff ON public.support_tickets
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── TICKET MESSAGES (follow ticket access) ──────────────────────
DROP POLICY IF EXISTS ticket_msg_select ON public.ticket_messages;
CREATE POLICY ticket_msg_select ON public.ticket_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets
      WHERE id = ticket_id AND (user_id = auth.uid() OR assigned_to = auth.uid() OR public.is_staff())
    )
  );

DROP POLICY IF EXISTS ticket_msg_insert ON public.ticket_messages;
CREATE POLICY ticket_msg_insert ON public.ticket_messages
  FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS ticket_msg_staff ON public.ticket_messages;
CREATE POLICY ticket_msg_staff ON public.ticket_messages
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── KANBAN COLUMNS (staff only) ─────────────────────────────────
DROP POLICY IF EXISTS kanban_select ON public.kanban_columns;
CREATE POLICY kanban_select ON public.kanban_columns
  FOR SELECT USING (public.is_staff());

DROP POLICY IF EXISTS kanban_staff ON public.kanban_columns;
CREATE POLICY kanban_staff ON public.kanban_columns
  FOR ALL USING (public.is_staff())
  WITH CHECK (public.is_staff());

-- ─── NEWSLETTER SUBSCRIBERS (self + admin) ───────────────────────
DROP POLICY IF EXISTS newsletter_sub_insert ON public.newsletter_subscribers;
CREATE POLICY newsletter_sub_insert ON public.newsletter_subscribers
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS newsletter_sub_select ON public.newsletter_subscribers;
CREATE POLICY newsletter_sub_select ON public.newsletter_subscribers
  FOR SELECT USING (
    (user_id IS NOT NULL AND user_id = auth.uid()) OR public.is_admin()
  );

DROP POLICY IF EXISTS newsletter_sub_admin ON public.newsletter_subscribers;
CREATE POLICY newsletter_sub_admin ON public.newsletter_subscribers
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── NEWSLETTER SEND LOGS (admin only) ───────────────────────────
DROP POLICY IF EXISTS newsletter_logs_admin ON public.newsletter_send_logs;
CREATE POLICY newsletter_logs_admin ON public.newsletter_send_logs
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── DATA DELETION REQUESTS (owner + admin) ──────────────────────
DROP POLICY IF EXISTS ddr_select_own ON public.data_deletion_requests;
CREATE POLICY ddr_select_own ON public.data_deletion_requests
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS ddr_insert_own ON public.data_deletion_requests;
CREATE POLICY ddr_insert_own ON public.data_deletion_requests
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS ddr_admin ON public.data_deletion_requests;
CREATE POLICY ddr_admin ON public.data_deletion_requests
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── USER CONSENTS (owner + admin) ───────────────────────────────
DROP POLICY IF EXISTS consent_select_own ON public.user_consents;
CREATE POLICY consent_select_own ON public.user_consents
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS consent_insert_own ON public.user_consents;
CREATE POLICY consent_insert_own ON public.user_consents
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS consent_update_own ON public.user_consents;
CREATE POLICY consent_update_own ON public.user_consents
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS consent_admin ON public.user_consents;
CREATE POLICY consent_admin ON public.user_consents
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── USER SESSIONS (owner + admin) ───────────────────────────────
DROP POLICY IF EXISTS sessions_select_own ON public.user_sessions;
CREATE POLICY sessions_select_own ON public.user_sessions
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS sessions_own ON public.user_sessions;
CREATE POLICY sessions_own ON public.user_sessions
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS sessions_admin ON public.user_sessions;
CREATE POLICY sessions_admin ON public.user_sessions
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── USER ADDRESSES (owner + admin) ──────────────────────────────
DROP POLICY IF EXISTS addresses_select_own ON public.user_addresses;
CREATE POLICY addresses_select_own ON public.user_addresses
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS addresses_own ON public.user_addresses;
CREATE POLICY addresses_own ON public.user_addresses
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ─── PASSWORD RESET TOKENS (admin only — users go through GoTrue) ─
DROP POLICY IF EXISTS prt_admin ON public.password_reset_tokens;
CREATE POLICY prt_admin ON public.password_reset_tokens
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── EVENTS (owner + creator + staff read, admin write) ──────────
DROP POLICY IF EXISTS events_select ON public.events;
CREATE POLICY events_select ON public.events
  FOR SELECT USING (user_id = auth.uid() OR created_by = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS events_admin ON public.events;
CREATE POLICY events_admin ON public.events
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── TIME OFF REQUESTS (owner + staff) ───────────────────────────
DROP POLICY IF EXISTS timeoff_select ON public.time_off_requests;
CREATE POLICY timeoff_select ON public.time_off_requests
  FOR SELECT USING (user_id = auth.uid() OR public.is_staff());

DROP POLICY IF EXISTS timeoff_insert_own ON public.time_off_requests;
CREATE POLICY timeoff_insert_own ON public.time_off_requests
  FOR INSERT WITH CHECK (user_id = auth.uid() AND public.is_staff());

DROP POLICY IF EXISTS timeoff_admin ON public.time_off_requests;
CREATE POLICY timeoff_admin ON public.time_off_requests
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── GRANT ALL DOMAIN TABLES TO anon AND authenticated ───────────
-- anon: limited SELECT on public tables
-- authenticated: full CRUD (policies enforce actual access)

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    AND tablename IN (
      'profiles', 'companies', 'working_hours', 'company_owners', 'company_working_hours',
      'allergens', 'diets', 'themes', 'ingredients',
      'dishes', 'dish_allergens', 'dish_ingredients',
      'menus', 'menu_images', 'menu_ingredients', 'menu_dishes',
      'discounts', 'orders', 'order_menus', 'order_tags', 'order_order_tags', 'order_status_history',
      'delivery_assignments',
      'loyalty_accounts', 'loyalty_transactions',
      'reviews', 'review_images',
      'promotions', 'user_promotions',
      'messages', 'notifications', 'contact_messages', 'support_tickets', 'ticket_messages',
      'kanban_columns',
      'newsletter_subscribers', 'newsletter_send_logs',
      'data_deletion_requests', 'user_consents', 'user_sessions', 'user_addresses',
      'password_reset_tokens', 'events', 'time_off_requests'
    )
  LOOP
    EXECUTE format('GRANT SELECT ON public.%I TO anon', tbl);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', tbl);
  END LOOP;
END $$;
