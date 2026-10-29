import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema claro do app (todas as telas, exceto login/cadastro, que usam
/// auth_theme.dart).
class AppTheme {
  AppTheme._();

  static ThemeData get claro => ThemeData(
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          surface: kSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimary,
          foregroundColor: kSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kSurface,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: kSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          labelStyle: const TextStyle(color: kTextSecondary),
          hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.7)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kTextSecondary, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      );
}
