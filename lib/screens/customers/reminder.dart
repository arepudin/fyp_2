import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fyp_2/config/app_config.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'home_page.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.2),
            width: AppSizes.p8,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                gapH20,
                SvgPicture.asset(AppConfig.appIconPath, height: 180),
                gapH40,
                Text(
                  AppStrings.reminderTitle,
                  style: textTheme.displayMedium?.copyWith(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                gapH30,
                Text(
                  AppStrings.reminderMessage,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                  child: const Text(AppStrings.next),
                ),
                gapH20,
              ],
            ),
          ),
        ),
      ),
    );
  }
}