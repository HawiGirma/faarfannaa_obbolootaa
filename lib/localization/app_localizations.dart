import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'appName': 'Faarfanna Obbolootaa',
      'home': 'Home',
      'search': 'Search',
      'favorites': 'Favorites',
      'profile': 'Profile',
      'settings': 'Settings',
      'featured': 'Featured',
      'recentlyAdded': 'Recently Added',
      'trending': 'Trending',
      'allSongs': 'All Songs',
      'searchHint': 'Search songs, artists...',
      'noResults': 'No results found',
      'noFavorites': 'No favorites yet',
      'addFavorites': 'Tap the heart icon on any song to save it here',
      'nowPlaying': 'Now Playing',
      'lyrics': 'Lyrics',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'signOut': 'Sign Out',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'adminDashboard': 'Admin Dashboard',
      'uploadSong': 'Upload Song',
      'songTitle': 'Song Title',
      'artistName': 'Artist / Group Name',
      'language': 'Language',
      'lyricsText': 'Lyrics',
      'audioFile': 'Audio File',
      'coverImage': 'Cover Image',
      'publish': 'Publish Song',
      'edit': 'Edit',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'save': 'Save',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'appLanguage': 'App Language',
      'about': 'About',
      'version': 'Version',
      'share': 'Share',
      'download': 'Download Lyrics',
      'seeAll': 'See All',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'welcome': 'Welcome Back',
      'welcomeSubtitle': 'Sign in to continue your worship journey',
      'createAccount': 'Create Account',
      'createAccountSubtitle': 'Join the worship community',
      'featured_badge': 'Featured',
      'all': 'All',
      'afaanOromo': 'Afaan Oromo',
      'english': 'English',
      'amharic': 'Amharic',
      'recentlyPlayed': 'Recently Played',
      'queue': 'Queue',
      'shuffle': 'Shuffle',
      'repeat': 'Repeat',
      'noSongsFound': 'No songs found',
      'tapToPlay': 'Tap to play',
      'adminOnly': 'Admin Access Required',
      'notAdmin': 'You need admin privileges to access this section.',
      'uploadAudio': 'Upload Audio',
      'uploadImage': 'Upload Cover Image',
      'selectAudio': 'Select MP3 File',
      'selectImage': 'Select Image',
      'uploading': 'Uploading...',
      'uploadSuccess': 'Song uploaded successfully!',
      'uploadFailed': 'Upload failed. Please try again.',
      'deleteConfirm': 'Are you sure you want to delete this song?',
      'yes': 'Yes',
      'no': 'No',
      'featuredSong': 'Featured Song',
      'markFeatured': 'Mark as Featured',
      'removeFeatured': 'Remove from Featured',
      'playCount': 'plays',
      'onboardingTitle1': 'Worship Together',
      'onboardingSubtitle1':
          'Discover and listen to beautiful gospel songs in Afaan Oromo and English',
      'onboardingTitle2': 'Read Lyrics',
      'onboardingSubtitle2': 'Follow along with full lyrics while you worship',
      'onboardingTitle3': 'Save Favorites',
      'onboardingSubtitle3': 'Build your personal collection of worship songs',
      'getStarted': 'Get Started',
      'next': 'Next',
      'skip': 'Skip',
    },
    'om': {
      'appName': 'Faarfanna Obbolootaa',
      'home': 'Mana',
      'search': 'Barbaadi',
      'favorites': 'Jaalatamoo',
      'profile': 'Profaayilii',
      'settings': 'Qindaa\'ina',
      'featured': 'Filatamoo',
      'recentlyAdded': 'Dhiyoo Dabalame',
      'trending': 'Beekamoo',
      'allSongs': 'Faarfannaawwan Hunda',
      'searchHint': 'Faarfannaa, artisti barbaadi...',
      'noResults': 'Bu\'aa hin argamne',
      'noFavorites': 'Jaalatamoon hin jiru',
      'addFavorites': 'Faarfannaa kamirrattuu onnee tuqi',
      'nowPlaying': 'Amma Taphatamaa Jira',
      'lyrics': 'Jechawwan',
      'signIn': 'Seeni',
      'signUp': 'Galmaa\'i',
      'signOut': 'Ba\'i',
      'email': 'Imeelii',
      'password': 'Jecha Darbii',
      'confirmPassword': 'Jecha Darbii Mirkaneessi',
      'fullName': 'Maqaa Guutuu',
      'forgotPassword': 'Jecha Darbii Dagatte?',
      'resetPassword': 'Jecha Darbii Haaromsi',
      'dontHaveAccount': 'Herrega hin qabduu?',
      'alreadyHaveAccount': 'Herrega qabdaa?',
      'adminDashboard': 'Galmee Bulchiinsaa',
      'uploadSong': 'Faarfannaa Olkaa\'i',
      'songTitle': 'Mata-duree Faarfannaa',
      'artistName': 'Maqaa Artisti / Garee',
      'language': 'Afaan',
      'lyricsText': 'Jechawwan',
      'audioFile': 'Faayilii Sagalee',
      'coverImage': 'Suuraa Uwwisaa',
      'publish': 'Maxxansi',
      'edit': 'Gulaali',
      'delete': 'Haqi',
      'cancel': 'Dhiisi',
      'save': 'Kuusi',
      'darkMode': 'Haala Dukkana',
      'lightMode': 'Haala Ifa',
      'appLanguage': 'Afaan Appii',
      'about': 'Waa\'ee',
      'version': 'Versiinii',
      'share': 'Qoodi',
      'download': 'Jechawwan Buufadhu',
      'seeAll': 'Hunda Ilaali',
      'loading': 'Fe\'amaa jira...',
      'error': 'Rakkoo uumame',
      'retry': 'Irra deebi\'i yaali',
      'welcome': 'Baga Deebitee',
      'welcomeSubtitle': 'Itti fufi',
      'createAccount': 'Herrega Uumi',
      'createAccountSubtitle': 'Hawaasa faarfannaa keessatti makamu',
      'featured_badge': 'Filatamoo',
      'all': 'Hunda',
      'afaanOromo': 'Afaan Oromoo',
      'english': 'Afaan Inglizii',
      'amharic': 'Afaan Amaaraa',
      'recentlyPlayed': 'Dhiyoo Taphatame',
      'queue': 'Tarree',
      'shuffle': 'Walitti Makuu',
      'repeat': 'Irra Deebi\'i',
      'noSongsFound': 'Faarfannaan hin argamne',
      'tapToPlay': 'Tuqi taphachiisi',
      'adminOnly': 'Hayyama Bulchiinsaa Barbaachisa',
      'notAdmin': 'Kutaa kana seenuuf hayyama bulchiinsaa barbaachisa.',
      'uploadAudio': 'Sagalee Olkaa\'i',
      'uploadImage': 'Suuraa Uwwisaa Olkaa\'i',
      'selectAudio': 'Faayilii MP3 Filadhu',
      'selectImage': 'Suuraa Filadhu',
      'uploading': 'Olkaa\'amaa jira...',
      'uploadSuccess': 'Faarfannaan milkaa\'inaan olkaa\'ame!',
      'uploadFailed': 'Olkaa\'uun hin milkoofne. Irra deebi\'i yaali.',
      'deleteConfirm': 'Faarfannaa kana haqu barbaaddaa?',
      'yes': 'Eeyyee',
      'no': 'Lakki',
      'featuredSong': 'Faarfannaa Filatamoo',
      'markFeatured': 'Filatamoo Godhuu',
      'removeFeatured': 'Filatamoo Irraa Kaasuu',
      'playCount': 'taphatame',
      'onboardingTitle1': 'Waliin Faarfadhu',
      'onboardingSubtitle1':
          'Faarfannaawwan Afaan Oromoo fi Inglizii bareedaa argadhu',
      'onboardingTitle2': 'Jechawwan Dubbisi',
      'onboardingSubtitle2': 'Yeroo faarfattu jechawwan hordofi',
      'onboardingTitle3': 'Jaalatamoo Kuusi',
      'onboardingSubtitle3': 'Walitti qabinsa faarfannaa kee dhuunfaa ijaaruu',
      'getStarted': 'Jalqabi',
      'next': 'Itti Aanaa',
      'skip': 'Irra Darbii',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode == 'om' ? 'om' : 'en';
    return _localizedStrings[langCode]?[key] ?? key;
  }

  // Convenience getters
  String get appName => translate('appName');
  String get home => translate('home');
  String get search => translate('search');
  String get favorites => translate('favorites');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get featured => translate('featured');
  String get recentlyAdded => translate('recentlyAdded');
  String get trending => translate('trending');
  String get allSongs => translate('allSongs');
  String get searchHint => translate('searchHint');
  String get noResults => translate('noResults');
  String get noFavorites => translate('noFavorites');
  String get addFavorites => translate('addFavorites');
  String get nowPlaying => translate('nowPlaying');
  String get lyrics => translate('lyrics');
  String get signIn => translate('signIn');
  String get signUp => translate('signUp');
  String get signOut => translate('signOut');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get fullName => translate('fullName');
  String get forgotPassword => translate('forgotPassword');
  String get resetPassword => translate('resetPassword');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get adminDashboard => translate('adminDashboard');
  String get uploadSong => translate('uploadSong');
  String get songTitle => translate('songTitle');
  String get artistName => translate('artistName');
  String get language => translate('language');
  String get lyricsText => translate('lyricsText');
  String get audioFile => translate('audioFile');
  String get coverImage => translate('coverImage');
  String get publish => translate('publish');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get darkMode => translate('darkMode');
  String get lightMode => translate('lightMode');
  String get appLanguage => translate('appLanguage');
  String get about => translate('about');
  String get version => translate('version');
  String get share => translate('share');
  String get seeAll => translate('seeAll');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get welcome => translate('welcome');
  String get welcomeSubtitle => translate('welcomeSubtitle');
  String get createAccount => translate('createAccount');
  String get createAccountSubtitle => translate('createAccountSubtitle');
  String get all => translate('all');
  String get afaanOromo => translate('afaanOromo');
  String get english => translate('english');
  String get amharic => translate('amharic');
  String get recentlyPlayed => translate('recentlyPlayed');
  String get noSongsFound => translate('noSongsFound');
  String get adminOnly => translate('adminOnly');
  String get notAdmin => translate('notAdmin');
  String get uploadAudio => translate('uploadAudio');
  String get uploadImage => translate('uploadImage');
  String get selectAudio => translate('selectAudio');
  String get selectImage => translate('selectImage');
  String get uploading => translate('uploading');
  String get uploadSuccess => translate('uploadSuccess');
  String get uploadFailed => translate('uploadFailed');
  String get deleteConfirm => translate('deleteConfirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get getStarted => translate('getStarted');
  String get next => translate('next');
  String get skip => translate('skip');
  String get onboardingTitle1 => translate('onboardingTitle1');
  String get onboardingSubtitle1 => translate('onboardingSubtitle1');
  String get onboardingTitle2 => translate('onboardingTitle2');
  String get onboardingSubtitle2 => translate('onboardingSubtitle2');
  String get onboardingTitle3 => translate('onboardingTitle3');
  String get onboardingSubtitle3 => translate('onboardingSubtitle3');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'om'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
