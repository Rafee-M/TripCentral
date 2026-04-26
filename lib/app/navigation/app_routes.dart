import 'package:flutter/material.dart';

import 'app_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const String shell = '/';
  static const String detail = '/placeholder-detail';

  static Map<String, WidgetBuilder> get all => <String, WidgetBuilder>{
    shell: (_) => const AppShell(),
    detail: (_) => const _PlaceholderDetailPage(),
  };

  // Teammate integration guide:
  // 1) Keep this tabs list as the single source of truth for shell pages and
  //    bottom navigation destinations.
  // 2) When a feature page is ready, replace one pageBuilder with that page.
  //    Example:
  //    pageBuilder: (context) => const HomePage(),
  // 3) Do not change AppShell for feature wiring. AppShell reads this list and
  //    updates both the IndexedStack and NavigationBar automatically.
  // 4) Keep placeholders in unfinished tabs so the app always compiles.

  static final List<AppTabDefinition> tabs = <AppTabDefinition>[
    AppTabDefinition(
      title: 'Home',
      routeName: '/home',
      appBarTitle: 'TripCentral Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      pageBuilder: _buildHomePage,
    ),
    AppTabDefinition(
      title: 'Lists',
      routeName: '/lists',
      appBarTitle: 'Collaborative Lists',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt_rounded,
      pageBuilder: _buildListsPage,
    ),
    AppTabDefinition(
      title: 'Map',
      routeName: '/map',
      appBarTitle: 'Travel Map',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      pageBuilder: _buildMapPage,
    ),
    AppTabDefinition(
      title: 'Social',
      routeName: '/social',
      appBarTitle: 'Social Planning',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      pageBuilder: _buildSocialPage,
    ),
    AppTabDefinition(
      title: 'Profile',
      routeName: '/profile',
      appBarTitle: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      pageBuilder: _buildProfilePage,
    ),
  ];

  static Widget _buildHomePage(BuildContext context) {
    return const _TabPlaceholderPage(
      title: 'TripCentral Home',
      icon: Icons.home_rounded,
      description:
          'Home module placeholder is ready. Teammate widgets can be attached here later.',
    );
  }

  static Widget _buildListsPage(BuildContext context) {
    return const _TabPlaceholderPage(
      title: 'Collaborative Lists',
      icon: Icons.list_alt_rounded,
      description:
          'Lists module placeholder is ready. Your shell and routing already support integration.',
    );
  }

  static Widget _buildMapPage(BuildContext context) {
    return const _TabPlaceholderPage(
      title: 'Travel Map',
      icon: Icons.map_rounded,
      description:
          'Map module placeholder is active. Google Maps implementation can plug in later.',
    );
  }

  static Widget _buildSocialPage(BuildContext context) {
    return const _TabPlaceholderPage(
      title: 'Social Planning',
      icon: Icons.forum_rounded,
      description:
          'Social module placeholder is active. Team feed and chat can be integrated here.',
    );
  }

  static Widget _buildProfilePage(BuildContext context) {
    return const _TabPlaceholderPage(
      title: 'Profile',
      icon: Icons.person_rounded,
      description:
          'Profile module placeholder is active. Authentication and settings can be attached later.',
    );
  }
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
  final WidgetBuilder pageBuilder;
}

class SharedBasePageScaffold extends StatelessWidget {
  const SharedBasePageScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabPlaceholderPage extends StatelessWidget {
  const _TabPlaceholderPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SharedBasePageScaffold(
      title: title,
      icon: icon,
      description: description,
    );
  }
}

class _PlaceholderDetailPage extends StatelessWidget {
  const _PlaceholderDetailPage();

  @override
  Widget build(BuildContext context) {
    return const SharedBasePageScaffold(
      title: 'Detail Placeholder',
      icon: Icons.description_outlined,
      description:
          'Detail route is available and safe to use while team feature pages are still under development.',
    );
  }
}
