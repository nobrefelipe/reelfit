import 'package:flutter/material.dart';

import '../../../core/ui/notifications/dialog/dialog.dart';
import '../../../data/auth_repository.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () => ShowDialog(
        context,
        title: 'Sign out',
        content: 'Are you sure you want to sign out?',
        onConfirm: () => AuthRepository().signOut(),
      ),
    );
  }
}
