class AppConstants {
  static const String appName = 'Faarfanna Obbolootaa';
  static const String appNameShort = 'FO';

  // ── Supabase ──────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://mwnrsfnnazyskpvylcfs.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im13bnJzZm5uYXp5c2twdnlsY2ZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNDU3NjksImV4cCI6MjA5NTYyMTc2OX0.GMquG6710zq5NKRyCtGurHR4bY6F3cJCFACOLEJikRk';

  // ── Supabase table names ──────────────────────────────────────────────
  static const String songsTable = 'songs';
  static const String usersTable = 'users';
  static const String favoritesTable = 'favorites';

  // ── Supabase Storage buckets ──────────────────────────────────────────
  static const String songsBucket = 'songs';
  static const String audioFolder = 'audio';
  static const String imagesFolder = 'images';

  // ── SharedPreferences Keys ────────────────────────────────────────────
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingKey = 'onboarding_done';
  static const String recentlyPlayedKey = 'recently_played';

  // ── Languages ─────────────────────────────────────────────────────────
  static const String langAfaanOromo = 'Afaan Oromo';
  static const String langEnglish = 'English';
  static const String langAmharic = 'Amharic';

  static const List<String> languages = [
    langAfaanOromo,
    langEnglish,
    langAmharic,
  ];

  // ── Admin credentials ─────────────────────────────────────────────────
  // The admin logs in with username "foAdmin" / password "admin@fo"
  // Internally mapped to the Supabase Auth account below
  static const String adminUsername = 'foAdmin';
  static const String adminPassword = 'admin@fo';
  static const String adminEmail = 'admin@faarfanna.com';

  // Any account whose email is in this list is treated as admin
  static const List<String> adminEmails = [
    'admin@faarfanna.com',
    'admin@fo.com',
  ];

  // ── Pagination ────────────────────────────────────────────────────────
  static const int songsPerPage = 20;
}
