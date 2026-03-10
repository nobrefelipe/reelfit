import 'package:flutter/material.dart';
import 'package:reelfit/core/ui/text.dart';
import 'package:reelfit/models/exercise_model.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: UIKText.h4(exercise.name)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
