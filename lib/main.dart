import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/customers/splash.dart';
import 'config/app_config.dart';
import 'config/theme_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration based on environment
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  await AppConfig.initialize(environment: environment);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.buildTheme(),
      home: const SplashScreen(),
    );
  }
}