import 'package:flutter/material.dart';
import 'package:fyp_2/screens/customers/splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fyp_2/config/app_config.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'package:fyp_2/screens/customers/profile_setup.dart'; // Ensure path is correct
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
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    } catch (error) {
      debugPrint('Error checking user profile: $error');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    // Use the client ID from AppConfig
    final googleSignIn = GoogleSignIn(serverClientId: AppConfig.googleWebAppClientId);

    setState(() => _isLoading = true);

    try {
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens.');
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      if (context.mounted) await _checkAndNavigateUser(context, response.user!);

    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.errorSigningIn}$error'),
          // Use the theme's error color for consistency
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.asset(AppConfig.appIconPath, height: 300, fit: BoxFit.contain),
              gapH20,
              Text(
                '${AppStrings.welcomeTo} ${AppConfig.appName}',
                textAlign: TextAlign.center,
                // Use a standard text style from your theme
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              gapH16,
              Text(
                AppStrings.signInToContinue,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              gapH40,
              ElevatedButton.icon(
                // The style is fully inherited from ThemeConfig
                onPressed: _isLoading ? null : () => _signInWithGoogle(context),
                icon: _isLoading
                    ? Container() // Hide icon when loading
                    // Icon color will be inherited from the button's foregroundColor
                    : const Icon(Icons.login),
                label: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          // The color is inherited from the button's foregroundColor
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.signInWithGoogle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}