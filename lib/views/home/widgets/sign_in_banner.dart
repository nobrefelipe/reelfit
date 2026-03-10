import 'package:flutter/material.dart';

import '../../../core/ui/text.dart';
import '../../auth/sign_in_sheet.dart';

class SignInBanner extends StatelessWidget {
  const SignInBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => SignInSheet.show(
        context,
        title: 'Sync & unlock unlimited extracts',
        subtitle:
            'Sign in to save your history across devices and extract unlimited workouts.',
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.workspace_premium, color: primary, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UIKText.small(
                    'Sync & unlock unlimited extracts',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: 2),
                  UIKText.small(
                    'Sign in to save your history across devices and extract unlimited workouts.',
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
