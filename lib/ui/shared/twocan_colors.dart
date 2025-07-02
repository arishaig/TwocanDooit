import 'package:flutter/material.dart';

/// Twocan brand colors from the official brand guide
/// High-contrast, cheerful without being neon assault. All colors pass accessibility thresholds.
class TwocanColors {
  // Primary brand colors
  static const Color toucanBlue = Color(0xFF2D7A9A);     // 🐦 Toucan Blue - Primary buttons, headers
  static const Color beakOrange = Color(0xFFFFAD49);     // 🍊 Beak Orange - Highlights, checkmarks, icons
  static const Color bellyCream = Color(0xFFFFF7ED);     // 🪶 Belly Cream - Backgrounds
  static const Color jungleGreen = Color(0xFF64A67B);    // 🌿 Jungle Green - Success states, accent buttons
  static const Color cozyPurple = Color(0xFFA393D3);     // 💜 Cozy Purple - Hover states, links, flair
  static const Color charcoalText = Color(0xFF2B2B2B);   // 🌑 Charcoal Text - Primary text
  
  // Alert colors
  static const Color alertBerry = Color(0xFFD46A6A);     // Muted berry - never flashing, never yelling
  
  // Gradient combinations for cozy UI elements
  static const LinearGradient toucanGradient = LinearGradient(
    colors: [toucanBlue, Color(0xFF3A8BAB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [beakOrange, Color(0xFFFFB85E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [jungleGreen, Color(0xFF70B088)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Helper methods for themed colors
  static Color getSuccessColor(BuildContext context) {
    return jungleGreen;
  }
  
  static Color getWarningColor(BuildContext context) {
    return beakOrange;
  }
  
  static Color getErrorColor(BuildContext context) {
    return alertBerry;
  }
  
  static Color getCozyBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1A1A1A) : bellyCream;
  }
  
  static Color getCozyText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? bellyCream : charcoalText;
  }
}