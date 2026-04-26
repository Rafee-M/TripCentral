import 'package:flutter/material.dart';

import '../map/map_page.dart';
import '../../app/navigation/app_routes.dart';
import '../../core/patterns/singleton/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final session = SupabaseService.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (isLoggedIn)
            TextButton.icon(
              onPressed: () async {
                await SupabaseService.instance.client.auth.signOut();
                setState(() {}); // Refresh UI
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            )
          else
            TextButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.login);
                setState(() {}); // Refresh UI so it detects login state
              },
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore New places with ease',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapPage()),
                );
              },
              decoration: InputDecoration(
                hintText: 'Where do you want to go?',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Suggested places',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPlaceCard('https://picsum.photos/400/300?random=1', 'Place 1'),
                  _buildPlaceCard('https://picsum.photos/400/300?random=2', 'Place 2'),
                  _buildPlaceCard('https://picsum.photos/400/300?random=3', 'Place 3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(String imageUrl, String title) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
