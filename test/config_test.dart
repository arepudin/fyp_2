// Test to verify the configuration system works correctly
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_2/config/app_config.dart';
import 'package:fyp_2/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('Configuration System Tests', () {
    setUpAll(() async {
      // Load test environment
      await dotenv.load(fileName: '.env.development');
    });

    test('AppConfig provides correct default values', () {
      expect(AppConfig.appName, equals('Tailormate'));
      expect(AppConfig.companyName, equals('SABA CURTAIN'));
      expect(AppConfig.companyEmail, equals('sabacurtain@gmail.com'));
      expect(AppConfig.supportPhone, equals('+60 11-1161 1627'));
      expect(AppConfig.companyLogoPath, equals('asset/SABA CURTAIN LOGO.jpg'));
      expect(AppConfig.appIconPath, equals('asset/app_icon.svg'));
    });

    test('ThemeConfig provides correct primary color', () {
      final primaryColor = ThemeConfig.primaryColor;
      expect(primaryColor, equals(const Color.fromARGB(255, 158, 19, 17)));
    });

    test('ThemeConfig builds valid theme', () {
      final theme = ThemeConfig.buildTheme();
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, equals(ThemeConfig.primaryColor));
    });

    test('Supabase configuration is accessible', () {
      expect(AppConfig.supabaseUrl, isNotEmpty);
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
      expect(AppConfig.supabaseUrl, startsWith('https://'));
    });
  });
}