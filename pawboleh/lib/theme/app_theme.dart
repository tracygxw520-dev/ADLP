import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand copy used across the app. Centralized so swapping the tenant
/// brand (e.g. for a different MSME customer) only means editing this file.
class AppBrand {
  AppBrand._();
  static const String name = 'Gema';
  static const String greeting = 'Welcome back';
}

class AppColors {
  AppColors._();

  static const Color confettiPink = Color(0xFFFDE7EA);
  static const Color deepOlive = Color(0xFF4A5D23);
  static const Color gold = Color(0xFFFFD700);

  static const Color bgStart = confettiPink;
  static const Color bgEnd = Color(0xFFFFF8F0);

  static const Color textPrimary = deepOlive;

  static const Color orangeStart = gold;
  static const Color orangeEnd = Color(0xFFE8B900);

  static const Color tealStart = deepOlive;
  static const Color tealEnd = deepOlive;

  static const Color liveRed = Color(0xFFEF4444);

  // Cat mascot palette
  static const Color catFur = Color(0xFFF97316);
  static const Color catFurLight = Color(0xFFFDBA74);
  static const Color catInk = Color(0xFF3F1D0B);
  static const Color catBlush = Color(0xFFFDBA74);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgStart, bgEnd],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeStart, orangeEnd],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealStart, tealEnd],
  );
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Minimum touch target height for accessibility.
  static const double minTouchTarget = 60;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle greeting = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle brandLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary.withValues(alpha: 0.65),
  );

  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle cardSubtitle = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary.withValues(alpha: 0.7),
  );

  static TextStyle cardSubtitleOnDark = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.85),
  );

  static TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle chipLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle sectionLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle chatUsername = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle chatMessage = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary.withValues(alpha: 0.9),
  );

  static ThemeData themeData = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: GoogleFonts.interTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.tealStart,
      primary: AppColors.tealStart,
    ),
  );
}
