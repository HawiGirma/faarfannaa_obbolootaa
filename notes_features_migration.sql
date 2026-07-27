-- Advanced Notes Features Database Migration
-- Add this to your Supabase database

-- =============================================================================
-- 1. EXTEND EXISTING NOTES TABLE
-- =============================================================================

-- Add new columns to existing notes table
ALTER TABLE notes ADD COLUMN IF NOT EXISTS rich_content JSONB;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS has_drawing BOOLEAN DEFAULT FALSE;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS has_images BOOLEAN DEFAULT FALSE;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS has_attachments BOOLEAN DEFAULT FALSE;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS has_checklist BOOLEAN DEFAULT FALSE;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS topics TEXT[] DEFAULT '{}';
ALTER TABLE notes ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE notes ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS last_viewed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS font_family TEXT;
ALTER TABLE notes ADD COLUMN IF NOT EXISTS font_size REAL;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notes_topics ON notes USING GIN (topics);
CREATE INDEX IF NOT EXISTS idx_notes_tags ON notes USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_notes_is_favorite ON notes (is_favorite);
CREATE INDEX IF NOT EXISTS idx_notes_last_viewed ON notes (last_viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_view_count ON notes (view_count DESC);

-- =============================================================================
-- 2. CREATE NOTE TOPICS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS note_topics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, name)
);

-- RLS Policies for note_topics
ALTER TABLE note_topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own topics" 
  ON note_topics FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own topics" 
  ON note_topics FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own topics" 
  ON note_topics FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own topics" 
  ON note_topics FOR DELETE 
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_note_topics_user_id ON note_topics (user_id);
CREATE INDEX IF NOT EXISTS idx_note_topics_name ON note_topics (name);

-- =============================================================================
-- 3. CREATE NOTE ATTACHMENTS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS note_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for note_attachments
ALTER TABLE note_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own attachments" 
  ON note_attachments FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own attachments" 
  ON note_attachments FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own attachments" 
  ON note_attachments FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own attachments" 
  ON note_attachments FOR DELETE 
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_note_attachments_note_id ON note_attachments (note_id);
CREATE INDEX IF NOT EXISTS idx_note_attachments_user_id ON note_attachments (user_id);
CREATE INDEX IF NOT EXISTS idx_note_attachments_file_type ON note_attachments (file_type);

-- =============================================================================
-- 4. CREATE NOTE IMAGES TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS note_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  width REAL,
  height REAL,
  position INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for note_images
ALTER TABLE note_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own images" 
  ON note_images FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own images" 
  ON note_images FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own images" 
  ON note_images FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own images" 
  ON note_images FOR DELETE 
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_note_images_note_id ON note_images (note_id);
CREATE INDEX IF NOT EXISTS idx_note_images_user_id ON note_images (user_id);
CREATE INDEX IF NOT EXISTS idx_note_images_position ON note_images (position);

-- =============================================================================
-- 5. CREATE NOTE DRAWINGS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS note_drawings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  drawing_data JSONB NOT NULL,
  thumbnail_url TEXT,
  position INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for note_drawings
ALTER TABLE note_drawings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own drawings" 
  ON note_drawings FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own drawings" 
  ON note_drawings FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own drawings" 
  ON note_drawings FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own drawings" 
  ON note_drawings FOR DELETE 
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_note_drawings_note_id ON note_drawings (note_id);
CREATE INDEX IF NOT EXISTS idx_note_drawings_user_id ON note_drawings (user_id);
CREATE INDEX IF NOT EXISTS idx_note_drawings_position ON note_drawings (position);

-- =============================================================================
-- 6. CREATE FUNCTIONS FOR AUTO-UPDATE TIMESTAMPS
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_note_topics_updated_at 
  BEFORE UPDATE ON note_topics 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_note_attachments_updated_at 
  BEFORE UPDATE ON note_attachments 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_note_drawings_updated_at 
  BEFORE UPDATE ON note_drawings 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 7. CREATE STORAGE BUCKETS (if not exists)
-- =============================================================================

-- Note: Run these in the Supabase Storage section

-- Bucket for note attachments
INSERT INTO storage.buckets (id, name, public) 
VALUES ('note-attachments', 'note-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- Bucket for note images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('note-images', 'note-images', false)
ON CONFLICT (id) DO NOTHING;

-- Bucket for drawing thumbnails
INSERT INTO storage.buckets (id, name, public) 
VALUES ('drawing-thumbnails', 'drawing-thumbnails', false)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- 8. STORAGE POLICIES
-- =============================================================================

-- Policies for note-attachments bucket
CREATE POLICY "Users can upload own attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'note-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own attachments"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'note-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own attachments"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'note-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Similar policies for note-images bucket
CREATE POLICY "Users can upload own images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'note-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own images"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'note-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'note-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policies for drawing-thumbnails bucket
CREATE POLICY "Users can upload own thumbnails"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'drawing-thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own thumbnails"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'drawing-thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own thumbnails"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'drawing-thumbnails' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =============================================================================
-- 9. GRANT PERMISSIONS
-- =============================================================================

GRANT ALL ON notes TO authenticated;
GRANT ALL ON note_topics TO authenticated;
GRANT ALL ON note_attachments TO authenticated;
GRANT ALL ON note_images TO authenticated;
GRANT ALL ON note_drawings TO authenticated;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Verify tables were created
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename LIKE 'note%'
ORDER BY tablename;
