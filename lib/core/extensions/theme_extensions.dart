import 'package:flutter/material.dart';

/// Extension to easily access theme and color scheme from BuildContext
extension ThemeExtension on BuildContext {
  /// Access the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Access the current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Access the current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Quick access to commonly used colors
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get surfaceColor => colorScheme.surface;
  Color get errorColor => colorScheme.error;
  
  /// Quick access to text colors
  Color get textPrimary => textTheme.bodyLarge?.color ?? Colors.black;
  Color get textSecondary => textTheme.bodyMedium?.color ?? Colors.grey;
  
  /// Quick access to display text styles
  TextStyle? get displayLarge => textTheme.displayLarge;
  TextStyle? get displayMedium => textTheme.displayMedium;
  TextStyle? get displaySmall => textTheme.displaySmall;
  
  /// Quick access to headline text styles
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;
  
  /// Quick access to title text styles
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;
  
  /// Quick access to body text styles
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;
  
  /// Quick access to label text styles
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;
}
