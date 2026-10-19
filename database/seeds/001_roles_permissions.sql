-- 001_roles_permissions.sql
-- Seed ABAC roles and resource policies (integrates with mini-baas-infra migration 007)
-- The roles table already exists from mini-baas-infra 007_permissions_system.sql
-- We add domain-specific resource policies

-- Ensure domain roles exist (007 already seeds admin, user, guest, moderator, service_role)
INSERT INTO public.roles (name, description, is_system, metadata) VALUES
  ('superadmin', 'Full system access — developer only', true, '{"app_role": "superadmin"}'::jsonb),
  ('employee', 'Staff — menu/order/review management', true, '{"app_role": "employee"}'::jsonb)
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description, metadata = EXCLUDED.metadata;

-- Domain resource policies
-- Admin: full access to everything
INSERT INTO public.resource_policies (role_id, resource_type, resource_name, actions, effect, priority) VALUES
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'menus', '*', ARRAY['create','read','update','delete'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'orders', '*', ARRAY['create','read','update','delete','manage'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'reviews', '*', ARRAY['create','read','update','delete','moderate'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'users', '*', ARRAY['create','read','update','delete','disable'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'analytics', '*', ARRAY['read'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'settings', '*', ARRAY['read','update'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'dishes', '*', ARRAY['create','read','update','delete','manage'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'hours', '*', ARRAY['read','update','manage'], 'allow', 100),
  ((SELECT id FROM public.roles WHERE name = 'admin'), 'discounts', '*', ARRAY['create','read','update','delete'], 'allow', 100)
ON CONFLICT DO NOTHING;

-- Employee: limited access
INSERT INTO public.resource_policies (role_id, resource_type, resource_name, actions, effect, priority) VALUES
  ((SELECT id FROM public.roles WHERE name = 'employee'), 'menus', '*', ARRAY['create','read','update','delete'], 'allow', 50),
  ((SELECT id FROM public.roles WHERE name = 'employee'), 'dishes', '*', ARRAY['create','read','update','delete','manage'], 'allow', 50),
  ((SELECT id FROM public.roles WHERE name = 'employee'), 'orders', '*', ARRAY['read','update','manage'], 'allow', 50),
  ((SELECT id FROM public.roles WHERE name = 'employee'), 'reviews', '*', ARRAY['read','update','moderate'], 'allow', 50),
  ((SELECT id FROM public.roles WHERE name = 'employee'), 'hours', '*', ARRAY['read','update','manage'], 'allow', 50),
  ((SELECT id FROM public.roles WHERE name = 'employee'), 'settings', '*', ARRAY['update'], 'allow', 50)
ON CONFLICT DO NOTHING;

-- User: basic client access
INSERT INTO public.resource_policies (role_id, resource_type, resource_name, actions, effect, priority) VALUES
  ((SELECT id FROM public.roles WHERE name = 'user'), 'menus', '*', ARRAY['read'], 'allow', 10),
  ((SELECT id FROM public.roles WHERE name = 'user'), 'orders', '*', ARRAY['create','read'], 'allow', 10),
  ((SELECT id FROM public.roles WHERE name = 'user'), 'reviews', '*', ARRAY['create'], 'allow', 10)
ON CONFLICT DO NOTHING;

-- Superadmin: inherits admin + system-level
INSERT INTO public.resource_policies (role_id, resource_type, resource_name, actions, effect, priority) VALUES
  ((SELECT id FROM public.roles WHERE name = 'superadmin'), '*', '*', ARRAY['create','read','update','delete','manage','moderate','disable'], 'allow', 999)
ON CONFLICT DO NOTHING;
