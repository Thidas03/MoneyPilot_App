import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Centralized Theme configuration for MoneyPilot.
/// Built with Material 3, GoogleFonts Inter (body) and Outfit (headings).
class AppTheme {
  AppTheme._();

  /// Creates typography combining Outfit for headings and Inter for body/labels.
  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    final interTextTheme = GoogleFonts.interTextTheme();
    final outfitTextTheme = GoogleFonts.outfitTextTheme();

    return interTextTheme.copyWith(
      // Headings use Outfit for a premium, bold fintech feel
      displayLarge: outfitTextTheme.displayLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: outfitTextTheme.displayMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displaySmall: outfitTextTheme.displaySmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: outfitTextTheme.headlineLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: outfitTextTheme.headlineMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: outfitTextTheme.headlineSmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: outfitTextTheme.titleLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: outfitTextTheme.titleMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: outfitTextTheme.titleSmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),

      // Body and labels use Inter for high legibility
      bodyLarge: interTextTheme.bodyLarge?.copyWith(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: interTextTheme.bodyMedium?.copyWith(
        color: secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: interTextTheme.bodySmall?.copyWith(
        color: secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: interTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.1,
      ),
      labelMedium: interTextTheme.labelMedium?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: interTextTheme.labelSmall?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 10,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Light Theme Definition
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      AppColors.textPrimaryLight,
      AppColors.textSecondaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.teal,
        onSecondary: Colors.white,
        tertiary: AppColors.indigo,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.dividerLight,
        error: AppColors.expense,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMutedLight,
          fontSize: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 1,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondaryLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondaryLight,
            size: 24,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark Theme Definition
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
      AppColors.textPrimaryDark,
      AppColors.textSecondaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: Colors.black,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.teal,
        onSecondary: Colors.black,
        tertiary: AppColors.indigo,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.dividerDark,
        error: AppColors.expense,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 1,
        indicatorColor: AppColors.primaryDark.withValues(alpha: 0.5),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryLight : AppColors.textSecondaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.primaryLight : AppColors.textSecondaryDark,
            size: 24,
          );
        }),
      ),
    );
  }
}
