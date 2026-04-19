import 'package:flutter/material.dart';

class AppColors {
  // 💖 Core Pink Palette (Premium HSL-Tailored)
  static const Color primaryPink = Color(0xFFE91E63); 
  static const Color darkPink = Color(0xFF880E4F); 
  static const Color gradientStart = Color(0xFFEC407A); // Vibrant Pink
  static const Color gradientEnd = Color(0xFFAD1457);   // Deep Rose
  
  // 🌬️ Surface & Glassmorphism
  static const Color surfacePink = Color(0xFFFFF1F5); // Ultra Light Pink
  static const Color lightPink = Color(0xFFF8BBD0); // 🏛️ Pulihkan buat kodingan lama
  static const Color borderLight = Color(0xFFFCE4EC); // 🏛️ Pulihkan buat kodingan lama
  static const Color backgroundWhite = Color(0xFFFAFAFB); // Crisp Modern White
  static const Color surfaceWhite = Colors.white;
  static const Color glassWhite = Color(0xCCFFFFFF); // Semi-Transparent for glass effect
  
  // 🏛️ Typography
  static const Color textPrimary = Color(0xFF2D0C21); // Almost Black-Pink for elegance
  static const Color textSecondary = Color(0xFF6A1B4D); // Deep Muted Pink
  static const Color textMuted = Color(0xFFAD8B9D);    // Soft Gray-Pink
  
  // 🛡️ Status (Harmonized)
  static const Color statusActive = Color(0xFF2ECC71); 
  static const Color statusOverdue = Color(0xFFFF4757); 
  static const Color statusPending = Color(0xFFFFA502); 
  
  // 🐚 Shadow Constants (Soft & Modern)
  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: primaryPink.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
