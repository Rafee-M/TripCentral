import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import 'navigation/app_routes.dart';
import 'theme/app_theme_factory.dart';

class TripCentralApp extends StatelessWidget {
  const TripCentralApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = AppConfig.instance;
    final themeFactory = AppThemeFactory(seedColor: appConfig.brandColor);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appConfig.appName,
      theme: themeFactory.createLightTheme(),
      darkTheme: themeFactory.createDarkTheme(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.shell,
      routes: AppRoutes.all,
    );
  }
}
