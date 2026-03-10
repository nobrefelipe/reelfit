import 'package:flutter/material.dart';
import 'package:reelfit/core/ui/text.dart';

class DietDetailScreen extends StatelessWidget {
  const DietDetailScreen({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: UIKText.h4('Diet')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
