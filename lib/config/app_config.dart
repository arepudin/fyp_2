import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // App Information
  static String get appName => dotenv.env['APP_NAME'] ?? 'Tailormate';
  
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://pyudegqeszdngzicuwat.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5dWRlZ3Flc3pkbmd6aWN1d2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4ODg5MzUsImV4cCI6MjA2NTQ2NDkzNX0.Kl0j8M1IyBuatxKTtfLo0ddiPQEd_P2RIA8ZIRgw_bQ';
  
  // Company Information
  static String get companyName => dotenv.env['COMPANY_NAME'] ?? 'SABA CURTAIN';
  static String get companyEmail => dotenv.env['COMPANY_EMAIL'] ?? 'sabacurtain@gmail.com';
  static String get supportPhone => dotenv.env['SUPPORT_PHONE'] ?? '+60 11-1161 1627';
  
  // Asset Paths
  static String get companyLogoPath => dotenv.env['COMPANY_LOGO_PATH'] ?? 'asset/SABA CURTAIN LOGO.jpg';
  static String get appIconPath => dotenv.env['APP_ICON_PATH'] ?? 'asset/app_icon.svg';
  
  // Initialize configuration
  static Future<void> initialize({String environment = 'development'}) async {
    await dotenv.load(fileName: '.env.$environment');
  }
}