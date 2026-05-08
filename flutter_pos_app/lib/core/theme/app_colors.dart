import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primary = Color(0xFFFF9800);    
  static const Color accent = Color(0xFF101E2A);     
  static const Color secondary = Color(0xFF162B3A);  
  
  // Legacy / Missing Colors (Restored for compatibility)
  static const Color primaryLight = Color(0xFFFFE0B2);
  static const Color primaryDark = Color(0xFFF57C00);
  static const Color border = Color(0xFFE5E7EB);
  static const Color backgroundSecondary = Color(0xFFF3F4F6);
  static const Color backgroundTertiary = Color(0xFFE5E7EB);
  static const Color amazonYellow = Color(0xFFFFD814);
  static const Color amazonOrange = Color(0xFFFF9900);
  
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Semantic Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF2196F3);

  // Background & Surfaces
  static const Color background = Color(0xFFF7F8FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF101010);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static Color shadowLight = Colors.black.withOpacity(0.04);
  static Color shadowMedium = Colors.black.withOpacity(0.08);
}
