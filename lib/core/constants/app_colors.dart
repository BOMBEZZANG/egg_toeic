import 'package:flutter/material.dart';

class AppColors {
  // 🎯 Modern Primary Colors - Cool & Professional
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8); // Light Indigo
  static const Color primaryDark = Color(0xFF4F46E5); // Dark Indigo

  // 🚀 Secondary Colors - Clean & Modern
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color accentColor = Color(0xFF06B6D4); // Cyan
  static const Color tertiaryColor = Color(0xFF8B5CF6); // Violet

  // ✅ Status Colors - Clear & Intuitive
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // 🌊 Background Colors - Clean & Minimal
  static const Color backgroundGradientStart = Color(0xFFFAFAFA); // Neutral 50
  static const Color backgroundGradientEnd = Color(0xFFF4F4F5); // Neutral 100
  static const Color scaffoldBackground = Color(0xFFFFFFFF); // Pure White

  // 🎨 Surface Colors - Subtle & Elegant
  static const Color cardPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color cardSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color cardTertiary = Color(0xFFE2E8F0); // Slate 200
  static const Color cardAccent = Color(0xFFECFDF5); // Emerald 50
  static const Color cardWarning = Color(0xFFFEF3C7); // Amber 100

  // 📖 Text Colors - High Contrast & Readable
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Colors.white;
  static const Color textAccent = Color(0xFF6366F1); // Indigo

  // 🎨 UI Elements - Clean & Functional
  static const Color cardBackground = Colors.white;
  static const Color cardShadow = Color(0x08000000); // Subtle shadow
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200

  // 🏅 Level Colors - Clear Progression
  static const Color beginnerLevel = Color(0xFF10B981); // Emerald
  static const Color intermediateLevel = Color(0xFF3B82F6); // Blue
  static const Color advancedLevel = Color(0xFF8B5CF6); // Violet

  // 🏆 Achievement Colors - Premium Feel
  static const Color goldAchievement = Color(0xFFFBBF24); // Amber 400
  static const Color silverAchievement = Color(0xFF94A3B8); // Slate 400
  static const Color bronzeAchievement = Color(0xFFEA580C); // Orange 600

  // 💡 Additional Modern Colors
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundDark = Color(0xFF1E293B); // Slate 800
  static const Color disabledColor = Color(0xFFE2E8F0); // Slate 200
  static const Color hintColor = Color(0xFF94A3B8); // Slate 400

  // ✨ Special Effect Colors
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);

  // 🌊 Modern Gradient Collections
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neutralGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🏔️ Background Gradient - Clean & Minimal
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundGradientStart, backgroundGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}