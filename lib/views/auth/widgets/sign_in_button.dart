import 'package:flutter/material.dart';

import '../../../core/ui/buttons/ui_kit_button.dart';
import '../sign_in_sheet.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: UIKButton.ghost.small(
        label: 'Sign in',
        fullWidth: false,
        onTap: () async => SignInSheet.show(
          context,
          title: 'Sign in to ReelFit',
          subtitle: 'Sync your history and unlock unlimited extracts.',
        ),
      ),
    );
  }
}
