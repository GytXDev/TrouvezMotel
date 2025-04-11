import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF002B7F);
  static const Color secondary = Color(0xFFFFB100);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    background: AppColors.background,
  ),

  // ✅ Remplace Montserrat par Poppins
  fontFamily: GoogleFonts.poppins().fontFamily,

  textTheme: GoogleFonts.poppinsTextTheme().copyWith(
    headlineSmall: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      color: AppColors.textSecondary,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    labelStyle: GoogleFonts.poppins(
      color: AppColors.textSecondary,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
  ),
);
