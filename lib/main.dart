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
import 'services/audio_player_service.dart';
import 'services/background_audio_service.dart';
import 'services/download_service.dart';
import 'localization/app_localizations.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Initialize Supabase ───────────────────────────────────────────────
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // ── Init background audio service ─────────────────────────────────────
  final audioHandler = await AudioService.init(
    builder: () => BackgroundAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.faarfannaa_obbolootaa.audio',
      androidNotificationChannelName: 'Faarfanna Obbolootaa',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // ── Init local download cache ─────────────────────────────────────────
  final downloadService = DownloadService();
  await downloadService.init();

  runApp(FaarfannaApp(
    downloadService: downloadService,
    audioHandler: audioHandler,
  ));
}

class FaarfannaApp extends StatelessWidget {
  final DownloadService downloadService;
  final BackgroundAudioHandler audioHandler;

  const FaarfannaApp({
    super.key,
    required this.downloadService,
    required this.audioHandler,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SongProvider()),
        ChangeNotifierProvider.value(value: downloadService),
        ChangeNotifierProvider(
          create: (_) => AudioPlayerService(downloadService),
        ),
        Provider.value(value: audioHandler),
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
