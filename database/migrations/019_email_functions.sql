-- 019_email_functions.sql
-- Email sending via pg_net HTTP POST to the email-service
-- These functions use net.http_post() to call the email-service at runtime

-- ─── BASE: Send email via email-service ──────────────────────────

CREATE OR REPLACE FUNCTION public.send_email(
  p_to      TEXT,
  p_subject TEXT,
  p_html    TEXT
)
RETURNS BIGINT AS $$
DECLARE
  v_request_id BIGINT;
BEGIN
  SELECT net.http_post(
    url     := 'http://email-service:3030/mail/send',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key', true)
    ),
    body    := jsonb_build_object(
      'to', p_to,
      'subject', p_subject,
      'html', p_html
    )
  ) INTO v_request_id;

  RETURN v_request_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail the transaction if email sending fails
    RAISE WARNING 'Email send failed: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Password Reset Email ────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.send_password_reset_email(
  p_email TEXT,
  p_token TEXT
)
RETURNS BIGINT AS $$
DECLARE
  v_frontend_url TEXT;
  v_html TEXT;
BEGIN
  v_frontend_url := COALESCE(current_setting('app.frontend_url', true), 'http://localhost:5173');

  v_html := format(
    '<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">'
    '<div style="background:linear-gradient(135deg,#722F37,#8B3A42);padding:30px;text-align:center;border-radius:8px 8px 0 0">'
    '<h1 style="color:#fff;margin:0">Vite & Gourmand</h1></div>'
    '<div style="padding:30px;background:#fff;border:1px solid #eee">'
    '<h2 style="color:#722F37">Réinitialisation de votre mot de passe</h2>'
    '<p>Vous avez demandé la réinitialisation de votre mot de passe. Cliquez sur le bouton ci-dessous :</p>'
    '<div style="text-align:center;margin:30px 0">'
    '<a href="%s/reset-password?token=%s" style="background:#722F37;color:#fff;padding:12px 30px;text-decoration:none;border-radius:5px;display:inline-block">'
    'Réinitialiser mon mot de passe</a></div>'
    '<p style="color:#666;font-size:12px">Ce lien expire dans 1 heure. Si vous n''avez pas fait cette demande, ignorez cet email.</p>'
    '</div></div>',
    v_frontend_url, p_token
  );

  RETURN public.send_email(p_email, 'Réinitialisation de mot de passe — Vite Gourmand', v_html);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Order Confirmation Email ────────────────────────────────────

CREATE OR REPLACE FUNCTION public.send_order_confirmation_email(
  p_email        TEXT,
  p_order_number TEXT
)
RETURNS BIGINT AS $$
DECLARE
  v_html TEXT;
BEGIN
  v_html := format(
    '<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">'
    '<div style="background:linear-gradient(135deg,#722F37,#8B3A42);padding:30px;text-align:center;border-radius:8px 8px 0 0">'
    '<h1 style="color:#fff;margin:0">Vite & Gourmand</h1></div>'
    '<div style="padding:30px;background:#fff;border:1px solid #eee">'
    '<h2 style="color:#722F37">Commande confirmée !</h2>'
    '<p>Votre commande <strong>%s</strong> a bien été enregistrée.</p>'
    '<p>Nous vous tiendrons informé de l''avancement de votre commande.</p>'
    '<p style="color:#666;font-size:12px">Merci de votre confiance !</p>'
    '</div></div>',
    p_order_number
  );

  RETURN public.send_email(p_email, format('Commande confirmée — %s', p_order_number), v_html);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Contact Confirmation Email (to visitor) ─────────────────────

CREATE OR REPLACE FUNCTION public.send_contact_confirmation_email(
  p_email       TEXT,
  p_ticket_num  TEXT,
  p_name        TEXT
)
RETURNS BIGINT AS $$
DECLARE
  v_html TEXT;
BEGIN
  v_html := format(
    '<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">'
    '<div style="background:linear-gradient(135deg,#722F37,#8B3A42);padding:30px;text-align:center;border-radius:8px 8px 0 0">'
    '<h1 style="color:#fff;margin:0">Vite & Gourmand</h1></div>'
    '<div style="padding:30px;background:#fff;border:1px solid #eee">'
    '<h2 style="color:#722F37">Votre demande a bien été reçue</h2>'
    '<p>Bonjour %s,</p>'
    '<p>Nous avons bien reçu votre message. Voici votre numéro de suivi :</p>'
    '<div style="text-align:center;margin:20px 0">'
    '<span style="background:#722F37;color:#fff;padding:8px 20px;border-radius:4px;font-size:18px;font-weight:bold">%s</span></div>'
    '<p><strong>Prochaines étapes :</strong></p>'
    '<ol><li>Un membre de notre équipe examine votre demande</li>'
    '<li>Nous vous répondrons sous 24-48h</li>'
    '<li>En cas d''urgence, appelez-nous directement</li></ol>'
    '<p style="color:#666;font-size:12px">L''équipe Vite & Gourmand</p>'
    '</div></div>',
    p_name, p_ticket_num
  );

  RETURN public.send_email(p_email, format('Votre demande a bien été reçue — %s', p_ticket_num), v_html);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Contact Admin Notification ──────────────────────────────────

CREATE OR REPLACE FUNCTION public.send_contact_admin_notification(
  p_ticket_num  TEXT,
  p_name        TEXT,
  p_email       TEXT,
  p_phone       TEXT,
  p_title       TEXT,
  p_description TEXT
)
RETURNS BIGINT AS $$
DECLARE
  v_admin_email TEXT;
  v_html TEXT;
BEGIN
  v_admin_email := COALESCE(current_setting('app.admin_email', true), 'admin@vitegourmand.fr');

  v_html := format(
    '<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">'
    '<div style="background:#2c3e50;padding:20px;text-align:center;border-radius:8px 8px 0 0">'
    '<h1 style="color:#fff;margin:0">Nouveau ticket — %s</h1></div>'
    '<div style="padding:30px;background:#fff;border:1px solid #eee">'
    '<table style="width:100%%;border-collapse:collapse">'
    '<tr><td style="padding:8px;font-weight:bold;border-bottom:1px solid #eee">Nom</td><td style="padding:8px;border-bottom:1px solid #eee">%s</td></tr>'
    '<tr><td style="padding:8px;font-weight:bold;border-bottom:1px solid #eee">Email</td><td style="padding:8px;border-bottom:1px solid #eee">%s</td></tr>'
    '<tr><td style="padding:8px;font-weight:bold;border-bottom:1px solid #eee">Téléphone</td><td style="padding:8px;border-bottom:1px solid #eee">%s</td></tr>'
    '<tr><td style="padding:8px;font-weight:bold;border-bottom:1px solid #eee">Sujet</td><td style="padding:8px;border-bottom:1px solid #eee">%s</td></tr>'
    '</table>'
    '<div style="margin-top:20px;padding:15px;background:#f8f9fa;border-radius:4px">'
    '<strong>Message :</strong><br/>%s</div>'
    '</div></div>',
    p_ticket_num, p_name, p_email, p_phone, p_title, p_description
  );

  RETURN public.send_email(v_admin_email, format('[Nouveau ticket] %s — %s', p_ticket_num, p_title), v_html);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── GRANTS ──────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION public.send_email(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_password_reset_email(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_order_confirmation_email(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_contact_confirmation_email(TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.send_contact_admin_notification(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
