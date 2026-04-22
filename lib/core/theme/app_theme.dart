import 'package:flutter/material.dart';

class AppTheme {
  // Colores base
  static const Color crimson     = Color(0xFF8B0000);
  static const Color crimsonDeep = Color(0xFF5A0000);
  static const Color gold        = Color(0xFFFFD700);
  static const Color darkBg      = Color(0xFF0E0E0E);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard    = Color(0xFF201F1F);
  static const Color darkCardHigh= Color(0xFF353534);
  static const Color outline     = Color(0xFF2A2A2A);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: crimson,
      secondary: gold,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
    ),
    scaffoldBackgroundColor: darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: crimson,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: crimson,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF888888)),
      prefixIconColor: const Color(0xFF888888),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF141414),
      selectedItemColor: crimson,
      unselectedItemColor: Color(0xFF666666),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: outline,
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xFF666666),
      indicatorColor: crimson,
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: crimson,
      secondary: gold,
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F0F0),
    appBarTheme: const AppBarTheme(
      backgroundColor: crimson,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: crimson,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: crimson, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF666666)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: crimson,
      unselectedItemColor: Color(0xFF999999),
      type: BottomNavigationBarType.fixed,
      elevation: 4,
    ),
  );
}