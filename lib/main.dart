import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/core/constants/app_strings.dart';
import 'package:egg_toeic/core/routing/app_router.dart';
import 'package:egg_toeic/providers/repository_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:egg_toeic/core/services/auth_service.dart';
import 'package:egg_toeic/core/utils/firebase_diagnostics.dart';
import 'package:egg_toeic/core/utils/network_test.dart';
import 'package:egg_toeic/features/splash/splash_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 App starting...');

  // Initialize Google Mobile Ads
  print('📱 Initializing Google Mobile Ads...');
  final initResult = await MobileAds.instance.initialize();

  // Enable test mode for all devices during development
  final RequestConfiguration requestConfiguration = RequestConfiguration(
    testDeviceIds: ['YOUR_DEVICE_ID'], // Will be overridden by test ad units
  );
  MobileAds.instance.updateRequestConfiguration(requestConfiguration);

  print('✅ Google Mobile Ads initialized');
  print('📱 Test mode enabled for development');

  // Initialize Firebase
  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('📱 Stack trace: ${StackTrace.current}');
  }

  // Initialize Hive
  print('📦 Initializing Hive...');
  await Hive.initFlutter();
  print('✅ Hive initialized');

  // Run network test first
  await NetworkTest.checkConnectivity();

  // Run diagnostics to check Firebase setup
  await FirebaseDiagnostics.runDiagnostics();

  // Initialize Authentication - MUST complete before repositories
  print('🔐 Initializing Authentication...');
  try {
    await AuthService().initialize();
    print('✅ Authentication initialized in main()');

    // Small delay to ensure auth state is fully propagated
    await Future.delayed(const Duration(milliseconds: 300));
    print('✅ Auth state ready in main()');
  } catch (e, stackTrace) {
    print('❌ Auth initialization failed in main(): $e');
    print('📱 Stack trace: $stackTrace');
    print('⚠️ Continuing with offline mode - data will sync when online');
    // App should still work offline
  }

  print('🎨 Launching app UI...');
  runApp(
    const ProviderScope(
      child: EggToeicApp(),
    ),
  );
}

class EggToeicApp extends ConsumerStatefulWidget {
  const EggToeicApp({super.key});

  @override
  ConsumerState<EggToeicApp> createState() => _EggToeicAppState();
}

class _EggToeicAppState extends ConsumerState<EggToeicApp> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initAsync = ref.watch(repositoryInitializerProvider);

    return initAsync.when(
      data: (_) {
        if (_showSplash) {
          return MaterialApp(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: SplashScreen(onComplete: _onSplashComplete),
          );
        } else {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          );
        }
      },
      loading: () => MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const LoadingScreen(),
      ),
      error: (error, stack) => MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: ErrorScreen(error: error),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1CB0F6),
              Color(0xFF58CC02),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Object? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app or retry initialization
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
