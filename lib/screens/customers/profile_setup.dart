import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fyp_2/config/app_config.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'package:fyp_2/constants/supabase.dart';
import 'package:fyp_2/screens/customers/home_page.dart';
import 'package:fyp_2/screens/customers/reminder.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['full_name'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fullName = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final address = _addressController.text.trim();

      await supabase.from('user_profiles').upsert({
        'user_id': user.id, 'email': user.email, 'full_name': fullName,
        'phone_number': phoneNumber, 'address': address, 'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      final bool isOutsideSelangor = !address.toLowerCase().contains('selangor');

      if (isOutsideSelangor) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.errorSavingProfile}$error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(AppConfig.appIconPath, height: 180),
                    gapH30,
                    Text(
                      AppStrings.profileSetupTitle,
                      // --- FIX HERE ---
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    gapH24,
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: AppStrings.hintName),
                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.errorEnterName : null,
                    ),
                    gapH16,
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: AppStrings.hintPhone),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return AppStrings.errorEnterPhone;
                        if (v.trim().length < 10) return AppStrings.errorValidPhone;
                        return null;
                      },
                    ),
                    gapH16,
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(hintText: AppStrings.hintAddress),
                      validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.errorEnterAddress : null,
                    ),
                    gapH32,
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(AppStrings.next),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}