import 'package:flutter/material.dart';

class AppThemeFactory {
  const AppThemeFactory({required this.seedColor});

  final Color seedColor;

  ThemeData createLightTheme() {
    return _buildTheme(Brightness.light);
  }

  ThemeData createDarkTheme() {
    return _buildTheme(Brightness.dark);
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        indicatorColor: colorScheme.secondaryContainer,
        backgroundColor: colorScheme.surface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final weight = states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500;

          return TextStyle(fontSize: 12, fontWeight: weight);
        }),
      ),
    );
  }
}
