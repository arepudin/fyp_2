import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_2/config/app_config.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'package:fyp_2/screens/sign_in.dart'; // Make sure this path is correct

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static final List<Map<String, String>> onboardingData = [
    {'image': AppConfig.onboardingImage1, 'title': AppStrings.onboarding1Title, 'description': AppStrings.onboarding1Desc},
    {'image': AppConfig.onboardingImage2, 'title': AppStrings.onboarding2Title, 'description': AppStrings.onboarding2Desc},
    {'image': AppConfig.companyLogoPath, 'title': AppStrings.onboarding3Title, 'description': AppStrings.onboarding3Desc},
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GoogleSignInScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(AppStrings.skip, style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (_, index) => _buildOnboardingPage(
                  image: onboardingData[index]['image']!,
                  title: onboardingData[index]['title']!,
                  description: onboardingData[index]['description']!,
                  context: context,
                ),
              ),
            ),
            _buildScrollIndicator(theme.colorScheme.primary),
            gapH20,
            _buildNavigationButtons(theme),
            gapH40,
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({ required String image, required String title, required String description, required BuildContext context}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300),
          gapH40,
          // --- FIX HERE ---
          Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          gapH16,
          // --- FIX HERE ---
          Text(description, textAlign: TextAlign.center, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator(Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingData.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
          height: AppSizes.p8,
          width: _currentPage == index ? AppSizes.p24 : AppSizes.p8,
          decoration: BoxDecoration(
            color: _currentPage == index ? activeColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(AppSizes.p12),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    final isLastPage = _currentPage == onboardingData.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: isLastPage
          ? ElevatedButton(
              onPressed: _completeOnboarding,
              child: const Text(AppStrings.getStarted),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text(AppStrings.back, style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                  style: theme.elevatedButtonTheme.style?.copyWith(minimumSize: MaterialStateProperty.all(const Size(120, 50))),
                  child: const Text(AppStrings.next, style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }
}