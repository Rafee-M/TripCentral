import 'package:flutter/widgets.dart';

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

  static Map<String, WidgetBuilder> get all => <String, WidgetBuilder>{
    shell: (_) => const AppShell(),
    detail: (_) => const PlaceholderDetailPage(),
  };

  static const List<AppTabDefinition> tabs = <AppTabDefinition>[
    AppTabDefinition(
      title: 'Home',
      routeName: '/home',
      pageBuilder: HomePage.new,
    ),
    AppTabDefinition(
      title: 'Lists',
      routeName: '/lists',
      pageBuilder: ListsPage.new,
    ),
    AppTabDefinition(title: 'Map', routeName: '/map', pageBuilder: MapPage.new),
    AppTabDefinition(
      title: 'Social',
      routeName: '/social',
      pageBuilder: SocialPage.new,
    ),
    AppTabDefinition(
      title: 'Profile',
      routeName: '/profile',
      pageBuilder: ProfilePage.new,
    ),
  ];
}

class AppTabDefinition {
  const AppTabDefinition({
    required this.title,
    required this.routeName,
    required this.pageBuilder,
  });

  final String title;
  final String routeName;
  final Widget Function({Key? key}) pageBuilder;
}
