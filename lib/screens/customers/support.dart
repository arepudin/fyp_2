import 'package:flutter/material.dart';
import 'package:fyp_2/config/app_config.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/config/app_sizes.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.helpAndSupport),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(AppStrings.contactUs, textTheme),
            
            Card(
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: AppStrings.phoneSupport,
                      value: AppConfig.supportPhone,
                      theme: theme,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: AppStrings.emailSupport,
                      value: AppConfig.supportEmail,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
            
            gapH30,
            
            _buildSectionHeader(AppStrings.faqs, textTheme),
            _buildFaqTile(AppStrings.faq1Question, AppStrings.faq1Answer),
            _buildFaqTile(AppStrings.faq2Question, AppStrings.faq2Answer),
            _buildFaqTile(AppStrings.faq3Question, AppStrings.faq3Answer),
            _buildFaqTile(AppStrings.faq4Question, AppStrings.faq4Answer),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12, top: AppSizes.p8),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          gapW16,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FIX HERE ---
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              gapH4,
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.all(AppSizes.p16).copyWith(top: 0),
        children: [
          Text(answer, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
        ],
      ),
    );
  }
}