import 'package:flutter/material.dart';


import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_theme.dart';

abstract class AppTheme {
  static const _secondaryColor = Color(0xFFAAAAAA);

  static final lightTheme = ThemeData.light().copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    primaryColor: AppColors.primaryColor,
    secondaryHeaderColor: _secondaryColor,
    scaffoldBackgroundColor: Colors.white,
    textTheme: AppTextTheme.textThemeLight.apply(
      fontFamily: 'Poppins',
    ),
    primaryTextTheme: AppTextTheme.textThemeLight.apply(
      fontFamily: 'Poppins',
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: _secondaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _secondaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 1.5, color: _secondaryColor),
      ),
      contentPadding: AppDimens.inputsContentPadding,
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: MaterialStateProperty.all(Colors.white),
      fillColor: MaterialStateProperty.all(AppColors.primaryColor),
    ),
    radioTheme: RadioThemeData(
      overlayColor: MaterialStateProperty.all(AppColors.primaryColor),
      fillColor: MaterialStateProperty.all(AppColors.primaryColor),
    ),
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: AppColors.primaryColor,
      secondary: _secondaryColor,
    ),
  );
}
