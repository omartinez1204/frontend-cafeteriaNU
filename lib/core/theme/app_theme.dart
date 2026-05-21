import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ─── TEMA CLARO ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: NovaColors.greenDark,
      onPrimary: Colors.white,
      primaryContainer: NovaColors.greenLight,
      onPrimaryContainer: NovaColors.greenDark,
      secondary: NovaColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: NovaColors.goldLight,
      onSecondaryContainer: NovaColors.gold,
      surface: Colors.white,
      onSurface: NovaColors.black,
      surfaceContainerHighest: NovaColors.grayLight,
      onSurfaceVariant: const Color(0xFF49454F),
      error: NovaColors.error,
      onError: Colors.white,
      outline: NovaColors.grayMedium,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NovaColors.grayLight,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: NovaColors.greenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Botones ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NovaColors.greenDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: NovaColors.grayMedium,
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NovaColors.greenDark,
          side: const BorderSide(color: NovaColors.greenDark, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NovaColors.greenMedium,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.grayMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.grayMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.greenDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF49454F),
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: NovaColors.grayMedium,
        suffixIconColor: NovaColors.grayMedium,
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: NovaColors.greenDark.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: NovaColors.greenLight,
        labelStyle: const TextStyle(color: NovaColors.greenDark),
        side: BorderSide.none,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: NovaColors.greenDark,
        unselectedItemColor: Color(0xFF49454F),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // ─── TEMA OSCURO ──────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: NovaColors.greenMedium,
      onPrimary: Colors.white,
      primaryContainer: NovaColors.greenDark,
      onPrimaryContainer: NovaColors.greenLight,
      secondary: NovaColors.gold,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF4A3500),
      onSecondaryContainer: NovaColors.goldLight,
      surface: const Color(0xFF1C1B1F),
      onSurface: const Color(0xFFE6E1E5),
      surfaceContainerHighest: const Color(0xFF2B2930),
      onSurfaceVariant: const Color(0xFFCAC4D0),
      error: const Color(0xFFF2B8B5),
      onError: const Color(0xFF601410),
      outline: const Color(0xFF938F99),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1C1B1F),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A4731),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NovaColors.greenMedium,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2B2930),
          disabledForegroundColor: Colors.white38,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NovaColors.greenLight,
          side: const BorderSide(color: NovaColors.greenLight, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NovaColors.greenLight,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2B2930),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF938F99)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF938F99)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.greenMedium, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF2B8B5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF2B8B5), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFCAC4D0),
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: const Color(0xFF938F99),
        suffixIconColor: const Color(0xFF938F99),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF2B2930),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFF1A4731),
        labelStyle: const TextStyle(color: NovaColors.greenLight),
        side: BorderSide.none,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: NovaColors.gold,
        unselectedItemColor: Color(0xFFCAC4D0),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Color(0xFF2B2930),
      ),
    );
  }

  // ─── TEMA ROSA (PINK MODE) ────────────────────────────────────
  static ThemeData get pinkTheme {
    final colorScheme = ColorScheme.light(
      primary: const Color(0xFFD81B60),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFCE4EC),
      onPrimaryContainer: const Color(0xFFD81B60),
      secondary: const Color(0xFFFF4081),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFFF0F5),
      onSecondaryContainer: const Color(0xFFFF4081),
      surface: Colors.white,
      onSurface: const Color(0xFF2C2C2C),
      surfaceContainerHighest: const Color(0xFFF9F5F7),
      onSurfaceVariant: const Color(0xFF5D5759),
      error: NovaColors.error,
      onError: Colors.white,
      outline: const Color(0xFFE8D7DC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFAF0F3),

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD81B60),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Botones ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD81B60),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8D7DC),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD81B60),
          side: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFD81B60),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D7DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D7DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD81B60), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NovaColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF5D5759),
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: const Color(0xFFD81B60).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFFFFF7F9),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFFCE4EC),
        labelStyle: const TextStyle(color: Color(0xFFD81B60)),
        side: BorderSide.none,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFFD81B60),
        unselectedItemColor: Color(0xFF5D5759),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
      ),
    );
  }

  // ─── TEMA PÚRPURA (PURPLE MODE) ───────────────────────────────
  static ThemeData get purpleTheme {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFFAB47BC),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF4A148C),
      onPrimaryContainer: const Color(0xFFE1BEE7),
      secondary: const Color(0xFFE040FB),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF310057),
      onSecondaryContainer: const Color(0xFFF3E5F5),
      surface: const Color(0xFF120E1E),
      onSurface: const Color(0xFFECE7F2),
      surfaceContainerHighest: const Color(0xFF221733),
      onSurfaceVariant: const Color(0xFFCAC4D0),
      error: const Color(0xFFF2B8B5),
      onError: const Color(0xFF601410),
      outline: const Color(0xFF7B1FA2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F0B18),

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF310057),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Botones ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAB47BC),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF221733),
          disabledForegroundColor: Colors.white38,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE1BEE7),
          side: const BorderSide(color: Color(0xFFCE93D8), width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFE1BEE7),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF221733),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B1FA2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B1FA2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAB47BC), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF2B8B5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF2B8B5), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFCAC4D0),
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF221733),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFF4A148C),
        labelStyle: const TextStyle(color: Color(0xFFE1BEE7)),
        side: BorderSide.none,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFFE040FB),
        unselectedItemColor: Color(0xFFCAC4D0),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Color(0xFF221733),
      ),
    );
  }

  static ThemeData getTheme(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.light:
        return lightTheme;
      case AppThemeStyle.dark:
        return darkTheme;
      case AppThemeStyle.pink:
        return pinkTheme;
      case AppThemeStyle.purple:
        return purpleTheme;
    }
  }
}

enum AppThemeStyle {
  light,
  dark,
  pink,
  purple,
}
