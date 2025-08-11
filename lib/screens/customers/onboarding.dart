// lib/screens/customers/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sign_in.dart';
import '../../config/app_config.dart';
import '../../config/theme_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'asset/placeholder1.png',
      'title': 'Measure Your Windows',
      'description': 'Step 1: Get accurate measurements for a perfect, custom fit.'
    },
    {
      'image': 'asset/placeholder2.png',
      'title': 'Find Your Perfect Style',
      'description': 'Step 2: Explore our curated collection and find the best curtains for you.'
    },
    {
      'image': AppConfig.companyLogoPath,
      'title': 'Place Your Order',
      'description': 'Step 3: A few simple clicks to bring beautiful design into your home.'
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // *** THE CRITICAL FIX IS HERE: Use the correct key ***
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text("Skip", style: TextStyle(color: Colors.grey)),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = onboardingData[index];
                  return _buildOnboardingPage(
                    image: item['image']!,
                    title: item['title']!,
                    description: item['description']!,
                  );
                },
              ),
            ),
            // Indicator
            _buildScrollIndicator(ThemeConfig.primaryColor),
            const SizedBox(height: 20),
            // Navigation Buttons
            _buildNavigationButtons(ThemeConfig.primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
          ),
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
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: _currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index ? activeColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(Color primaryRed) {
    final bool isLastPage = _currentPage == onboardingData.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: isLastPage
          ? ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                // Use the theme's default style by not specifying anything extra
              ),
              child: const Text("GET STARTED"),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text("Back", style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }
}