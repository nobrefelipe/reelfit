import 'package:flutter/material.dart';

import '../../../core/ui/_theme.dart';
import '../../../core/ui/text.dart';
import '../../../models/exercise_model.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.exercise, required this.onTap});

  final ExerciseModel exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).surfaceColor,
          borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
          boxShadow: DesignTokens.defaultShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.buttonBorderRadius),
                bottomLeft: Radius.circular(DesignTokens.buttonBorderRadius),
              ),
              child: exercise.imageUrl != null
                  ? Image.network(
                      exercise.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const PlaceholderIcon(),
                    )
                  : const PlaceholderIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UIKText.h6(exercise.name),
                    const SizedBox(height: 4),
                    UIKText.small(
                      exercise.targetMuscleGroup,
                      color: DesignTokens.primary,
                    ),
                    const SizedBox(height: 6),
                    ExerciseStats(exercise: exercise),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderIcon extends StatelessWidget {
  const PlaceholderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: DesignTokens.primary.withAlpha(30),
      child: const Icon(Icons.fitness_center, color: DesignTokens.primary),
    );
  }
}

class ExerciseStats extends StatelessWidget {
  const ExerciseStats({super.key, required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (exercise.sets != null && exercise.reps != null) {
      parts.add('${exercise.sets} × ${exercise.reps} reps');
    } else if (exercise.sets != null) {
      parts.add('${exercise.sets} sets');
    } else if (exercise.reps != null) {
      parts.add('${exercise.reps} reps');
    }
    if (exercise.duration != null) parts.add(exercise.duration!);
    if (exercise.rest != null) parts.add('Rest: ${exercise.rest}');

    if (parts.isEmpty) return const SizedBox.shrink();

    return UIKText.small(
      parts.join('  ·  '),
      color: Theme.of(context).onSurfaceColor.withAlpha(150),
    );
  }
}
