import 'package:flutter/material.dart';

import '../../../core/ui/_theme.dart';
import '../../../core/ui/buttons/ui_kit_button.dart';
import '../../../core/ui/text.dart';
import '../../../models/exercise_model.dart';
import '../../auth/sign_in_sheet.dart';

class GuestProgressPrompt extends StatelessWidget {
  const GuestProgressPrompt({super.key, required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).surfaceColor,
        borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
        boxShadow: DesignTokens.defaultShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 40, color: DesignTokens.primary),
          const SizedBox(height: 12),
          UIKText.h5('Track your progress'),
          const SizedBox(height: 8),
          UIKText.body(
            'Sign in to log and track your progress over time.',
            textAlign: TextAlign.center,
            color: Theme.of(context).onSurfaceColor.withAlpha(150),
          ),
          const SizedBox(height: 16),
          UIKButton.primary(
            label: 'Sign in',
            onTap: () async => SignInSheet.show(
              context,
              title: 'Track your progress',
              subtitle: 'Sign in to log and track your progress over time.',
            ),
          ),
        ],
      ),
    );
  }
}
