import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  // ── Cormorant Garamond (títulos, marca) ───────────
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
        fontSize: 40, fontWeight: FontWeight.w700,
        color: AppColors.vanilla, letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.cormorantGaramond(
        fontSize: 32, fontWeight: FontWeight.w600,
        color: AppColors.vanilla, letterSpacing: -0.3,
      );

  static TextStyle get headlineLarge => GoogleFonts.cormorantGaramond(
        fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.black,
      );

  static TextStyle get headlineMedium => GoogleFonts.cormorantGaramond(
        fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.black,
      );

  static TextStyle get headlineSmall => GoogleFonts.cormorantGaramond(
        fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.black,
      );

  static TextStyle get headlineMediumOnDark =>
      headlineMedium.copyWith(color: AppColors.vanilla);

  static TextStyle get headlineLargeOnDark =>
      headlineLarge.copyWith(color: AppColors.vanilla);

  // ── Inter (datos, cuerpo) ─────────────────────────
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.black,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.black,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.black, height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.black, height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.grey, height: 1.4,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black, letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.grey, letterSpacing: 0.5,
      );

  // ── Variantes sobre oscuro ────────────────────────
  static TextStyle get bodyMediumOnDark =>
      bodyMedium.copyWith(color: AppColors.white.withOpacity(0.85));

  static TextStyle get bodySmallOnDark =>
      bodySmall.copyWith(color: AppColors.white.withOpacity(0.60));

  static TextStyle get titleMediumOnDark =>
      titleMedium.copyWith(color: AppColors.white);

  static TextStyle get titleSmallOnDark =>
      titleSmall.copyWith(color: AppColors.white);

  // ── Montos ────────────────────────────────────────
  static TextStyle get amountLarge => GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.vanilla, letterSpacing: -0.5,
      );

  static TextStyle get amountMedium => GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.black,
      );

  static TextStyle get amountSmall => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black,
      );
}