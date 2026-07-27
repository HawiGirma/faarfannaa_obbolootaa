-- Add rich_title column to support formatted titles
ALTER TABLE notes ADD COLUMN IF NOT EXISTS rich_title JSONB;

-- Add index for rich_title
CREATE INDEX IF NOT EXISTS idx_notes_rich_title ON notes USING GIN (rich_title);

-- Update existing notes to have null rich_title (will use plain text title as fallback)
-- No action needed as NULL is default
