import 'package:flutter/material.dart';

class AppPalette {
  // Servekeen brand tokens.  Keep legacy names as aliases while screens are
  // migrated; this prevents a stray purple from reappearing in old widgets.
  static const Color primaryBlue = Color(0xFF1769E0);
  static const Color primaryGreen = Color(0xFF16A66A);
  static const Color darkNavy = Color(0xFF12345B);
  static const Color darkNeutral = Color(0xFF16202A);
  static const Color deepBlue = darkNavy;
  static const Color fusionPurple = primaryBlue;
  static const Color elegantPink = primaryGreen;
  // A mistier light canvas keeps large screens from feeling stark or glaring.
  static const Color softBlendBackground = Color(0xFFF3F7FC);
  static const Color lightPinkTint = Color(0xFFEAF9F2);
  static const Color lightBlueTint = Color(0xFFEDF5FF);
  static const Color successTint = Color(0xFFE7F8F0);
  static const Color divider = Color(0xFFDDE7F2);
}
