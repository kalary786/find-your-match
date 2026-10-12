import 'package:flutter/material.dart';

/// Warm coral palette for light and dark themes.
abstract final class AppColors {
  static const coral = Color(0xFFE8553F);
  static const coralLight = Color(0xFFFF7A59);
  static const peach = Color(0xFFFFB36B);
  /// Alias used as dark-theme primary (same as [coralLight]).
  static const coralBright = coralLight;
  static const online = Color(0xFF22C55E);
  static const like = Color(0xFFE8553F);
  static const pass = Color(0xFF94A3B8);
  static const superlike = Color(0xFF3B82F6);

  static const ink = Color(0xFF1C1412);
  static const onDark = Color(0xFFF6EDE8);
  static const coralInk = Color(0xFF3F0E0A);

  static const canvas = Color(0xFFFFF8F6);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF1E4DF);
  static const muted = Color(0xFF7A6B66);
  static const bubbleThem = Color(0xFFF4ECE9);

  static const canvasDark = Color(0xFF14110F);
  static const cardDark = Color(0xFF1E1A18);
  static const lineDark = Color(0xFF2A2422);
  static const mutedDark = Color(0xFFA3948E);
  static const bubbleThemDark = Color(0xFF2A2422);

  static const brandGradient = LinearGradient(
    colors: [coral, coralLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const storyGradient = LinearGradient(
    colors: [coral, peach],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color cardOf(Brightness brightness) =>
      brightness == Brightness.dark ? cardDark : card;

  static Color lineOf(Brightness brightness) =>
      brightness == Brightness.dark ? lineDark : line;

  static Color mutedOf(Brightness brightness) =>
      brightness == Brightness.dark ? mutedDark : muted;

  static Color bubbleThemOf(Brightness brightness) =>
      brightness == Brightness.dark ? bubbleThemDark : bubbleThem;
}
