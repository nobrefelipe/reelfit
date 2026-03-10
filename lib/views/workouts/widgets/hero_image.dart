import 'package:flutter/material.dart';

import '../../../core/ui/_theme.dart';
import '../../../models/exercise_model.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key, required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
      child: exercise.imageUrl != null
          ? Image.network(
              exercise.imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const FallbackImage(),
            )
          : const FallbackImage(),
    );
  }
}

class FallbackImage extends StatelessWidget {
  const FallbackImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      color: DesignTokens.primary.withAlpha(30),
      child: const Icon(Icons.fitness_center, size: 64, color: DesignTokens.primary),
    );
  }
}
