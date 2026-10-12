import 'package:flutter/material.dart';

/// Warm ink and coral palette shared by the light and dark themes.
abstract final class AppColors {
  static const coral = Color(0xFFE8553F);
  static const coralLight = Color(0xFFFF7A59);
  /// Alias used as dark-theme primary (same as [coralLight]).
  static const coralBright = coralLight;
  static const online = Color(0xFF22C55E);
  static const ink = Color(0xFF1C1412);
  static const onDark = Color(0xFFF6EDE8);
  static const coralInk = Color(0xFF3F0E0A);

  static const canvas = Color(0xFFFFF8F6);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF1E4DF);
  static const bubbleThem = Color(0xFFF4ECE9);

  static const canvasDark = Color(0xFF14110F);
  static const cardDark = Color(0xFF1E1A18);
  static const lineDark = Color(0xFF2A2422);
  static const bubbleThemDark = Color(0xFF2A2422);

  static const brandGradient = LinearGradient(
    colors: [coral, coralLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color cardOf(Brightness brightness) =>
      brightness == Brightness.dark ? cardDark : card;

  static Color lineOf(Brightness brightness) =>
      brightness == Brightness.dark ? lineDark : line;

  static Color bubbleThemOf(Brightness brightness) =>
      brightness == Brightness.dark ? bubbleThemDark : bubbleThem;
}
