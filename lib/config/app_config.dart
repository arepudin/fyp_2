import 'dart:ui';

class AppConfig {

// Google Sign-In Configuration
  static const String googleWebAppClientId = String.fromEnvironment(
    'GOOGLE_WEB_APP_CLIENT_ID',
    defaultValue: '619873992295-gi2hlqn52e30r0dnkskq8th6qo12d1kr.apps.googleusercontent.com',
  );

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pyudegqeszdngzicuwat.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5dWRlZ3Flc3pkbmd6aWN1d2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4ODg5MzUsImV4cCI6MjA2NTQ2NDkzNX0.Kl0j8M1IyBuatxKTtfLo0ddiPQEd_P2RIA8ZIRgw_bQ',
  );

  // App Branding
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Tailormate',
  );
  
  static const String companyName = String.fromEnvironment(
    'COMPANY_NAME',
    defaultValue: 'SABA CURTAIN',
  );

  // Theme Configuration
  static const int primaryColorRed = int.fromEnvironment('PRIMARY_COLOR_RED', defaultValue: 158);
  static const int primaryColorGreen = int.fromEnvironment('PRIMARY_COLOR_GREEN', defaultValue: 19);
  static const int primaryColorBlue = int.fromEnvironment('PRIMARY_COLOR_BLUE', defaultValue: 17);
  
  // Contact Information
  static const String supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+60 11-1161 1627',
  );
  
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'sabacurtain@gmail.com',
  );

  // Asset Paths
  static const String appIconPath = String.fromEnvironment(
    'APP_ICON_PATH',
    defaultValue: 'lib/asset/app_icon.svg',
  );
  
  static const String companyLogoPath = String.fromEnvironment(
    'COMPANY_LOGO_PATH',
    defaultValue: 'asset/SABA CURTAIN LOGO.jpg',
  );
  
  static const String onboardingImage1 = String.fromEnvironment(
    'ONBOARDING_IMAGE_1',
    defaultValue: 'asset/placeholder1.png',
  );
  
  static const String onboardingImage2 = String.fromEnvironment(
    'ONBOARDING_IMAGE_2',
    defaultValue: 'asset/placeholder2.png',
  );
  
  static const String onboardingImage3 = String.fromEnvironment(
    'ONBOARDING_IMAGE_3',
    defaultValue: 'asset/placeholder3.png',
  );

  // Derived properties
  static Color get primaryColor => Color.fromARGB(
    255,
    primaryColorRed,
    primaryColorGreen,
    primaryColorBlue,
  );
}