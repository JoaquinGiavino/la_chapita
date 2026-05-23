import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color vanilla = Color(0xFFFFF2B3);
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF777777);

  static const Color vanillaLight = Color(0xFFFFFAE0);
  static const Color vanillaDark = Color(0xFFE8D88A);
  static const Color blackSurface = Color(0xFF1A1A1A);
  static const Color blackElevated = Color(0xFF222222);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);

  static Color get glassSurface => white.withOpacity(0.08);
  static Color get glassBorder => white.withOpacity(0.15);
  static Color get vanillaHover => vanilla.withOpacity(0.10);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}