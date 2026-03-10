import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/bottom_sheet/bottom_sheet_action.dart';
import '../../core/ui/bottom_sheet/ui_kit_bottom_sheet.dart';
import '../../core/ui/text.dart';
import '../../data/auth_repository.dart';

/// Sign-in upsell bottom sheet.
///
/// Call [SignInSheet.show] from any upsell entry point — different title and
/// subtitle copy per context:
/// ```dart
/// // Guest limit reached
/// SignInSheet.show(
///   context,
///   title: 'You\'ve used your 3 free extracts',
///   subtitle: 'Sign in with Google to save unlimited workouts and track your progress.',
/// );
///
/// // Log progress upsell
/// SignInSheet.show(
///   context,
///   title: 'Track your progress',
///   subtitle: 'Sign in to track your progress over time.',
/// );
/// ```
class SignInSheet {
  SignInSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return UIKitBottomSheet.show(
      context,
      title: title,
      content: _SignInContent(subtitle: subtitle),
      primaryAction: BottomSheetAction(
        label: 'Continue with Google',
        onTap: () async => AuthRepository().signInWithGoogle(),
      ),
      secondaryAction: BottomSheetAction(
        label: 'Maybe later',
        onTap: () async => context.pop(),
      ),
    );
  }
}

class _SignInContent extends StatelessWidget {
  const _SignInContent({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: UIKText.body(
        subtitle,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}
