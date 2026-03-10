import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../data/auth_repository.dart';
import 'atomic_state/async_atom.dart';
import 'atomic_state/auth_state.dart';
import 'atomic_state/result.dart';
import 'cache/local_cache.dart';
import 'global_atoms.dart';

/// Wraps the entire app in MaterialApp.router's builder.
/// Responsible for three things only:
///   1. Triggering checkAuth() on Initial state
///   2. Resetting all atoms on logout
///   3. Reacting to Supabase auth state changes (OAuth callback, token refresh)
///
/// Routing is handled entirely by GoRouter — never navigate from here.
class AuthBuilder extends StatefulWidget {
  final Widget child;

  const AuthBuilder({super.key, required this.child});

  @override
  State<AuthBuilder> createState() => _AuthBuilderState();
}

class _AuthBuilderState extends State<AuthBuilder> {
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription? _supabaseAuthSubscription;
  AuthState? _previousAuthState;

  @override
  void initState() {
    super.initState();
    authState.addListener(_authListener);
    Future(() => _authListener());

    // Re-verify auth every time the app comes to foreground
    _lifecycleListener = AppLifecycleListener(onResume: () => authState.emit(Initial()));

    // React to Supabase auth events: OAuth callback, token refresh, sign-out
    _supabaseAuthSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        AppCache().saveToken(session.accessToken);
        if (authState.value is! Authenticated) {
          authState.emit(Authenticated());
        }
      } else if (authState.value is! Initial) {
        authState.emit(Unauthenticated());
      }
    });
  }

  @override
  void dispose() {
    authState.removeListener(_authListener);
    _lifecycleListener.dispose();
    _supabaseAuthSubscription?.cancel();
    super.dispose();
  }

  Future<void> _authListener() async {
    final current = authState.value;

    if (current is Initial) {
      final result = await AuthRepository().checkAuth();
      _previousAuthState = current;
      authState.emit(result is Success ? Authenticated() : Unauthenticated());
      return;
    }

    if (current is Authenticated) {
      // historyController.migrateLocalVideos() — wired in Phase 2
    } else if (current is Unauthenticated) {
      // only reset if user was previously authenticated (real sign-out)
      if (_previousAuthState is Authenticated) {
        resetAllAtoms();
        await AppCache().setGuestVideoCount(0);
      }
    }

    _previousAuthState = current;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
