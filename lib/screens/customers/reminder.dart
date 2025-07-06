import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'home_page.dart'; // Make sure this path is correct

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFF9D1D1),
            width: 8,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 20),
                SvgPicture.asset(
                  'lib/asset/app_icon.svg', // Make sure this path is correct
                  height: 180,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Remainder',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "It looks like you're outside our delivery zone. To keep our curtains in top shape, we only offer in-store pickup. \n\nAre you still interested in placing an order?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const Spacer(), // Pushes the button to the bottom
                ElevatedButton(
                  onPressed: () {
                    // User acknowledges and proceeds to the app's home page
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC86462),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}