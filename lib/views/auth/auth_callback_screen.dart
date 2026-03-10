import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/atomic_state/auth_state.dart';
import '../../core/global_atoms.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    authState.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    authState.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (authState.value is! Initial && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
