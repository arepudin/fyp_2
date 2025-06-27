// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_in.dart';

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
    'image': 'lib/asset/placeholder1.png',
    'title': 'measure windows',
    'description': 'Step 1: Measure your windows accurately for a perfect fit.'
  },
  {
    'image': 'lib/asset/placeholder2.png',
    'title': 'search suitable curtains',
    'description': 'Step 2: Explore and choose the best curtains for your style.'
  },
  {
    'image': 'lib/asset/SABA CURTAIN LOGO.jpg',
    'title': 'send yourt order',
    'description': 'Step 3: Place your order.'
  },
];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
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
          _buildScrollIndicator(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300, width: 400),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          onboardingData.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            height: 8.0,
            width: _currentPage == index ? 20.0 : 8.0,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? const Color.fromRGBO(36, 95, 117, 1)
                  : Colors.grey,
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text("Back", style: TextStyle(fontSize: 16, color: Color.fromRGBO(36, 95, 117, 1))),
            )
          else
            const SizedBox.shrink(),
          if (_currentPage < onboardingData.length - 1)
            TextButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text("Next", style: TextStyle(fontSize: 16, color: Color.fromRGBO(36, 95, 117, 1))),
            )
          else
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text("Done", style: TextStyle(fontSize: 16, color: Color.fromRGBO(229, 64, 19, 1), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}