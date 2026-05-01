import 'package:flutter/material.dart';
import 'package:trip_central/features/home/ui/home_screen.dart'; // Which currently has the lists
import 'package:trip_central/features/chat/ui/chat_list_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore New places with ease',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Placeholder for maps images
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 10),
                    color: Colors.grey[300],
                    child: const Center(child: Text('Map Image 1')),
                  ),
                  Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 10),
                    color: Colors.grey[300],
                    child: const Center(child: Text('Map Image 2')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Suggested places',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // More content goes here
          ],
        ),
      ),
    );
  }
}

