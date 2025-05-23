import 'package:flutter/material.dart';

/// App Color Palette
/// Based on the provided color scheme for inventory management app
class AppColors {
  // Primary Colors from your theme
  static const Color darkNavy = Color(0xFF023047);      // #023047
  static const Color teal = Color(0xFF219EBC);          // #219EBC
  static const Color lightBlue = Color(0xFF8ECAE6);     // #8ECAE6
  static const Color goldenYellow = Color(0xFFFFB703);  // #FFB703
  static const Color orange = Color(0x0ffb8500);         // #FB8500

  // Primary color variations
  static const Color primary = teal;
  static const Color primaryDark = darkNavy;
  static const Color primaryLight = lightBlue;
  static const Color secondary = goldenYellow;
  static const Color secondaryDark = orange;

  // Background colors
  static const Color background = lightBlue;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = goldenYellow;
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = teal;
  static const Color infoLight = Color(0xFFECF7FF);

  // Stock status colors
  static const Color inStock = success;
  static const Color inStockBackground = successLight;
  static const Color lowStock = warning;
  static const Color lowStockBackground = warningLight;
  static const Color outOfStock = error;
  static const Color outOfStockBackground = errorLight;

  // Border and divider colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color shadow = Color(0x1A000000);

  // Interactive colors
  static const Color hover = Color(0xFFF9FAFB);
  static const Color pressed = Color(0xFFF3F4F6);
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color disabledText = Color(0xFF9CA3AF);

  // Gradient colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [teal, darkNavy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient secondaryGradient = LinearGradient(
    colors: [goldenYellow, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [lightBlue, Color(0xFFB8E6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Chart colors for analytics
  static const List<Color> chartColors = [
    teal,
    goldenYellow,
    orange,
    darkNavy,
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
  ];

  static var secondaryLight;

  static var accent;

  // Color utilities
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}