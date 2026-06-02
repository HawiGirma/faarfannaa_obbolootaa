-- ============================================================
-- COMPLETE SUPABASE SCHEMA WITH DATABASE FILE STORAGE
-- Run in Supabase SQL Editor
-- Dashboard → SQL Editor → New query → paste all → Run
-- ============================================================
-- This schema stores files directly in the database instead
-- of using Supabase Storage (which has issues)
-- ============================================================

-- ══════════════════════════════════════════════════════════
-- STEP 1: Clean slate — drop existing tables
-- ══════════════════════════════════════════════════════════

drop table if exists public.file_storage cascade;
drop table if exists public.songs cascade;
drop table if exists public.users cascade;
drop function if exists public.increment_play_count(uuid);
drop function if exists public.is_admin();

-- ══════════════════════════════════════════════════════════
-- STEP 2: users table
-- ══════════════════════════════════════════════════════════

create table public.users (
  id           uuid primary key,
  email        text not null unique,
  display_name text not null default 'User',
  photo_url    text,
  is_admin     boolean not null default false,
  favorite_ids text[] not null default '{}',
  created_at   timestamptz not null default now()
);

comment on table public.users is 'User accounts linked to Supabase Auth';

-- ══════════════════════════════════════════════════════════
-- STEP 3: file_storage table (replaces Supabase Storage)
-- ══════════════════════════════════════════════════════════

create table public.file_storage (
  id           uuid primary key default gen_random_uuid(),
  path         text not null unique,
  mime_type    text not null,
  size_bytes   bigint not null,
  data         text not null,  -- Base64-encoded file content
  uploaded_by  uuid references public.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  
  constraint valid_mime_type check (
    mime_type in (
      'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/aac',
      'image/jpeg', 'image/png', 'image/webp', 'image/gif'
    )
  ),
  constraint valid_size check (size_bytes > 0 and size_bytes <= 52428800)
);

comment on table public.file_storage is 'Binary file storage in database (audio, images)';
comment on column public.file_storage.data is 'Base64-encoded file content';
comment on column public.file_storage.size_bytes is 'Original file size in bytes (max 50MB)';

-- Index for faster path lookups
create index idx_file_storage_path on public.file_storage(path);
create index idx_file_storage_uploaded_by on public.file_storage(uploaded_by);

-- ══════════════════════════════════════════════════════════
-- STEP 4: songs table
-- ══════════════════════════════════════════════════════════

create table public.songs (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  artist           text not null,
  language         text not null default 'Afaan Oromo',
  lyrics           text not null default '',
  audio_url        text not null default '',
  cover_url        text not null default '',
  featured         boolean not null default false,
  play_count       integer not null default 0,
  album_name       text,
  duration_seconds integer,
  uploaded_by      uuid references public.users(id) on delete set null,
  created_at       timestamptz not null default now(),
  
  constraint valid_play_count check (play_count >= 0)
);

comment on table public.songs is 'Song metadata (URLs point to file_storage entries)';

-- Indexes for common queries
create index idx_songs_featured on public.songs(featured) where featured = true;
create index idx_songs_created_at on public.songs(created_at desc);
create index idx_songs_play_count on public.songs(play_count desc);
create index idx_songs_uploaded_by on public.songs(uploaded_by);

-- ══════════════════════════════════════════════════════════
-- STEP 5: Helper function — is current user an admin?
-- ══════════════════════════════════════════════════════════

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    (
      select is_admin
      from public.users
      where id = auth.uid()
    ),
    -- Fallback: check email directly for first-time admin login
    auth.email() in ('admin@faarfanna.com', 'admin@fo.com')
  );
$$;

comment on function public.is_admin is 'Returns true if current user is admin';

-- ══════════════════════════════════════════════════════════
-- STEP 6: RPC — atomic play count increment
-- ══════════════════════════════════════════════════════════

