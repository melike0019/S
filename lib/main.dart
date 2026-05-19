import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/clothing_provider.dart';
import 'providers/outfit_provider.dart';
import 'providers/history_provider.dart';
import 'providers/planner_provider.dart';
import 'providers/user_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/splash_screen.dart';
import 'services/ai_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Native splash'ı Firebase init bitene kadar tut
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Offline persistence — internet olmadığında cache'den veri serve et
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  // Bildirim servisi arka planda başlatılır, başlangıcı bloklamaz
  unawaited(NotificationService().init());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<ClothingProvider>(
          create: (_) => ClothingProvider(),
        ),
        ChangeNotifierProvider<OutfitProvider>(create: (_) => OutfitProvider()),
        ChangeNotifierProvider<WeatherProvider>(
          create: (_) => WeatherProvider(),
        ),
        ChangeNotifierProvider<PlannerProvider>(
          create: (_) => PlannerProvider(),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (_) => HistoryProvider(),
        ),
        Provider<AIService>(create: (_) => AIService()),
      ],
      child: const StilyaApp(),
    ),
  );
  // NOT: FlutterNativeSplash.remove() SplashScreen.initState() içinde çağrılır
  // böylece Flutter ilk frame'i çizdikten sonra native splash kalkar, siyah ekran olmaz
}

class StilyaApp extends StatelessWidget {
  const StilyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stilya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.88,
              maxScaleFactor: 1.16,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
