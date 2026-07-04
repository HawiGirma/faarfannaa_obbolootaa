-- ============================================================
-- NOTES TABLE MIGRATION
-- Add note-taking functionality to the app
-- Run in Supabase SQL Editor
-- ============================================================

-- ══════════════════════════════════════════════════════════
-- STEP 1: Create notes table
-- ══════════════════════════════════════════════════════════

create table if not exists public.notes (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.users(id) on delete cascade,
  title        text not null default 'Untitled',
  content      text not null default '',
  color        text not null default '#FFFFFF',
  is_pinned    boolean not null default false,
  is_archived  boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  
  constraint valid_title check (char_length(title) <= 200)
);

comment on table public.notes is 'User notes with rich content support';
comment on column public.notes.color is 'Hex color code for note background';
comment on column public.notes.is_pinned is 'Pinned notes appear at the top';
comment on column public.notes.is_archived is 'Archived notes are hidden from main view';

-- ══════════════════════════════════════════════════════════
-- STEP 2: Create indexes for better performance
-- ══════════════════════════════════════════════════════════

create index idx_notes_user_id on public.notes(user_id);
create index idx_notes_created_at on public.notes(created_at desc);
create index idx_notes_updated_at on public.notes(updated_at desc);
create index idx_notes_pinned on public.notes(is_pinned) where is_pinned = true;
create index idx_notes_active on public.notes(user_id, is_archived) where is_archived = false;

-- ══════════════════════════════════════════════════════════
-- STEP 3: Create function to auto-update updated_at
-- ══════════════════════════════════════════════════════════

create or replace function public.update_notes_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ══════════════════════════════════════════════════════════
-- STEP 4: Create trigger for auto-updating timestamp
-- ══════════════════════════════════════════════════════════

create trigger notes_updated_at_trigger
  before update on public.notes
  for each row
  execute function public.update_notes_updated_at();

-- ══════════════════════════════════════════════════════════
-- STEP 5: Enable RLS on notes table
-- ══════════════════════════════════════════════════════════

alter table public.notes enable row level security;

-- ══════════════════════════════════════════════════════════
-- STEP 6: Create RLS policies
-- ══════════════════════════════════════════════════════════

-- Users can read their own notes
create policy "notes: read own"
  on public.notes for select
  using (auth.uid() = user_id);

-- Users can insert their own notes
create policy "notes: insert own"
  on public.notes for insert
  with check (auth.uid() = user_id);

-- Users can update their own notes
create policy "notes: update own"
  on public.notes for update
  using (auth.uid() = user_id);

-- Users can delete their own notes
create policy "notes: delete own"
  on public.notes for delete
  using (auth.uid() = user_id);

-- Admins can read all notes
create policy "notes: admin read all"
  on public.notes for select
  using (public.is_admin());

-- ══════════════════════════════════════════════════════════
-- STEP 7: Verify setup
-- ══════════════════════════════════════════════════════════

select 'Notes table migration complete!' as status;

select 'Table created:' as info;
select table_name 
from information_schema.tables 
where table_schema = 'public' 
  and table_name = 'notes';

-- ══════════════════════════════════════════════════════════
-- DONE
-- ══════════════════════════════════════════════════════════
