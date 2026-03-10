import 'package:flutter/material.dart';

import '../../../core/ui/_theme.dart';
import '../../../core/ui/text.dart';
import '../../../models/exercise_model.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final stats = <({String label, String value})>[];

    if (exercise.sets != null && exercise.reps != null) {
      stats.add((label: 'Sets × Reps', value: '${exercise.sets} × ${exercise.reps}'));
    } else if (exercise.sets != null) {
      stats.add((label: 'Sets', value: '${exercise.sets}'));
    } else if (exercise.reps != null) {
      stats.add((label: 'Reps', value: '${exercise.reps}'));
    }
    if (exercise.duration != null) {
      stats.add((label: 'Duration', value: exercise.duration!));
    }
    if (exercise.rest != null) {
      stats.add((label: 'Rest', value: exercise.rest!));
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < stats.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).surfaceColor,
                borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
                boxShadow: DesignTokens.defaultShadow,
              ),
              child: Column(
                children: [
                  UIKText.small(
                    stats[i].label,
                    color: Theme.of(context).onSurfaceColor.withAlpha(150),
                  ),
                  const SizedBox(height: 4),
                  UIKText.h6(stats[i].value),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
