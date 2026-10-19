-- 018_business_logic.sql
-- All business logic as PL/pgSQL functions callable via PostgREST RPC
-- POST /rest/v1/rpc/<function_name>

-- ─── HELPERS ──────────────────────────────────────────────────────

-- Generate order number: VG-YYYYMMDD-RANDOM6
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TEXT AS $$
DECLARE
  d TEXT;
  r TEXT;
BEGIN
  d := to_char(now(), 'YYYYMMDD');
  r := upper(substr(md5(random()::text), 1, 6));
  RETURN 'VG-' || d || '-' || r;
END;
$$ LANGUAGE plpgsql;

-- Generate ticket number: TKYYYYMM-RANDOM6
CREATE OR REPLACE FUNCTION public.generate_ticket_number()
RETURNS TEXT AS $$
DECLARE
  d TEXT;
  r TEXT;
BEGIN
  d := to_char(now(), 'YYYYMM');
  r := upper(substr(md5(random()::text), 1, 6));
  RETURN 'TK' || d || '-' || r;
END;
$$ LANGUAGE plpgsql;

-- ─── ORDER: CREATE ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.create_order(
  p_menu_ids          UUID[],
  p_menu_quantities   INTEGER[] DEFAULT NULL,
  p_delivery_date     DATE DEFAULT NULL,
  p_delivery_hour     TEXT DEFAULT NULL,
  p_delivery_address  TEXT DEFAULT NULL,
  p_delivery_city     TEXT DEFAULT 'Bordeaux',
  p_person_number     INTEGER DEFAULT NULL,
  p_special_instructions TEXT DEFAULT NULL,
  p_material_lending  BOOLEAN DEFAULT false,
  p_discount_code     TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id    UUID;
  v_order_id   UUID;
  v_order_num  TEXT;
  v_menu_price NUMERIC(10,2) := 0;
  v_delivery_price NUMERIC(10,2) := 0;
  v_discount_id UUID;
  v_discount_percent NUMERIC(5,2) := 0;
  v_discount_amount NUMERIC(10,2) := 0;
  v_total      NUMERIC(10,2);
  v_menu_id    UUID;
  v_qty        INTEGER;
  v_price      NUMERIC(10,2);
  i            INTEGER;
  v_material_deadline DATE;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'P0001';
  END IF;

  -- Default quantities to 1 each
  IF p_menu_quantities IS NULL THEN
    p_menu_quantities := array_fill(1, ARRAY[array_length(p_menu_ids, 1)]);
  END IF;

  -- Calculate menu price
  FOR i IN 1..array_length(p_menu_ids, 1) LOOP
    v_menu_id := p_menu_ids[i];
    v_qty := COALESCE(p_menu_quantities[i], 1);

    SELECT price_per_person INTO v_price FROM public.menus WHERE id = v_menu_id AND status = 'published';
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Menu % not found or not published', v_menu_id USING ERRCODE = 'P0002';
    END IF;

    v_menu_price := v_menu_price + (COALESCE(v_price, 0) * COALESCE(p_person_number, 1) * v_qty);
  END LOOP;

  -- Apply discount if provided
  IF p_discount_code IS NOT NULL THEN
    SELECT id INTO v_discount_id FROM public.discounts WHERE code = p_discount_code AND is_active = true;
    IF FOUND THEN
      PERFORM public.validate_discount(p_discount_code, v_menu_price + v_delivery_price);
      SELECT
        CASE WHEN type = 'percentage' THEN value ELSE 0 END,
        CASE WHEN type = 'percentage' THEN (v_menu_price * value / 100) ELSE value END
      INTO v_discount_percent, v_discount_amount
      FROM public.discounts WHERE id = v_discount_id;
    END IF;
  END IF;

  v_total := v_menu_price + v_delivery_price - v_discount_amount;
  IF v_total < 0 THEN v_total := 0; END IF;

  v_order_num := public.generate_order_number();

  -- Material return deadline: 7 days after delivery
  IF p_material_lending AND p_delivery_date IS NOT NULL THEN
    v_material_deadline := p_delivery_date + INTERVAL '7 days';
  END IF;

  INSERT INTO public.orders (
    order_number, user_id, delivery_date, delivery_hour, delivery_address,
    delivery_city, person_number, menu_price, delivery_price,
    discount_id, discount_percent, discount_amount, total_price,
    status, material_lending, material_return_deadline, special_instructions
  ) VALUES (
    v_order_num, v_user_id, p_delivery_date, p_delivery_hour, p_delivery_address,
    p_delivery_city, p_person_number, v_menu_price, v_delivery_price,
    v_discount_id, v_discount_percent, v_discount_amount, v_total,
    'pending', p_material_lending, v_material_deadline, p_special_instructions
  ) RETURNING id INTO v_order_id;

  -- Link menus
  FOR i IN 1..array_length(p_menu_ids, 1) LOOP
    INSERT INTO public.order_menus (order_id, menu_id, quantity)
    VALUES (v_order_id, p_menu_ids[i], COALESCE(p_menu_quantities[i], 1));
  END LOOP;

  -- Record initial status
  INSERT INTO public.order_status_history (order_id, old_status, new_status, notes)
  VALUES (v_order_id, NULL, 'pending', 'Order created');

  -- Increment discount usage
  IF v_discount_id IS NOT NULL THEN
    UPDATE public.discounts SET current_uses = current_uses + 1 WHERE id = v_discount_id;
  END IF;

  RETURN jsonb_build_object(
    'id', v_order_id,
    'order_number', v_order_num,
    'total_price', v_total,
    'status', 'pending'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── ORDER: UPDATE STATUS (state machine) ────────────────────────

CREATE OR REPLACE FUNCTION public.update_order_status(
  p_order_id   UUID,
  p_new_status TEXT,
  p_notes      TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_current_status TEXT;
  v_order_user_id  UUID;
  v_valid_transitions JSONB := '{
    "pending": ["accepted", "cancelled"],
    "accepted": ["preparing", "cancelled"],
    "preparing": ["ready", "delivering"],
    "ready": ["delivering"],
    "delivering": ["delivered"],
    "delivered": ["awaiting_material_return", "completed"],
    "awaiting_material_return": ["completed"]
  }'::JSONB;
  v_allowed JSONB;
BEGIN
  -- Must be staff
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Access denied: staff role required' USING ERRCODE = 'P0001';
  END IF;

  SELECT status, user_id INTO v_current_status, v_order_user_id
  FROM public.orders WHERE id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found' USING ERRCODE = 'P0002';
  END IF;

  -- Validate transition
  v_allowed := v_valid_transitions -> v_current_status;
  IF v_allowed IS NULL OR NOT v_allowed ? p_new_status THEN
    RAISE EXCEPTION 'Invalid status transition: % → %', v_current_status, p_new_status
      USING ERRCODE = 'P0003';
  END IF;

  -- Update order
  UPDATE public.orders SET
    status = p_new_status,
    confirmed_at = CASE WHEN p_new_status = 'accepted' THEN now() ELSE confirmed_at END,
    delivered_at = CASE WHEN p_new_status = 'delivered' THEN now() ELSE delivered_at END,
    updated_at = now()
  WHERE id = p_order_id;

  -- Record history
  INSERT INTO public.order_status_history (order_id, old_status, new_status, notes)
  VALUES (p_order_id, v_current_status, p_new_status, p_notes);

  -- Auto-earn loyalty points on completion
  IF p_new_status = 'completed' THEN
    PERFORM public.earn_loyalty_points(
      v_order_user_id,
      p_order_id,
      (SELECT total_price FROM public.orders WHERE id = p_order_id)
    );
  END IF;

  RETURN jsonb_build_object(
    'id', p_order_id,
    'old_status', v_current_status,
    'new_status', p_new_status
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── ORDER: CANCEL ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.cancel_order(
  p_order_id UUID,
  p_reason   TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_status  TEXT;
  v_user_id UUID;
BEGIN
  SELECT status, user_id INTO v_status, v_user_id
  FROM public.orders WHERE id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found' USING ERRCODE = 'P0002';
  END IF;

  -- Only owner or admin can cancel
  IF v_user_id != auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied' USING ERRCODE = 'P0001';
  END IF;

  -- Only cancellable from pending or accepted
  IF v_status NOT IN ('pending', 'accepted') THEN
    RAISE EXCEPTION 'Order cannot be cancelled from status: %', v_status
      USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.orders SET
    status = 'cancelled',
    cancellation_reason = p_reason,
    cancelled_at = now(),
    updated_at = now()
  WHERE id = p_order_id;

  INSERT INTO public.order_status_history (order_id, old_status, new_status, notes)
  VALUES (p_order_id, v_status, 'cancelled', COALESCE(p_reason, 'Cancelled by user'));

  RETURN jsonb_build_object('id', p_order_id, 'status', 'cancelled');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── ORDER: EDIT (only pending/accepted) ─────────────────────────

CREATE OR REPLACE FUNCTION public.edit_order(
  p_order_id           UUID,
  p_delivery_address   TEXT DEFAULT NULL,
  p_delivery_hour      TEXT DEFAULT NULL,
  p_special_instructions TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_status  TEXT;
  v_user_id UUID;
BEGIN
  SELECT status, user_id INTO v_status, v_user_id
  FROM public.orders WHERE id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_user_id != auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied' USING ERRCODE = 'P0001';
  END IF;

  IF v_status NOT IN ('pending', 'accepted') THEN
    RAISE EXCEPTION 'Order can only be edited in pending or accepted status'
      USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.orders SET
    delivery_address = COALESCE(p_delivery_address, delivery_address),
    delivery_hour = COALESCE(p_delivery_hour, delivery_hour),
    special_instructions = COALESCE(p_special_instructions, special_instructions),
    updated_at = now()
  WHERE id = p_order_id;

  RETURN jsonb_build_object('id', p_order_id, 'updated', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── DISCOUNT: VALIDATE ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.validate_discount(
  p_code         TEXT,
  p_order_amount NUMERIC DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_discount   RECORD;
  v_errors     TEXT[] := '{}';
  v_discount_amount NUMERIC := 0;
  v_final      NUMERIC;
BEGIN
  SELECT * INTO v_discount FROM public.discounts WHERE code = p_code;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Discount code not found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT v_discount.is_active THEN
    v_errors := array_append(v_errors, 'Discount code is not active');
  END IF;

  IF v_discount.valid_from IS NOT NULL AND v_discount.valid_from > now() THEN
    v_errors := array_append(v_errors, 'Discount code is not yet valid');
  END IF;

  IF v_discount.valid_until IS NOT NULL AND v_discount.valid_until < now() THEN
    v_errors := array_append(v_errors, 'Discount code has expired');
  END IF;

  IF v_discount.max_uses IS NOT NULL AND v_discount.current_uses >= v_discount.max_uses THEN
    v_errors := array_append(v_errors, 'Discount code has reached maximum uses');
  END IF;

  IF v_discount.min_order_amount IS NOT NULL AND p_order_amount IS NOT NULL
     AND p_order_amount < v_discount.min_order_amount THEN
    v_errors := array_append(v_errors, format('Minimum order amount is %s€', v_discount.min_order_amount));
  END IF;

  IF array_length(v_errors, 1) > 0 THEN
    RAISE EXCEPTION '%', array_to_string(v_errors, '. ') USING ERRCODE = 'P0003';
  END IF;

  -- Calculate discount
  IF p_order_amount IS NOT NULL THEN
    IF v_discount.type = 'percentage' THEN
      v_discount_amount := (p_order_amount * v_discount.value) / 100;
    ELSE
      v_discount_amount := v_discount.value;
    END IF;
    v_final := GREATEST(p_order_amount - v_discount_amount, 0);
  END IF;

  RETURN jsonb_build_object(
    'valid', true,
    'discount', row_to_json(v_discount)::jsonb,
    'discount_amount', v_discount_amount,
    'final_amount', v_final
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ─── LOYALTY: EARN POINTS ────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.earn_loyalty_points(
  p_user_id      UUID,
  p_order_id     UUID,
  p_order_amount NUMERIC
)
RETURNS JSONB AS $$
DECLARE
  v_points     INTEGER;
  v_account_id UUID;
  v_txn_id     UUID;
  POINTS_PER_EURO CONSTANT INTEGER := 10;
BEGIN
  v_points := floor(p_order_amount * POINTS_PER_EURO);

  -- Auto-create account if missing
  INSERT INTO public.loyalty_accounts (user_id, balance, total_earned, last_activity_at)
  VALUES (p_user_id, 0, 0, now())
  ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_account_id FROM public.loyalty_accounts WHERE user_id = p_user_id;

  -- Create transaction
  INSERT INTO public.loyalty_transactions (loyalty_account_id, order_id, points, type, description)
  VALUES (v_account_id, p_order_id, v_points, 'earn', format('Points earned from order #%s', p_order_id))
  RETURNING id INTO v_txn_id;

  -- Update balance
  UPDATE public.loyalty_accounts SET
    balance = balance + v_points,
    total_earned = total_earned + v_points,
    last_activity_at = now()
  WHERE id = v_account_id;

  RETURN jsonb_build_object('points_earned', v_points, 'transaction_id', v_txn_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── LOYALTY: REDEEM POINTS ──────────────────────────────────────

CREATE OR REPLACE FUNCTION public.redeem_loyalty_points(
  p_points INTEGER
)
RETURNS JSONB AS $$
DECLARE
  v_user_id      UUID;
  v_account_id   UUID;
  v_balance      INTEGER;
  v_txn_id       UUID;
  v_discount     NUMERIC;
  POINTS_TO_EURO CONSTANT INTEGER := 100;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'P0001';
  END IF;

  SELECT id, balance INTO v_account_id, v_balance
  FROM public.loyalty_accounts WHERE user_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No loyalty account found' USING ERRCODE = 'P0002';
  END IF;

  IF v_balance < p_points THEN
    RAISE EXCEPTION 'Insufficient points balance: have %, need %', v_balance, p_points
      USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.loyalty_transactions (loyalty_account_id, points, type, description)
  VALUES (v_account_id, -p_points, 'redeem', format('Redeemed %s points', p_points))
  RETURNING id INTO v_txn_id;

  UPDATE public.loyalty_accounts SET
    balance = balance - p_points,
    total_spent = total_spent + p_points,
    last_activity_at = now()
  WHERE id = v_account_id;

  v_discount := p_points::NUMERIC / POINTS_TO_EURO;

  RETURN jsonb_build_object(
    'transaction_id', v_txn_id,
    'points_redeemed', p_points,
    'discount_value', v_discount
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── LOYALTY: ADMIN BONUS ────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_bonus_points(
  p_user_id    UUID,
  p_points     INTEGER,
  p_description TEXT DEFAULT 'Admin bonus'
)
RETURNS JSONB AS $$
DECLARE
  v_account_id UUID;
  v_txn_id     UUID;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required' USING ERRCODE = 'P0001';
  END IF;

  -- Auto-create account
  INSERT INTO public.loyalty_accounts (user_id, balance, total_earned, last_activity_at)
  VALUES (p_user_id, 0, 0, now())
  ON CONFLICT (user_id) DO NOTHING;

  SELECT id INTO v_account_id FROM public.loyalty_accounts WHERE user_id = p_user_id;

  INSERT INTO public.loyalty_transactions (loyalty_account_id, points, type, description)
  VALUES (v_account_id, p_points, 'bonus', p_description)
  RETURNING id INTO v_txn_id;

  UPDATE public.loyalty_accounts SET
    balance = balance + p_points,
    total_earned = total_earned + p_points,
    last_activity_at = now()
  WHERE id = v_account_id;

  RETURN jsonb_build_object('transaction_id', v_txn_id, 'points_added', p_points);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── MENU: PUBLISH / UNPUBLISH ───────────────────────────────────

CREATE OR REPLACE FUNCTION public.publish_menu(p_menu_id UUID)
RETURNS JSONB AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Staff access required' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.menus SET
    status = 'published',
    published_at = now(),
    updated_at = now()
  WHERE id = p_menu_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Menu not found' USING ERRCODE = 'P0002';
  END IF;

  RETURN jsonb_build_object('id', p_menu_id, 'status', 'published');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.unpublish_menu(p_menu_id UUID)
RETURNS JSONB AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Staff access required' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.menus SET
    status = 'draft',
    published_at = NULL,
    updated_at = now()
  WHERE id = p_menu_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Menu not found' USING ERRCODE = 'P0002';
  END IF;

  RETURN jsonb_build_object('id', p_menu_id, 'status', 'draft');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── REVIEW: MODERATE ────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.moderate_review(
  p_review_id UUID,
  p_status    TEXT
)
RETURNS JSONB AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Staff access required' USING ERRCODE = 'P0001';
  END IF;

  IF p_status NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'Status must be approved or rejected' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.reviews SET
    status = p_status,
    moderated_by = auth.uid(),
    moderated_at = now(),
    updated_at = now()
  WHERE id = p_review_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Review not found' USING ERRCODE = 'P0002';
  END IF;

  RETURN jsonb_build_object('id', p_review_id, 'status', p_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── REVIEW: PUBLIC STATS ────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_review_stats()
RETURNS JSONB AS $$
DECLARE
  v_avg    NUMERIC;
  v_count  BIGINT;
  v_sat    NUMERIC;
  v_total  BIGINT;
BEGIN
  SELECT avg(note), count(*) INTO v_avg, v_count
  FROM public.reviews WHERE status = 'approved';

  SELECT count(*) INTO v_total FROM public.reviews;

  IF v_total > 0 THEN
    SELECT (count(*) FILTER (WHERE note >= 4)::NUMERIC / v_total * 100)
    INTO v_sat FROM public.reviews;
  ELSE
    v_sat := 0;
  END IF;

  RETURN jsonb_build_object(
    'average_rating', round(COALESCE(v_avg, 0), 2),
    'review_count', COALESCE(v_count, 0),
    'satisfaction_percent', round(COALESCE(v_sat, 0), 1)
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ─── CONTACT: CREATE TICKET ──────────────────────────────────────

CREATE OR REPLACE FUNCTION public.create_contact_ticket(
  p_name        TEXT,
  p_email       TEXT,
  p_phone       TEXT DEFAULT NULL,
  p_title       TEXT DEFAULT 'Contact',
  p_description TEXT DEFAULT ''
)
RETURNS JSONB AS $$
DECLARE
  v_contact_id   UUID;
  v_ticket_id    UUID;
  v_ticket_num   TEXT;
  v_category     TEXT;
  v_lower_title  TEXT;
BEGIN
  -- 1. Save contact message
  INSERT INTO public.contact_messages (title, description, email)
  VALUES (p_title, p_description, p_email)
  RETURNING id INTO v_contact_id;

  -- 2. Auto-categorize
  v_lower_title := lower(p_title);
  IF v_lower_title LIKE '%mariage%' OR v_lower_title LIKE '%anniversaire%'
     OR v_lower_title LIKE '%événement%' OR v_lower_title LIKE '%entreprise%' THEN
    v_category := 'order';
  ELSIF v_lower_title LIKE '%menu%' THEN
    v_category := 'menu';
  ELSE
    v_category := 'other';
  END IF;

  -- 3. Create support ticket
  v_ticket_num := public.generate_ticket_number();

  INSERT INTO public.support_tickets (
    ticket_number, category, subject, description, priority, status
  ) VALUES (
    v_ticket_num,
    v_category,
    p_title,
    format('[Contact — %s] %s' || chr(10) || chr(10) || '—' || chr(10) || 'Email : %s' || chr(10) || 'Téléphone : %s',
           p_name, p_description, p_email, COALESCE(p_phone, 'N/A')),
    'normal',
    'open'
  ) RETURNING id INTO v_ticket_id;

  -- 4. Send emails via pg_net (async HTTP calls to email-service)
  -- Confirmation to visitor
  PERFORM public.send_contact_confirmation_email(p_email, v_ticket_num, p_name);
  -- Notification to admin
  PERFORM public.send_contact_admin_notification(v_ticket_num, p_name, p_email, COALESCE(p_phone, 'N/A'), p_title, p_description);

  RETURN jsonb_build_object(
    'contact_id', v_contact_id,
    'ticket_id', v_ticket_id,
    'ticket_number', v_ticket_num
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── DELIVERY: ASSIGN ────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.assign_delivery(
  p_order_id          UUID,
  p_delivery_person_id UUID,
  p_vehicle_type      TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_id UUID;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Staff access required' USING ERRCODE = 'P0001';
  END IF;

  -- Check order exists
  IF NOT EXISTS (SELECT 1 FROM public.orders WHERE id = p_order_id) THEN
    RAISE EXCEPTION 'Order not found' USING ERRCODE = 'P0002';
  END IF;

  -- Check no duplicate
  IF EXISTS (SELECT 1 FROM public.delivery_assignments WHERE order_id = p_order_id) THEN
    RAISE EXCEPTION 'Delivery assignment already exists for this order' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.delivery_assignments (order_id, delivery_person_id, vehicle_type)
  VALUES (p_order_id, p_delivery_person_id, p_vehicle_type)
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('id', v_id, 'status', 'assigned');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── DELIVERY: UPDATE STATUS ─────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_delivery_status(
  p_id              UUID,
  p_status          TEXT,
  p_proof_photo_url TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_current TEXT;
  v_valid   JSONB := '{
    "assigned": ["picked_up"],
    "picked_up": ["in_transit"],
    "in_transit": ["delivered", "failed"]
  }'::JSONB;
BEGIN
  SELECT status INTO v_current FROM public.delivery_assignments WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Delivery assignment not found' USING ERRCODE = 'P0002';
  END IF;

  -- Staff or the delivery person themselves
  IF NOT public.is_staff() AND (SELECT delivery_person_id FROM public.delivery_assignments WHERE id = p_id) != auth.uid() THEN
    RAISE EXCEPTION 'Access denied' USING ERRCODE = 'P0001';
  END IF;

  IF NOT (v_valid -> v_current) ? p_status THEN
    RAISE EXCEPTION 'Invalid delivery status transition: % → %', v_current, p_status
      USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.delivery_assignments SET
    status = p_status,
    picked_up_at = CASE WHEN p_status = 'picked_up' THEN now() ELSE picked_up_at END,
    delivered_at = CASE WHEN p_status = 'delivered' THEN now() ELSE delivered_at END,
    proof_photo_url = COALESCE(p_proof_photo_url, proof_photo_url)
  WHERE id = p_id;

  RETURN jsonb_build_object('id', p_id, 'status', p_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── DELIVERY: RATE ──────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.rate_delivery(
  p_id     UUID,
  p_rating INTEGER
)
RETURNS JSONB AS $$
BEGIN
  IF p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.delivery_assignments SET client_rating = p_rating WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Delivery assignment not found' USING ERRCODE = 'P0002';
  END IF;

  RETURN jsonb_build_object('id', p_id, 'client_rating', p_rating);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── GRANT EXECUTE ON ALL RPC FUNCTIONS ──────────────────────────

GRANT EXECUTE ON FUNCTION public.generate_order_number() TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_ticket_number() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_order(UUID[], INTEGER[], DATE, TEXT, TEXT, TEXT, INTEGER, TEXT, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_order_status(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_order(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.edit_order(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_discount(TEXT, NUMERIC) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.earn_loyalty_points(UUID, UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_loyalty_points(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_bonus_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.publish_menu(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unpublish_menu(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.moderate_review(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_review_stats() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_contact_ticket(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.assign_delivery(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_delivery_status(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rate_delivery(UUID, INTEGER) TO authenticated;
