import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/_theme.dart';
import '../../core/ui/bottom_sheet/ui_kit_bottom_sheet.dart';
import '../../core/ui/buttons/ui_kit_button.dart';
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
      footer: _SignInFooter(context: context),
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

class _SignInFooter extends StatelessWidget {
  const _SignInFooter({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
          ),
          child: TextButton(
            onPressed: () async => AuthRepository().signInWithGoogle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        UIKButton.ghost(
          label: 'Maybe later',
          onTap: () async => context.pop(),
        ),
      ],
    );
  }
}
