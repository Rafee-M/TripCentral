import 'package:flutter/material.dart';

class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  final String appName = 'TripCentral';
  final String appTagline = 'Plan trips together, in one place.';
  final Color brandColor = const Color(0xFF0F4C81);
}
