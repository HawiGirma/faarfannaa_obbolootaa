class AppConstants {
  static const String appName = 'Faarfanna Obbolootaa';
  static const String appNameShort = 'FO';

  // Firestore Collections
  static const String songsCollection = 'songs';
  static const String usersCollection = 'users';
  static const String favoritesCollection = 'favorites';
  static const String playlistsCollection = 'playlists';

  // Storage Paths
  static const String audioStoragePath = 'songs/audio/';
  static const String imageStoragePath = 'songs/images/';

  // SharedPreferences Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingKey = 'onboarding_done';
  static const String recentlyPlayedKey = 'recently_played';

  // Languages
  static const String langAfaanOromo = 'Afaan Oromo';
  static const String langEnglish = 'English';
  static const String langAmharic = 'Amharic';

  static const List<String> languages = [
    langAfaanOromo,
    langEnglish,
    langAmharic,
  ];

  // Admin credentials (display name → real Firebase email)
  // The admin logs in with username "foAdmin" and password "admin@fo"
  // Internally mapped to the Firebase account below
  static const String adminUsername = 'foAdmin';
  static const String adminPassword = 'admin@fo';
  static const String adminFirebaseEmail = 'admin@faarfanna.com';

  // Admin emails — any account with these emails gets isAdmin = true
  static const List<String> adminEmails = [
    'admin@faarfanna.com',
    'admin@fo.com',
  ];

  // Pagination
  static const int songsPerPage = 20;
}
