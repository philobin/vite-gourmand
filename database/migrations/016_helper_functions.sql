-- 016_helper_functions.sql
-- Helper functions for RLS policies and business logic

-- Get current user's app_role from profiles
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT app_role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if current user is admin (superadmin or admin)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND app_role IN ('superadmin', 'admin')
      AND is_active = true
      AND is_deleted = false
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if current user is staff (superadmin, admin, or employee)
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND app_role IN ('superadmin', 'admin', 'employee')
      AND is_active = true
      AND is_deleted = false
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if current user owns a resource
CREATE OR REPLACE FUNCTION public.is_owner(resource_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT auth.uid() = resource_user_id;
$$ LANGUAGE SQL STABLE;
