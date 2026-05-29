# Supabase Setup Guide — Faarfanna Obbolootaa

## 1. Create a Supabase Project

1. Go to https://supabase.com and sign in
2. Click **New Project**
3. Choose your organisation, set a name and a strong database password
4. Select the region closest to your users
5. Click **Create new project** and wait ~2 minutes

---

## 2. Get Your Credentials

In the Supabase dashboard → **Project Settings → API**:

- Copy **Project URL** → paste into `AppConstants.supabaseUrl`
- Copy **anon / public key** → paste into `AppConstants.supabaseAnonKey`

File: `lib/core/constants/app_constants.dart`

```dart
static const String supabaseUrl = 'https://xxxxxxxxxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## 3. Create the Database Tables

Go to **SQL Editor** in the Supabase dashboard and run:

```sql
-- ── users table ──────────────────────────────────────────────────────────
create table if not exists public.users (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null,
  display_name text not null default 'User',
  photo_url    text,
  is_admin     boolean not null default false,
  favorite_ids text[] not null default '{}',
  created_at   timestamptz not null default now()
);

-- ── songs table ───────────────────────────────────────────────────────────
create table if not exists public.songs (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  artist           text not null,
  language         text not null default 'Afaan Oromo',
  lyrics           text not null default '',
  audio_url        text not null,
  cover_url        text not null default '',
  featured         boolean not null default false,
  play_count       integer not null default 0,
  album_name       text,
  duration_seconds integer,
  uploaded_by      uuid references auth.users(id),
  created_at       timestamptz not null default now()
);

-- ── RPC: atomic play count increment ─────────────────────────────────────
create or replace function increment_play_count(song_id uuid)
returns void
language sql
security definer
as $$
  update public.songs
  set play_count = play_count + 1
  where id = song_id;
$$;
```

---

## 4. Row Level Security (RLS) Policies

```sql
-- Enable RLS on both tables
alter table public.users enable row level security;
alter table public.songs enable row level security;

-- ── users policies ────────────────────────────────────────────────────────

-- Users can read their own row
create policy "users: read own"
  on public.users for select
  using (auth.uid() = id);

-- Users can update their own row (e.g. favorites)
create policy "users: update own"
  on public.users for update
  using (auth.uid() = id);

-- Allow insert during sign-up (service role / trigger handles this)
create policy "users: insert own"
  on public.users for insert
  with check (auth.uid() = id);

-- Admins can read all users
create policy "users: admin read all"
  on public.users for select
  using (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.is_admin = true
    )
  );

-- ── songs policies ────────────────────────────────────────────────────────

-- Anyone (including anonymous) can read songs
create policy "songs: public read"
  on public.songs for select
  using (true);

-- Only admins can insert songs
create policy "songs: admin insert"
  on public.songs for insert
  with check (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.is_admin = true
    )
  );

-- Only admins can update songs
create policy "songs: admin update"
  on public.songs for update
  using (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.is_admin = true
    )
  );

-- Only admins can delete songs
create policy "songs: admin delete"
  on public.songs for delete
  using (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.is_admin = true
    )
  );
```

---

## 5. Storage Bucket Setup

In the Supabase dashboard → **Storage → New bucket**:

- Name: `songs`
- Public: **Yes** (so audio/image URLs work without auth tokens)
- Click **Create bucket**

Then run these storage policies in the SQL Editor:

```sql
-- Anyone can read files in the songs bucket
create policy "songs bucket: public read"
  on storage.objects for select
  using (bucket_id = 'songs');

-- Only admins can upload files
create policy "songs bucket: admin insert"
  on storage.objects for insert
  with check (
    bucket_id = 'songs' and
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.is_admin = true
    )
  );

-- Only admins can update files
create policy "songs bucket: admin update"
  on storage.objects for update
  using (
    bucket_id = 'songs' and
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.is_admin = true
    )
  );

-- Only admins can delete files
create policy "songs bucket: admin delete"
  on storage.objects for delete
  using (
    bucket_id = 'songs' and
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.is_admin = true
    )
  );
```

---

## 6. Authentication Configuration

In the Supabase dashboard → **Authentication → Providers**:

1. Make sure **Email** provider is **enabled**
2. Under **Email → Confirm email**: set to **OFF** for development
   (or ON for production — users will need to verify their email)

The admin account (`admin@faarfanna.com`) is created automatically on first
login via the app. No manual setup needed.

---

## 7. Create the Admin User (first run)

Simply open the app and tap the admin login button. Enter:
- Username: `foAdmin`
- Password: `admin@fo`

The app will automatically create the Supabase Auth account and the `users`
table row with `is_admin = true` on first run.

---

## 8. Realtime (optional but recommended)

To enable live song list updates:

In the Supabase dashboard → **Database → Replication**:
- Enable replication for the `songs` table

---

## 9. Android — Minimum SDK

Supabase requires minSdk 21. In `android/app/build.gradle.kts`:

```kotlin
minSdk = 21  // or flutter.minSdkVersion if it's already ≥ 21
```

---

## 10. Quick Checklist

- [ ] `supabaseUrl` set in `app_constants.dart`
- [ ] `supabaseAnonKey` set in `app_constants.dart`
- [ ] `users` table created
- [ ] `songs` table created
- [ ] `increment_play_count` RPC created
- [ ] RLS policies applied to both tables
- [ ] `songs` storage bucket created (public)
- [ ] Storage policies applied
- [ ] Email auth enabled, email confirmation off (dev)
- [ ] `google-services.json` removed from `android/app/`