create or replace function public.increment_play_count(song_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.songs
  set play_count = play_count + 1
  where id = song_id;
$$;

comment on function public.increment_play_count is 'Atomically increment song play count';

-- ══════════════════════════════════════════════════════════
-- STEP 7: Enable RLS
-- ══════════════════════════════════════════════════════════

alter table public.users enable row level security;
alter table public.songs enable row level security;
alter table public.file_storage enable row level security;

-- ══════════════════════════════════════════════════════════
-- STEP 8: Users RLS policies
-- ══════════════════════════════════════════════════════════

create policy "users: read own or admin"
  on public.users for select
  using (auth.uid() = id or public.is_admin());

create policy "users: insert own"
  on public.users for insert
  with check (auth.uid() = id);

create policy "users: update own"
  on public.users for update
  using (auth.uid() = id);

-- ══════════════════════════════════════════════════════════
-- STEP 9: Songs RLS policies
-- ══════════════════════════════════════════════════════════

create policy "songs: public read"
  on public.songs for select
  using (true);

create policy "songs: admin insert"
  on public.songs for insert
  with check (public.is_admin());

create policy "songs: admin update"
  on public.songs for update
  using (public.is_admin());

create policy "songs: admin delete"
  on public.songs for delete
  using (public.is_admin());

-- ══════════════════════════════════════════════════════════
-- STEP 10: file_storage RLS policies
-- ══════════════════════════════════════════════════════════

-- Anyone can read files (public access for playback)
create policy "file_storage: public read"
  on public.file_storage for select
  using (true);

-- Only admins can upload files
create policy "file_storage: admin insert"
  on public.file_storage for insert
  with check (
    auth.role() = 'authenticated'
    and public.is_admin()
  );

-- Only admins can delete files
create policy "file_storage: admin delete"
  on public.file_storage for delete
  using (
    auth.role() = 'authenticated'
    and public.is_admin()
  );

-- ══════════════════════════════════════════════════════════
-- STEP 11: Create storage bucket (DISABLED, not used)
-- ══════════════════════════════════════════════════════════

-- We keep the bucket for compatibility but don't use it
insert into storage.buckets (id, name, public)
values ('songs', 'songs', true)
on conflict (id) do update set public = true;

-- Remove all storage policies (we're not using Supabase Storage)
delete from storage.policies where bucket_id = 'songs';

-- ══════════════════════════════════════════════════════════
-- STEP 12: Insert test admin user (optional)
-- ══════════════════════════════════════════════════════════

-- You can manually insert admin after they sign up, or do it here
-- Replace 'USER_UUID' with actual UUID from auth.users table

-- Example (run AFTER admin signs up):
-- insert into public.users (id, email, display_name, is_admin)
-- values (
--   'USER_UUID_FROM_AUTH_USERS',
--   'admin@faarfanna.com',
--   'Admin',
--   true
-- )
-- on conflict (id) do update set is_admin = true;

-- ══════════════════════════════════════════════════════════
-- STEP 13: Verify setup
-- ══════════════════════════════════════════════════════════

select 'Schema setup complete!' as status;

select 'Tables created:' as info;
select table_name 
from information_schema.tables 
where table_schema = 'public' 
  and table_name in ('users', 'songs', 'file_storage');

select 'Functions created:' as info;
select routine_name 
from information_schema.routines 
where routine_schema = 'public'
  and routine_name in ('is_admin', 'increment_play_count');

-- ══════════════════════════════════════════════════════════
-- DONE
-- ══════════════════════════════════════════════════════════
-- After running this:
-- 1. Go to Authentication → Settings → Email Auth
--    → Disable "Confirm email"
-- 2. Delete existing admin@faarfanna.com from Auth → Users
-- 3. Run the app and sign in with: foAdmin / admin@fo
-- 4. Go to SQL Editor and run:
--    update public.users set is_admin = true 
--    where email = 'admin@faarfanna.com';
-- 5. Try uploading a song!
-- ══════════════════════════════════════════════════════════
