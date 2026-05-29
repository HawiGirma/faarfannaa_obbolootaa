-- ============================================================
-- FULL RESET & SETUP — Run in Supabase SQL Editor
-- Dashboard → SQL Editor → New query → paste all → Run
-- ============================================================

-- ── 1. Clean slate ───────────────────────────────────────────────────────

drop table if exists public.songs cascade;
drop table if exists public.users cascade;
drop function if exists public.increment_play_count(uuid);

-- ── 2. users table ───────────────────────────────────────────────────────

create table public.users (
  id           uuid primary key,
  email        text not null,
  display_name text not null default 'User',
  photo_url    text,
  is_admin     boolean not null default false,
  favorite_ids text[] not null default '{}',
  created_at   timestamptz not null default now()
);

-- ── 3. songs table ───────────────────────────────────────────────────────

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
  uploaded_by      uuid,
  created_at       timestamptz not null default now()
);

-- ── 4. RPC: atomic play count increment ──────────────────────────────────

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

-- ── 5. Helper function: is current user an admin ─────────────────────────
-- Checks auth.email() directly — no join needed, avoids circular RLS issues

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
    -- fallback: check email directly so first-login upload works
    auth.email() in ('admin@faarfanna.com', 'admin@fo.com')
  );
$$;

-- ── 6. Enable RLS ────────────────────────────────────────────────────────

alter table public.songs enable row level security;
alter table public.users enable row level security;

-- ── 7. Songs RLS policies ────────────────────────────────────────────────

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

-- ── 8. Users RLS policies ────────────────────────────────────────────────

create policy "users: read own or admin"
  on public.users for select
  using (auth.uid() = id or public.is_admin());

create policy "users: insert own"
  on public.users for insert
  with check (auth.uid() = id);

create policy "users: update own"
  on public.users for update
  using (auth.uid() = id);

-- ── 9. Storage bucket ────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'songs',
  'songs',
  true,
  52428800,  -- 50 MB limit
  array['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/aac',
        'image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
  set public = true,
      file_size_limit = 52428800;

-- ── 10. Storage RLS policies ─────────────────────────────────────────────
-- Drop any existing storage policies for this bucket first

delete from storage.policies
where bucket_id = 'songs';

-- Anyone can read/download files (public bucket)
create policy "storage songs: public read"
  on storage.objects for select
  using (bucket_id = 'songs');

-- Only admins can upload — use email check to avoid schema dependency
create policy "storage songs: admin insert"
  on storage.objects for insert
  with check (
    bucket_id = 'songs'
    and auth.role() = 'authenticated'
    and auth.email() in ('admin@faarfanna.com', 'admin@fo.com')
  );

-- Only admins can update
create policy "storage songs: admin update"
  on storage.objects for update
  using (
    bucket_id = 'songs'
    and auth.role() = 'authenticated'
    and auth.email() in ('admin@faarfanna.com', 'admin@fo.com')
  );

-- Only admins can delete
create policy "storage songs: admin delete"
  on storage.objects for delete
  using (
    bucket_id = 'songs'
    and auth.role() = 'authenticated'
    and auth.email() in ('admin@faarfanna.com', 'admin@fo.com')
  );

-- ── Done ─────────────────────────────────────────────────────────────────
-- After running this script:
-- 1. Go to Authentication → Providers → Email → turn OFF "Confirm email"
-- 2. Delete any existing admin@faarfanna.com user in Authentication → Users
-- 3. Hot restart the app and log in with foAdmin / admin@fo
