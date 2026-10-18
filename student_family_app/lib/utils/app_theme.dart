import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color deepNavy = Color(0xFF0F1C2E);
  static const Color navyLight = Color(0xFF1C2E4A);
  static const Color primary = Color(0xFF0B1E3D);
  static const Color mintEmerald = Color(0xFF2ECC9A);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color orange = Color(0xFFFF9F43);
  static const Color sky = Color(0xFF4FACFE);
  static const Color purple = Color(0xFF7C5CFF);

  static const Color textGrey = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color paidGreen = Color(0xFF2ECC9A);
  static const Color pendingAmber = Color(0xFFF5A623);
  static const Color overdueCrimson = Color(0xFFE63950);

  static const Color bgLight = Color(0xFFF4F7FB);
  static const Color sidebarBg = Color(0xFF0A172B);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE6EEF5);

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF2ECC9A), Color(0xFF1BBF8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F1C2E), Color(0xFF1C2E4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF0F1C2E), Color(0xFF1C2E4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB347), Color(0xFFF5A623)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFFB347), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFFF7E7E), Color(0xFFE63950)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFF4F7FB), Color(0xFFEDF1F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return paidGreen;
      case 'pending':
        return pendingAmber;
      case 'overdue':
        return overdueCrimson;
      case 'partial':
        return orange;
      default:
        return textGrey;
    }
  }
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

class AppText {
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textGrey,
      );

  static TextStyle get bodyBold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get statNumber => GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
      );
}

class AppTheme {
  static const Color primary = AppColors.primary;
  static const Color mintEmerald = AppColors.mintEmerald;
  static const Color textGrey = AppColors.textGrey;
  static const Color paidGreen = AppColors.paidGreen;
  static const Color pendingAmber = AppColors.pendingAmber;
  static const Color overdueCrimson = AppColors.overdueCrimson;
  static const Color bgLight = AppColors.bgLight;

  static Color getStatusColor(String? status) {
    return AppColors.getStatusColor(status);
  }

    static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.mintEmerald,
        scaffoldBackgroundColor: AppColors.bgLight,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme(),
        splashFactory: InkRipple.splashFactory,
      );
}

// ============================================================
// ✅ NEW — Dark-mode-aware color helpers (does NOT touch AppColors)
// Use these via `context.xxx` only in screens you want dark-mode-aware.
// Existing AppColors usage everywhere else remains 100% unaffected.
// ============================================================
extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get bgLight =>
      isDarkMode ? const Color(0xFF121826) : AppColors.bgLight;

  Color get cardWhite =>
      isDarkMode ? const Color(0xFF1C2333) : AppColors.cardWhite;

  Color get borderColor =>
      isDarkMode ? const Color(0xFF2A3347) : AppColors.border;

  Color get textDarkColor =>
      isDarkMode ? const Color(0xFFE2E8F0) : AppColors.textDark;

  Color get textGreyColor =>
      isDarkMode ? const Color(0xFFA0AEC0) : AppColors.textGrey;

  Color get textMutedColor =>
      isDarkMode ? const Color(0xFF718096) : AppColors.textMuted;

  LinearGradient get bgGradient => isDarkMode
      ? const LinearGradient(
          colors: [Color(0xFF0D1320), Color(0xFF121826)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : AppColors.bgGradient;

  List<BoxShadow> get cardShadow => isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ]
      : AppShadows.soft;
}