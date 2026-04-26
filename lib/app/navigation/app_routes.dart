import 'package:flutter/material.dart';

import '../../features/auth/login_page.dart';
import '../../features/home/home_page.dart';
import '../../features/lists/lists_page.dart';
import '../../features/map/map_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/social/social_page.dart';
import 'app_shell.dart';
import 'placeholder_detail_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String shell = '/';
  static const String detail = '/placeholder-detail';
  static const String login = '/login';

  static Map<String, WidgetBuilder> get all => <String, WidgetBuilder>{
    shell: (_) => const AppShell(),
    detail: (_) => const PlaceholderDetailPage(),
    login: (_) => const LoginPage(),
  };

  static const List<AppTabDefinition> tabs = <AppTabDefinition>[
    AppTabDefinition(
      title: 'Home',
      routeName: '/home',
      appBarTitle: 'TripCentral Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      pageBuilder: HomePage.new,
    ),
    AppTabDefinition(
      title: 'Lists',
      routeName: '/lists',
      appBarTitle: 'Collaborative Lists',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt_rounded,
      pageBuilder: ListsPage.new,
    ),
    AppTabDefinition(
      title: 'Map',
      routeName: '/map',
      appBarTitle: 'Travel Map',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      pageBuilder: MapPage.new,
    ),
    AppTabDefinition(
      title: 'Social',
      routeName: '/social',
      appBarTitle: 'Social Planning',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      pageBuilder: SocialPage.new,
    ),
    AppTabDefinition(
      title: 'Profile',
      routeName: '/profile',
      appBarTitle: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      pageBuilder: ProfilePage.new,
    ),
  ];
}

class AppTabDefinition {
  const AppTabDefinition({
    required this.title,
    required this.routeName,
    required this.appBarTitle,
    required this.icon,
    required this.selectedIcon,
    required this.pageBuilder,
  });

  final String title;
  final String routeName;
  final String appBarTitle;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function({Key? key}) pageBuilder;
}
