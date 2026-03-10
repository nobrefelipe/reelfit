import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth_builder.dart';
import 'core/cache/local_cache.dart';
import 'core/env.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppCache().init();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  runApp(const ReelFitApp());
}

class ReelFitApp extends StatelessWidget {
  const ReelFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ReelFit',
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) => AuthBuilder(child: child ?? const SizedBox()),
    );
  }
}
