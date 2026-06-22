import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  COLOR SYSTEM  (Phase 2 — Premium Glassmorphism)
// ─────────────────────────────────────────────────────────────
class AppColors {
  // Primary palette
  static const Color primary      = Color(0xFF6C63FF);
  static const Color primaryDeep  = Color(0xFF4E44E7);
  static const Color primaryLight = Color(0xFFA89CFF);
  static const Color primaryGlow  = Color(0x336C63FF);

  // Accent
  static const Color teal         = Color(0xFF00E6B4);
  static const Color tealLight    = Color(0xFF33DDBB);
  static const Color coral        = Color(0xFFEF5350);
  static const Color amber        = Color(0xFFFFC107);
  static const Color success      = Color(0xFF4CAF50);
  static const Color info         = Color(0xFF00A3FF);

  // Semantic aliases
  static const Color tealSuccess  = Color(0xFF00E6B4);
  static const Color coralError   = Color(0xFFEF5350);
  static const Color amberWarning = Color(0xFFFFC107);

  // Backgrounds — light
  static const Color bg           = Color(0xFFF8F7FF);
  static const Color background   = Color(0xFFF8F7FF);
  static const Color card         = Color(0xFFFFFFFF);
  static const Color cardWhite    = Color(0xFFFFFFFF);
  static const Color surface      = Color(0xFFF0EFF8);
  static const Color inputBg      = Color(0xFFF0EFF8);

  // Backgrounds — dark
  static const Color bgDark       = Color(0xFF0A0915);
  static const Color darkBg       = Color(0xFF030206);
  static const Color cardDark     = Color(0xFF0F0C1E);
  static const Color darkCard     = Color(0xFF0F0C1E);
  static const Color surfaceDark  = Color(0xFF252340);

  // Text — light
  static const Color textPrimary     = Color(0xFF1A1830);
  static const Color textSecondary   = Color(0xFF5C5980);
  static const Color textHint        = Color(0xFF9B98B8);

  // Text — dark
  static const Color textPrimaryDark   = Color(0xFFF0EEFF);
  static const Color textSecondaryDark = Color(0xFFB8B4E0);

  // Misc
  static const Color border    = Color(0xFFE2E0F0);
  static const Color divider   = Color(0xFFEEECF8);
  static const Color overlay   = Color(0x80000000);

  // Glass surface helpers
  static Color glassLight  = Colors.white.withValues(alpha: 0.45);
  static Color glassBorderLight = Colors.white.withValues(alpha: 0.35);
  static Color glassDark   = const Color(0xFF0F0C1E).withValues(alpha: 0.45);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.07);
}

// ─────────────────────────────────────────────────────────────
//  GRADIENT SYSTEM
// ─────────────────────────────────────────────────────────────
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4E44E7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryAngled = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4E44E7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(135 * 3.14159 / 180),
  );
  static const LinearGradient teal = LinearGradient(
    colors: [Color(0xFF00E6B4), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warm = LinearGradient(
    colors: [Color(0xFFFFC107), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient dark = LinearGradient(
    colors: [Color(0xFF0A0915), Color(0xFF030206)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient headerPurple = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4E44E7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  // New Phase 2 gradients
  static const LinearGradient aurora = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00E6B4), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient deepNight = LinearGradient(
    colors: [Color(0xFF0A0915), Color(0xFF0F0C1E), Color(0xFF030206)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient coralSunset = LinearGradient(
    colors: [Color(0xFFEF5350), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // App Background Gradients
  static const LinearGradient bgLight = LinearGradient(
    colors: [Color(0xFFF8F7FF), Color(0xFFEFEFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bgDark = LinearGradient(
    colors: [Color(0xFF0A0915), Color(0xFF030206)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────
//  SHADOW SYSTEM
// ─────────────────────────────────────────────────────────────
class AppShadows {
  static const List<BoxShadow> e1 = [
    BoxShadow(color: Color(0x146C63FF), blurRadius: 8,  offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> e2 = [
    BoxShadow(color: Color(0x1F6C63FF), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> e3 = [
    BoxShadow(color: Color(0x296C63FF), blurRadius: 32, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> e4 = [
    BoxShadow(color: Color(0x3D6C63FF), blurRadius: 48, offset: Offset(0, 16)),
  ];
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A6C63FF), blurRadius: 8,  offset: Offset(0, 2)),
  ];
  // Glass morphism shadow
  static const List<BoxShadow> glass = [
    BoxShadow(color: Color(0x0F6C63FF), blurRadius: 32, offset: Offset(0, 8)),
  ];
  // Colored glow effects
  static List<BoxShadow> glow(Color color, {double intensity = 0.3}) => [
    BoxShadow(color: color.withValues(alpha: intensity), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
  ];
}

// ─────────────────────────────────────────────────────────────
//  SPACING / RADIUS
// ─────────────────────────────────────────────────────────────
class AppRadius {
  static const double xs   = 6;
  static const double sm   = 10;
  static const double md   = 14;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double full = 999;
}

class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

// ─────────────────────────────────────────────────────────────
//  TYPOGRAPHY
// ─────────────────────────────────────────────────────────────
class AppTextStyles {
  static TextStyle get display => const TextStyle(
    fontSize: 40, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -1.5, height: 1.1,
  );
  static TextStyle get h1 => const TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle get h2 => const TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.2,
  );
  static TextStyle get h3 => const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.3,
  );
  static TextStyle get h4 => const TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.3,
  );
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static TextStyle get body => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );
  static TextStyle get caption => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textHint, letterSpacing: 0.2,
  );
  static TextStyle get label => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.5,
  );
  static TextStyle get button => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.3,
  );
  static TextStyle get queueNumber => const TextStyle(
    fontFamily: 'monospace', fontSize: 72, fontWeight: FontWeight.w900,
    color: AppColors.primary, letterSpacing: -3, height: 1.0,
  );
  static TextStyle get otpText => const TextStyle(
    fontFamily: 'monospace', fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: 8,
  );
  // Dark mode variants
  static TextStyle get h3Dark => const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark, height: 1.3,
  );
  static TextStyle get bodyDark => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark, height: 1.5,
  );
}

// ─────────────────────────────────────────────────────────────
//  THEME DATA
// ─────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.teal,
        error: AppColors.coral,
        surface: AppColors.card,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Outfit',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        color: AppColors.card,
        shadowColor: AppColors.primaryGlow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.teal,
        error: AppColors.coral,
        surface: AppColors.cardDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: 'Outfit',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        color: AppColors.cardDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
    );
  }
}
