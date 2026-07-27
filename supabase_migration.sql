-- ═══════════════════════════════════════════════════════════════════════════
-- FAARFANNA OBBOLOOTAA DATABASE MIGRATION
-- Purpose: Add phone authentication + secure RLS policies
-- ═══════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────
-- 1. Update users table to support phone authentication
-- ───────────────────────────────────────────────────────────────────────────

-- Add phone_number column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone_number TEXT UNIQUE;

-- Add index for faster phone lookups
CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users(phone_number);

-- Add check constraint for phone format (E.164 format)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'check_phone_format' 
    AND conrelid = 'users'::regclass
  ) THEN
    ALTER TABLE users 
    ADD CONSTRAINT check_phone_format 
    CHECK (phone_number IS NULL OR phone_number ~ '^\+[1-9]\d{1,14}$');
  END IF;
END $$;

-- Add updated_at column for tracking changes
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- ───────────────────────────────────────────────────────────────────────────
-- 2. Ensure notes table has proper structure
-- ───────────────────────────────────────────────────────────────────────────

-- Create notes table if it doesn't exist
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'Untitled',
  content TEXT NOT NULL DEFAULT '',
  color TEXT NOT NULL DEFAULT '#FFFFFF',
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for faster user queries
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_archived ON notes(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at DESC);

-- ───────────────────────────────────────────────────────────────────────────
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ───────────────────────────────────────────────────────────────────────────

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Enable RLS on notes table
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- ───────────────────────────────────────────────────────────────────────────
-- 4. RLS POLICIES FOR USERS TABLE
-- ───────────────────────────────────────────────────────────────────────────

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Service role can insert users" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;

-- Policy: Users can read their own profile
CREATE POLICY "Users can view their own profile"
ON users FOR SELECT
USING (auth.uid() = id);

-- Policy: Users can update their own profile (except is_admin field)
CREATE POLICY "Users can update their own profile"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id 
  AND (is_admin = (SELECT is_admin FROM users WHERE id = auth.uid()))
);

-- Policy: Service role can insert new users (for signups)
CREATE POLICY "Service role can insert users"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Policy: Admins can view all users
CREATE POLICY "Admins can view all users"
ON users FOR SELECT
USING (
  (SELECT is_admin FROM users WHERE id = auth.uid()) = TRUE
);

-- ───────────────────────────────────────────────────────────────────────────
-- 5. RLS POLICIES FOR NOTES TABLE
-- ───────────────────────────────────────────────────────────────────────────

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own notes" ON notes;
DROP POLICY IF EXISTS "Users can create their own notes" ON notes;
DROP POLICY IF EXISTS "Users can update their own notes" ON notes;
DROP POLICY IF EXISTS "Users can delete their own notes" ON notes;

-- Policy: Users can only view their own notes
CREATE POLICY "Users can view their own notes"
ON notes FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can create notes (user_id must match auth.uid())
CREATE POLICY "Users can create their own notes"
ON notes FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update only their own notes
CREATE POLICY "Users can update their own notes"
ON notes FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete only their own notes
CREATE POLICY "Users can delete their own notes"
ON notes FOR DELETE
USING (auth.uid() = user_id);

-- ───────────────────────────────────────────────────────────────────────────
-- 6. TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES
-- ───────────────────────────────────────────────────────────────────────────

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for notes table
DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
CREATE TRIGGER update_notes_updated_at
BEFORE UPDATE ON notes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ───────────────────────────────────────────────────────────────────────────
-- 7. DATA MIGRATION (IF NEEDED)
-- ───────────────────────────────────────────────────────────────────────────

-- Extract phone from generated emails like "251912345678@faarfanna.app"
UPDATE users 
SET phone_number = '+' || SPLIT_PART(email, '@', 1)
WHERE email LIKE '%@faarfanna.app' 
  AND phone_number IS NULL
  AND SPLIT_PART(email, '@', 1) ~ '^[0-9]+$';

-- ───────────────────────────────────────────────────────────────────────────
-- 8. VERIFICATION QUERIES (Run separately to check results)
-- ───────────────────────────────────────────────────────────────────────────

-- Verify RLS is enabled
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('users', 'notes');

-- Verify policies exist
-- SELECT schemaname, tablename, policyname FROM pg_policies WHERE tablename IN ('users', 'notes');

-- ═══════════════════════════════════════════════════════════════════════════
-- END OF MIGRATION
-- ═══════════════════════════════════════════════════════════════════════════
