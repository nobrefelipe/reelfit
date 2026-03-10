import 'package:flutter/material.dart';

import '../../../controllers/progress_controller.dart';
import '../../../core/ui/text.dart';
import '../../../models/exercise_model.dart';
import 'guest_progress_prompt.dart';
import 'progress_chart.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({
    super.key,
    required this.exercise,
    required this.isGuest,
    this.onAdd,
  });

  final ExerciseModel exercise;
  final bool isGuest;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return GuestProgressPrompt(exercise: exercise);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UIKText.h5('Progress'),
            if (onAdd != null)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onAdd,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        progress(
          success: ProgressChart.new,
          loading: () => const Center(child: CircularProgressIndicator()),
          empty: () => UIKText.body('No progress logged yet'),
          idle: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
