// import 'package:get/route_manager.dart';

abstract class Env {
  static String get apiBaseUrl => const String.fromEnvironment("DEFINE_API_URL");

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const supabaseRedirectUrl = String.fromEnvironment('SUPABASE_REDIRECT_URL');

  static bool get suppressApiLogging => const bool.fromEnvironment("DEFINE_SUPPRESS_API_LOGS");

  static bool get isInDebugMode => const bool.fromEnvironment("DEFINE_IS_DEV");
  static bool get isProd => const bool.fromEnvironment("DEFINE_IS_PROD");
  static bool get isAlpha => const bool.fromEnvironment("DEFINE_IS_ALPHA");
}
