import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:audio_service/audio_service.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/song_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/note_provider.dart';
import 'providers/bible_provider.dart';
import 'services/audio_player_service.dart';
import 'services/background_audio_service.dart';
import 'services/download_service.dart';
import 'services/bible_service.dart';
import 'localization/app_localizations.dart';
import 'screens/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Initialize Supabase ───────────────────────────────────────────────
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  // ── Init background audio service with timeout and error handling ─────
  BackgroundAudioHandler? audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => BackgroundAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.faarfannaa_obbolootaa.audio',
        androidNotificationChannelName: 'Faarfanna Obbolootaa',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('AudioService initialization timed out');
        throw TimeoutException('AudioService init timeout');
      },
    );
  } catch (e) {
    debugPrint('AudioService initialization error: $e');
    // Continue without audio handler - will be handled gracefully in the app
  }

  // ── Init local download cache ─────────────────────────────────────────
  final downloadService = DownloadService();
  try {
    await downloadService.init();
  } catch (e) {
    debugPrint('DownloadService initialization error: $e');
  }

  // ── Init Bible service ────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  final bibleService = BibleService(prefs);

  runApp(FaarfannaApp(
    downloadService: downloadService,
    audioHandler: audioHandler,
    bibleService: bibleService,
  ));
}

class FaarfannaApp extends StatelessWidget {
  final DownloadService downloadService;
  final BackgroundAudioHandler? audioHandler;
  final BibleService bibleService;

  const FaarfannaApp({
    super.key,
    required this.downloadService,
    this.audioHandler,
    required this.bibleService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => BibleProvider(bibleService)),
        ChangeNotifierProvider.value(value: downloadService),
        ChangeNotifierProvider(
          create: (_) => AudioPlayerService(downloadService),
        ),
        if (audioHandler != null) Provider.value(value: audioHandler),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('om')],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
