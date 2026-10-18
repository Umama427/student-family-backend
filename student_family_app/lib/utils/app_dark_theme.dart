import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDarkColors {
  static const Color bgDark = Color(0xFF121826);
  static const Color cardDark = Color(0xFF1C2333);
  static const Color borderDark = Color(0xFF2A3347);
  static const Color textLightOnDark = Color(0xFFE2E8F0);
  static const Color textMutedOnDark = Color(0xFF94A3B8);
  static const Color mintEmerald = Color(0xFF2ECC9A);
}

class AppDarkTheme {
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppDarkColors.mintEmerald,
        scaffoldBackgroundColor: AppDarkColors.bgDark,
        cardColor: AppDarkColors.cardDark,
        dividerColor: AppDarkColors.borderDark,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: AppDarkColors.textLightOnDark,
          displayColor: AppDarkColors.textLightOnDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppDarkColors.bgDark,
          elevation: 0,
          foregroundColor: AppDarkColors.textLightOnDark,
        ),
        splashFactory: InkRipple.splashFactory,
      );
}