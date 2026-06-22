import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.card,
      ),
      primaryColor: AppColors.accent,
      fontFamily: GoogleFonts.inter().fontFamily,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.pressStart2p(
          fontSize: 14,
          color: AppColors.accent,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.darkGray,
        thickness: 0.5,
      ),

      // Text
      textTheme: TextTheme(
        displayLarge: GoogleFonts.protestRevolution(
          fontSize: 32,
          color: AppColors.white,
        ),
        displayMedium: GoogleFonts.permanentMarker(
          fontSize: 24,
          color: AppColors.white,
        ),
        headlineMedium: GoogleFonts.lacquer(
          fontSize: 20,
          color: AppColors.white,
        ),
        titleLarge: GoogleFonts.permanentMarker(
          fontSize: 18,
          color: AppColors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.gray,
        ),
        labelLarge: GoogleFonts.pressStart2p(
          fontSize: 12,
          color: AppColors.accent,
        ),
        labelSmall: GoogleFonts.pressStart2p(
          fontSize: 9,
          color: AppColors.gray,
        ),
      ),
    );
  }
}
