import 'package:flutter/material.dart';

class PlaceholderDetailPage extends StatelessWidget {
  const PlaceholderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Base Detail Screen')),
      body: const SizedBox.shrink(),
    );
  }
}
