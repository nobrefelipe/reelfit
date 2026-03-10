import 'package:flutter/material.dart';
import 'package:reelfit/core/ui/text.dart';

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: UIKText.h4('Workout')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
