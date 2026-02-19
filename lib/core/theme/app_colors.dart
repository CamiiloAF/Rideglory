import 'package:flutter/material.dart';

/// Centralized color palette for the Rideglory app
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  
  // Secondary colors
  static const Color secondary = Color(0xFF8B5CF6); // Purple
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);
  
  // Gradient colors
  static List<Color> get primaryGradient => [primary, secondary];
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937); // Gray 800
  static const Color textSecondary = Color(0xFF6B7280); // Gray 500
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray 400
  static const Color textDisabled = Color(0xFFD1D5DB); // Gray 300
  
  // Background colors
  static const Color backgroundGray = Color(0xFFF9FAFB); // Gray 50
  static const Color backgroundGrayLight = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceGray = Color(0xFFF3F4F6); // Gray 100
  
  // Border colors
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color borderLight = Color(0xFFF3F4F6); // Gray 100
  static const Color borderDark = Color(0xFFD1D5DB); // Gray 300
  
  // Status colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  
  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  
  // Icon colors
  static const Color iconPrimary = primary;
  static const Color iconSecondary = textSecondary;
  static const Color iconDisabled = textDisabled;
  
  // Shadow colors
  static Color get shadowLight => Colors.black.withValues(alpha: .05);
  static Color get shadowMedium => Colors.black.withValues(alpha: .1);
  static Color get shadowDark => Colors.black.withValues(alpha: .15);
  static Color primaryShadow({double opacity = 0.3}) => primary.withValues(alpha: opacity);
  
  // Overlay colors
  static Color get overlayLight => Colors.white.withValues(alpha: 0.1);
  static Color get overlayMedium => Colors.white.withValues(alpha: 0.25);
  static Color get overlayStrong => Colors.white.withValues(alpha: 0.9);
  
  // Vehicle type colors
  static const Color motorcycle = Color(0xFF6366F1);
  static const Color car = Color(0xFF3B82F6);
  
  // Maintenance status colors
  static const Color maintenanceUrgent = error;
  static const Color maintenanceWarning = warning;
  static const Color maintenanceOk = success;
}
