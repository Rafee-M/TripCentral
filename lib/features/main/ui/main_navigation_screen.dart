import 'package:flutter/material.dart';
import 'package:trip_central/features/home/ui/home_screen.dart'; // Which currently has the lists
import 'package:trip_central/features/chat/ui/chat_list_screen.dart';
import 'package:trip_central/features/trips/ui/pending_invitations_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GenericHomeScreen(),
    const HomeScreen(), // This is actually the list screen
    const ChatListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}

class GenericHomeScreen extends StatelessWidget {
  const GenericHomeScreen({super.key});

  // --- CONFIGURATION ---
  // Easily toggle images on and off here
  final bool _showImages = true;

  // Hardcoded direct URLs for the images
  final String _imageUrl1 = 'https://lh3.googleusercontent.com/gps-cs-s/APNQkAEVmxV2_yPrRsLy87v71Kc6_s9pukMVr4NQfsJzwjQ72ZYgHd0SLNzYkFvnVNkQDOU3KvqJaZNgwUosJOcTsmNMwneHS0lYt7SdEEgvXHhPA60Qnqq8JO8kYNbu6oNExAHDp0nz=w270-h312-n-k-no?q=80&w=600&auto=format&fit=crop';
  final String _imageUrl2 = 'https://encrypted-tbn0.gstatic.com/licensed-image?q=tbn:ANd9GcS4WGfz_BdIV5nQPtgEw_7GKwJgy1Hxsax31S2VVTtX-EZOJHZahczGCKZLl1D-gaGFbsvqq3sE6my8RtTlmkDEVqlcs8boa530t3gBYTtiJqx1w5HGdCMeTeelQkPqprp4q2FhWBg&s=19&ec=121643274?q=80&w=600&auto=format&fit=crop';
  // ---------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Home',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.onSurface),
            tooltip: 'Pending Invitations',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingInvitationsScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Explore new places with ease',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming in a future release',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Image Section
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMapCard(theme, _imageUrl1, 'Map Image 1'),
                  const SizedBox(width: 16),
                  _buildMapCard(theme, _imageUrl2, 'Map Image 2'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Extracted widget for cleaner reading
  Widget _buildMapCard(ThemeData theme, String imageUrl, String fallbackText) {
    return Container(
      width: 160,
      clipBehavior: Clip.antiAlias, // Ensures the image respects the border radius
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: _showImages
          ? Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme, fallbackText),
      )
          : _buildPlaceholder(theme, fallbackText),
    );
  }

  // Elegant fallback/placeholder
  Widget _buildPlaceholder(ThemeData theme, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}