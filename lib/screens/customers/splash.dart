import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_2/constants/supabase.dart';
import 'package:fyp_2/screens/customers/home_page.dart';
import 'package:fyp_2/screens/customers/onboarding.dart'; // Create this if you don't have it
import 'package:fyp_2/screens/customers/profile_setup.dart';
import 'package:fyp_2/screens/sign_in.dart';
import 'package:fyp_2/screens/tailors/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // This slight delay ensures the widget is fully built before navigating.
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // --- 1. Check Onboarding Status ---
    final prefs = await SharedPreferences.getInstance();
    final bool hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;

    if (!hasCompletedOnboarding) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }

    // --- 2. Check Authentication and Role ---
    final session = supabase.auth.currentSession;
    if (session == null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GoogleSignInScreen()));
      return;
    }

    try {
      final userId = session.user.id;
      final response = await supabase
          .from('user_profiles')
          .select('role')
          .eq('user_id', userId)
          .single();
      
      final role = response['role'];
      
      if (role == 'tailor') {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TailorDashboardScreen()));
      } else { // 'customer' or any other default
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()));
      }

    } catch (error) {
      // This error often happens if a user signs up but hasn't created a profile yet.
      // We send them to the profile setup screen.
      debugPrint("Redirect Error: Profile not found for new user. $error");
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}