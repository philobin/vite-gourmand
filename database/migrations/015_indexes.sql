-- 015_indexes.sql
-- All performance indexes from the original Prisma schema

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles (email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles (app_role);

-- Company
CREATE INDEX IF NOT EXISTS idx_company_active ON public.companies (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_company_owner_user ON public.company_owners (user_id);

-- Contact
CREATE INDEX IF NOT EXISTS idx_contact_date ON public.contact_messages (created_at DESC);

-- Dishes
CREATE INDEX IF NOT EXISTS idx_dish_course ON public.dishes (course_type);
CREATE INDEX IF NOT EXISTS idx_dish_allergen_allergen ON public.dish_allergens (allergen_id);

-- Events
CREATE INDEX IF NOT EXISTS idx_event_creator ON public.events (created_by);
CREATE INDEX IF NOT EXISTS idx_event_date ON public.events (start_date DESC);

-- Loyalty
CREATE INDEX IF NOT EXISTS idx_loyalty_user ON public.loyalty_accounts (user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_txn_account ON public.loyalty_transactions (loyalty_account_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_txn_order ON public.loyalty_transactions (order_id);

-- Menus
CREATE INDEX IF NOT EXISTS idx_menu_status ON public.menus (status);
CREATE INDEX IF NOT EXISTS idx_menu_title ON public.menus (title);

-- Newsletter (partial index)
CREATE INDEX IF NOT EXISTS idx_newsletter_active ON public.newsletter_subscribers (email)
  WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_newsletter_email ON public.newsletter_subscribers (email);
CREATE INDEX IF NOT EXISTS idx_newsletter_user ON public.newsletter_subscribers (user_id);

-- Orders
CREATE INDEX IF NOT EXISTS idx_order_delivery ON public.orders (delivery_date);
CREATE INDEX IF NOT EXISTS idx_order_number ON public.orders (order_number);
CREATE INDEX IF NOT EXISTS idx_order_status ON public.orders (status);
CREATE INDEX IF NOT EXISTS idx_order_user_date ON public.orders (user_id, order_date);
CREATE INDEX IF NOT EXISTS idx_order_menu_menu ON public.order_menus (menu_id);
CREATE INDEX IF NOT EXISTS idx_osh_order ON public.order_status_history (order_id);

-- Promotions (partial indexes)
CREATE INDEX IF NOT EXISTS idx_promotion_active_dates ON public.promotions (start_date, end_date)
  WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_promotion_public ON public.promotions (is_public)
  WHERE is_public = true;

-- Reviews
CREATE INDEX IF NOT EXISTS idx_review_status ON public.reviews (status);
CREATE INDEX IF NOT EXISTS idx_review_user ON public.reviews (user_id);

-- Sessions & tokens
CREATE INDEX IF NOT EXISTS idx_session_token ON public.user_sessions (session_token);
CREATE INDEX IF NOT EXISTS idx_prt_token ON public.password_reset_tokens (token);

-- User addresses & consents
CREATE INDEX IF NOT EXISTS idx_user_address_user ON public.user_addresses (user_id);
CREATE INDEX IF NOT EXISTS idx_consent_user ON public.user_consents (user_id);

-- User promotions
CREATE INDEX IF NOT EXISTS idx_user_promotion_user ON public.user_promotions (user_id);
CREATE INDEX IF NOT EXISTS idx_user_promotion_promo ON public.user_promotions (promotion_id);

-- Delivery
CREATE INDEX IF NOT EXISTS idx_delivery_order ON public.delivery_assignments (order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_person ON public.delivery_assignments (delivery_person_id);

-- Support tickets
CREATE INDEX IF NOT EXISTS idx_ticket_status ON public.support_tickets (status);
CREATE INDEX IF NOT EXISTS idx_ticket_user ON public.support_tickets (user_id);

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notification_user ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notification_read ON public.notifications (user_id, is_read) WHERE is_read = false;

-- Messages
CREATE INDEX IF NOT EXISTS idx_message_recipient ON public.messages (recipient_id);
CREATE INDEX IF NOT EXISTS idx_message_sender ON public.messages (sender_id);
