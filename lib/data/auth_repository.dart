import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/atomic_state/result.dart';
import '../core/cache/local_cache.dart';
import '../core/env.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<Result<bool>> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Env.supabaseRedirectUrl,
    );
    return Success(true); // actual auth state arrives via onAuthStateChange
  }

  Future<Result<bool>> checkAuth() async {
    final session = _client.auth.currentSession;
    if (session == null) return Failure('No session');
    await AppCache().saveToken(session.accessToken);
    return Success(true);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await AppCache().clearToken();
  }
}
