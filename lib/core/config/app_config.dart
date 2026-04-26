import 'package:flutter/material.dart';

class AppConfig {
  AppConfig._internal();

  // Singleton access for all app-level constants.
  static final AppConfig instance = AppConfig._internal();

  final String appName = 'TripCentral';
  final String appTagline = 'Plan trips together, in one place.';
  final String appVersion = '0.1.0';

  // Foundation-level flags can live here until remote config is added.
  final bool enableDebugLogs = true;

  final Color brandColor = const Color(0xFF0F4C81);
}
