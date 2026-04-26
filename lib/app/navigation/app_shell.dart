import 'package:flutter/material.dart';

import 'app_routes.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = AppRoutes.tabs;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs.map((tab) => tab.pageBuilder()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        height: 76,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Lists',
          ),
        ],
      ),
    );
  }
}
