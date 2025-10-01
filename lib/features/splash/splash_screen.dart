import 'package:flutter/material.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';
import 'package:egg_toeic/core/constants/app_strings.dart';
import 'package:egg_toeic/core/theme/app_theme.dart';
import 'package:egg_toeic/core/services/app_open_ad_manager.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _animationController.forward();

    // Start loading ad and navigate after splash
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    bool hasCompleted = false;

    void completeAndNavigate() {
      if (!hasCompleted && mounted) {
        hasCompleted = true;
        print('✅ Splash complete - Switching to main app...');
        widget.onComplete();
      }
    }

    try {
      // Show splash for at least 2 seconds
      print('⏱️ Splash screen: Waiting 2 seconds...');
      await Future.delayed(const Duration(seconds: 2));

      // Load app open ad
      print('🎯 Loading app open ad from splash screen...');
      final adManager = AppOpenAdManager();
      await adManager.loadAd();
      print('📱 Ad load completed');

      // Check if widget is still mounted
      if (!mounted) {
        print('⚠️ Widget not mounted, aborting');
        return;
      }

      // Set a safety timeout to ensure we navigate even if ad fails
      Future.delayed(const Duration(seconds: 8), () {
        if (!hasCompleted) {
          print('⏰ Safety timeout reached, forcing completion');
          completeAndNavigate();
        }
      });

      // Show ad and navigate to home
      print('📺 Attempting to show ad...');
      await adManager.showAdIfAvailable(() {
        print('✅ Ad callback triggered');
        completeAndNavigate();
      });

      // If we reached here and callback wasn't called, complete anyway
      await Future.delayed(const Duration(milliseconds: 500));
      if (!hasCompleted) {
        print('⚠️ Ad callback not triggered, completing anyway');
        completeAndNavigate();
      }
    } catch (e) {
      print('❌ Error in splash screen: $e');
      completeAndNavigate();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1CB0F6), // Duolingo blue
              Color(0xFF58CC02), // Duolingo green
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(70),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 70,
                        color: Color(0xFF1CB0F6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // App Subtitle
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppStrings.appTitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Loading Indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // Version or tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    '🥚 Learn TOEIC the fun way!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}