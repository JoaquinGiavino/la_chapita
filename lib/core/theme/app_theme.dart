import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _colorScheme,
        scaffoldBackgroundColor: AppColors.black,
        textTheme: _textTheme(),
        cardTheme: _cardTheme(),
        elevatedButtonTheme: _elevatedButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        inputDecorationTheme: _inputDecorationTheme(),
        appBarTheme: _appBarTheme(),
        dividerTheme: _dividerTheme(),
        chipTheme: _chipTheme(),
        snackBarTheme: _snackBarTheme(),
        dialogTheme: _dialogTheme(),
        floatingActionButtonTheme: _fabTheme(),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.black : AppColors.grey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.vanilla
                : AppColors.white.withOpacity(0.2),
          ),
        ),
      );

  static const ColorScheme _colorScheme = ColorScheme.dark(
    primary: AppColors.vanilla,
    onPrimary: AppColors.black,
    secondary: AppColors.grey,
    onSecondary: AppColors.white,
    surface: AppColors.blackSurface,
    onSurface: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
  );

  static TextTheme _textTheme() => TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.white),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.white),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.white),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.white),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.white),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.white),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.white),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.white.withOpacity(0.85)),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.grey),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.white),
        labelSmall: AppTypography.labelSmall,
      );

  static CardTheme _cardTheme() => CardTheme(
        color: AppColors.blackSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.white.withOpacity(0.08)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vanilla,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.labelLarge,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.vanilla,
          side: const BorderSide(color: AppColors.vanilla, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.vanilla),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.vanilla,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.vanilla),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme() => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blackElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.vanilla, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey),
        floatingLabelStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.vanilla, letterSpacing: 0.3,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.grey,
        suffixIconColor: AppColors.grey,
      );

  static AppBarTheme _appBarTheme() => AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.vanilla,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.black.withOpacity(0.5),
        titleTextStyle: AppTypography.headlineMediumOnDark,
        toolbarHeight: 64,
      );

  static DividerThemeData _dividerTheme() => DividerThemeData(
        color: AppColors.white.withOpacity(0.08),
        thickness: 1,
        space: 1,
      );

  static ChipThemeData _chipTheme() => ChipThemeData(
        backgroundColor: AppColors.blackElevated,
        selectedColor: AppColors.vanilla.withOpacity(0.15),
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.white),
        side: BorderSide(color: AppColors.white.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );

  static SnackBarThemeData _snackBarTheme() => SnackBarThemeData(
        backgroundColor: AppColors.blackElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      );

  static DialogTheme _dialogTheme() => DialogTheme(
        backgroundColor: AppColors.blackSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.vanilla),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white.withOpacity(0.85),
        ),
      );

  static FloatingActionButtonThemeData _fabTheme() =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.vanilla,
        foregroundColor: AppColors.black,
        elevation: 4,
        shape: CircleBorder(),
      );
}