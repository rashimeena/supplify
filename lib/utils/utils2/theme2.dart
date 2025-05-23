import 'package:flutter/material.dart';
import 'colors2.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.blue,
    scaffoldBackgroundColor: AppColors.lightBlue,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.amber,
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.blue,
      secondary: AppColors.amber,
      background: AppColors.lightBlue,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: AppColors.darkBlue,
      onSurface: AppColors.darkBlue,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: AppColors.darkBlue,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: AppColors.darkBlue,
      ),
    ),
  );

}
