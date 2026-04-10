import 'package:flutter/material.dart';

class EmptyPageScaffold extends StatelessWidget {
  const EmptyPageScaffold({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  final String title;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(title),
        leading: showBackButton && Navigator.of(context).canPop()
            ? const BackButton()
            : null,
      ),
      body: const SizedBox.shrink(),
    );
  }
}
