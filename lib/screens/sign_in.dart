// lib/screens/google_signin_screen.dart
import 'package:flutter/material.dart';
import 'package:fyp_2/screens/customers/splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'customers/profile_setup.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _isLoading = false;

  Future<void> _checkAndNavigateUser(BuildContext context, User user) async {
    try {
      // Check if user has completed profile setup
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // User hasn't completed profile setup, navigate to profile setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        // User has completed profile setup, navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    } catch (error) {
      debugPrint('Error checking user profile: $error');
      // If there's an error, default to profile setup to be safe
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final googleSignIn = GoogleSignIn(
      serverClientId: '619873992295-gi2hlqn52e30r0dnkskq8th6qo12d1kr.apps.googleusercontent.com',
      scopes: [
        'email',
        'profile',
        'openid',
      ],
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // Clear any existing sign-in state
      await googleSignIn.signOut();
      
      // Start the Google Sign-In flow
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('Google User: ${googleUser.email}');

      // Get the authentication tokens
      final googleAuth = await googleUser.authentication;
      
      debugPrint('Access Token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}');
      debugPrint('ID Token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens. Please check your configuration.');
      }

      // Sign in to Supabase using the Google tokens
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('Supabase sign-in successful: ${response.user?.email}');

      // Check if user has completed profile setup
      if (context.mounted) {
        await _checkAndNavigateUser(context, response.user!);
      }
    } catch (error) {
      debugPrint("Google Sign-In Error: $error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error signing in: $error"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo
              SvgPicture.asset(
                'lib/asset/app_icon.svg',
                height: 300,
                width: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Welcome Title
              const Text(
                'Welcome to Tailormate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Sign in with Google to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              // Sign In Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _signInWithGoogle(context),
                icon: Icon(
                  _isLoading ? Icons.lock_clock : Icons.account_box,
                  color: Colors.white,
                ),
                label: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}