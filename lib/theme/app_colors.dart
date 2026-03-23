import 'package:flutter/material.dart';

class AppColors {
  // Core UI Theme
  static const Color primaryPink = Color(0xFFE91E63); // Vibrant Pink (Base)
  static const Color darkPink = Color(0xFFC2185B); // Darker shade for text/contrast
  static const Color lightPink = Color(0xFFF8BBD0); // Soft pastel pink for highlights
  static const Color surfacePink = Color(0xFFFDF2F8); // Very light pink for backgrounds
  
  // Base Colors
  static const Color backgroundWhite = Color(0xFFFDF2F8); // Replaced with surfacePink logic
  static const Color surfaceWhite = Colors.white;
  static const Color textPrimary = Color(0xFF4A148C); // Deep purple-pink for strong contrast
  static const Color textSecondary = Color(0xFF880E4F); // Muted dark pink for secondary text
  static const Color borderLight = Color(0xFFFCE4EC); // Soft pink border
  
  // Status Colors (Adapted to harmonize with pink)
  static const Color statusActive = Color(0xFF4CAF50); // Keep green for success/active
  static const Color statusOverdue = Color(0xFFD32F2F); // Red for overdue
  static const Color statusPending = Color(0xFFFFA000); // Amber for pending
  
  // Chart Gradients & Colors
  static const Color chartPurple = Color(0xFF9C27B0);
  static const Color chartGold = Color(0xFFFFB300);
  static const Color chartPeach = Color(0xFFFF7043);
}
