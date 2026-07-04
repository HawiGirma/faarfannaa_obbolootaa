# 🔧 Notes Feature Troubleshooting Guide

## Issue: Notes failing to fetch and save

### ✅ Step 1: Verify Database Migration

Run this in Supabase SQL Editor to check if the notes table exists:

```sql
-- Check if notes table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'notes';

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'notes';

-- Check existing policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'notes';

-- Test query (should return empty result, not error)
SELECT * FROM notes LIMIT 1;
```

**Expected Results:**
- Table exists: ✅ `notes`
- RLS enabled: ✅ `t` (true)
- Policies: ✅ 5 policies (read own, insert own, update own, delete own, admin read all)
- Test query: ✅ Returns empty or has data (no error)

### ✅ Step 2: Check Authentication

The notes feature requires a logged-in user. Verify:

```dart
// In your app, check if user is logged in
final user = Supabase.instance.client.auth.currentUser;
print('User ID: ${user?.id}');
print('User Email: ${user?.email}');
```

**If no user:**
1. Go to Profile tab
2. Sign in as admin or guest
3. Return to Notes tab

### ✅ Step 3: Run Migration (if not done)

If the table doesn't exist, run this in Supabase SQL Editor:

```sql
-- Run the complete migration
-- Copy and paste the entire contents of notes_table_migration.sql
```

### ✅ Step 4: Test Manual Insert

Test if you can manually insert a note:

```sql
-- Get your user ID first
SELECT id, email FROM auth.users LIMIT 1;

-- Then insert a test note (replace USER_ID with actual ID)
INSERT INTO public.notes (user_id, title, content, color)
VALUES ('USER_ID_HERE', 'Test Note', 'This is a test', '#FFFFFF');

-- Check if it worked
SELECT * FROM public.notes;
```

### ✅ Step 5: Check App Logs

Run your Flutter app with console open and look for these messages:

```
NoteService: Fetching notes for user: [USER_ID]
NoteService: Received X notes
NoteService: Creating note for user: [USER_ID]
NoteService: Note created successfully: [NOTE_ID]
```

**If you see errors:**
- `User not authenticated` → Sign in first
- `relation "notes" does not exist` → Run migration
- `permission denied` → Check RLS policies
- Other errors → Check Supabase logs

### ✅ Step 6: Verify RLS Policies

Run this to recreate policies if needed:

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "notes: read own" ON public.notes;
DROP POLICY IF EXISTS "notes: insert own" ON public.notes;
DROP POLICY IF EXISTS "notes: update own" ON public.notes;
DROP POLICY IF EXISTS "notes: delete own" ON public.notes;
DROP POLICY IF EXISTS "notes: admin read all" ON public.notes;

-- Recreate policies
CREATE POLICY "notes: read own"
  ON public.notes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "notes: insert own"
  ON public.notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notes: update own"
  ON public.notes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "notes: delete own"
  ON public.notes FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "notes: admin read all"
  ON public.notes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND is_admin = true
    )
  );
```

### ✅ Step 7: Test in Supabase Dashboard

1. Go to Supabase Dashboard
2. Click "Table Editor"
3. Find "notes" table
4. Click "Insert row"
5. Fill in:
   - user_id: (your user ID)
   - title: "Test from Dashboard"
   - content: "Testing"
   - color: "#FFFFFF"
6. Click "Save"

If this works, the table is fine. If not, there's a database issue.

### ✅ Step 8: Check Network Connection

```dart
// Test Supabase connection
try {
  final response = await Supabase.instance.client
      .from('notes')
      .select()
      .limit(1);
  print('Connection OK: $response');
} catch (e) {
  print('Connection Error: $e');
}
```

## Common Error Messages

### "User not authenticated"
**Solution:** Sign in to the app first
```
1. Tap Profile tab
2. Sign in as admin or guest
3. Return to Notes tab
```

### "relation 'notes' does not exist"
**Solution:** Run the database migration
```
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Run notes_table_migration.sql
```

### "permission denied for table notes"
**Solution:** Check RLS policies
```
1. Verify RLS is enabled
2. Recreate policies (see Step 6)
3. Ensure you're logged in
```

### "Failed to fetch notes: [error]"
**Solution:** Check detailed error
```dart
// Add this to note_provider.dart in loadNotes()
print('Detailed error: ${e.toString()}');
```

## Quick Fixes

### Reset Everything
```sql
-- Drop and recreate table
DROP TABLE IF EXISTS public.notes CASCADE;

-- Then run the complete migration again
-- Copy notes_table_migration.sql contents here
```

### Force Reload Notes
```dart
// In your app
context.read<NoteProvider>().loadNotes();
```

### Clear Cache and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## Debug Mode

Add this to your note_service.dart temporarily:

```dart
// At the top of fetchNotes()
print('=== DEBUG fetchNotes ===');
print('User ID: $_userId');
print('Is Authenticated: $_isAuthenticated');
print('Table: $_tableName');

// After query
print('Response type: ${response.runtimeType}');
print('Response: $response');
```

## Still Not Working?

1. **Check Supabase Project URL**
   - Verify in `app_constants.dart`
   - Should match your Supabase dashboard URL

2. **Check Supabase Anon Key**
   - Verify in `app_constants.dart`
   - Get from Supabase Settings → API

3. **Check Supabase Logs**
   - Dashboard → Logs → Postgres Logs
   - Look for errors when app tries to access notes

4. **Try a Fresh Migration**
   ```sql
   -- Backup if you have data
   CREATE TABLE notes_backup AS SELECT * FROM notes;
   
   -- Drop table
   DROP TABLE IF EXISTS public.notes CASCADE;
   
   -- Run migration again
   -- (paste notes_table_migration.sql)
   ```

5. **Contact Support**
   - Share error messages
   - Share Supabase logs
   - Share Flutter console output

---

## Quick Test Script

Run this in your Flutter app to test everything:

```dart
Future<void> testNotesFeature() async {
  final supabase = Supabase.instance.client;
  
  // 1. Check auth
  final user = supabase.auth.currentUser;
  print('1. User: ${user?.id ?? "NOT LOGGED IN"}');
  
  if (user == null) {
    print('ERROR: Please log in first');
    return;
  }
  
  // 2. Test fetch
  try {
    final notes = await supabase
        .from('notes')
        .select()
        .eq('user_id', user.id);
    print('2. Fetch OK: ${notes.length} notes');
  } catch (e) {
    print('2. Fetch ERROR: $e');
    return;
  }
  
  // 3. Test insert
  try {
    final newNote = await supabase
        .from('notes')
        .insert({
          'user_id': user.id,
          'title': 'Test ${DateTime.now()}',
          'content': 'Testing',
          'color': '#FFFFFF',
        })
        .select()
        .single();
    print('3. Insert OK: ${newNote['id']}');
    
    // 4. Test delete
    await supabase
        .from('notes')
        .delete()
        .eq('id', newNote['id']);
    print('4. Delete OK');
    
    print('\n✅ All tests passed!');
  } catch (e) {
    print('3/4. Insert/Delete ERROR: $e');
  }
}

// Call this from a button or initState
testNotesFeature();
```

---

**If you've followed all steps and it still doesn't work, the issue is likely:**
1. Database migration not run ← Most common
2. Not logged in ← Second most common
3. Wrong Supabase credentials ← Third most common
4. RLS policy issue ← Less common
5. Network/connection issue ← Rare

**Next step:** Share the exact error message you're seeing!
