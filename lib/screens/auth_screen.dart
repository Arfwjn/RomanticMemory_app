import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());
    
    return Obx(() {
      if (authController.isAuthenticated) {
        return const DashboardScreen();
      }
      return const _AuthContent();
    });
  }
}

class _AuthContent extends StatefulWidget {
  const _AuthContent({Key? key}) : super(key: key);

  @override
  State<_AuthContent> createState() => _AuthContentState();
}

class _AuthContentState extends State<_AuthContent> {
  bool isSignUp = false;
  final formKey = GlobalKey<FormState>();
  
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController displayNameController;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    if (!formKey.currentState!.validate()) return;

    final success = isSignUp
        ? await authController.signUp(
            emailController.text,
            passwordController.text,
            displayNameController.text,
          )
        : await authController.signIn(
            emailController.text,
            passwordController.text,
          );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.errorMessage.value ?? 'Auth failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Text(
                      'Memories',
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'favorite',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Display Name (Sign Up only)
                    if (isSignUp)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: CustomTextField(
                          label: 'Display Name',
                          hint: 'Enter your name',
                          controller: displayNameController,
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                      ),

                    // Email
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: CustomTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                    ),

                    // Password
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: passwordController,
                        isPassword: true,
                        validator: Validators.validatePassword,
                      ),
                    ),

                    // Auth Button
                    Obx(() => CustomButton(
                      label: isSignUp ? 'Sign Up' : 'Sign In',
                      onPressed: _handleAuth,
                      isLoading: authController.isLoading.value,
                    )),

                    const SizedBox(height: AppSpacing.lg),

                    // Toggle Sign In/Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSignUp
                              ? 'Already have an account? '
                              : 'Don\'t have an account? ',
                          style: const TextStyle(color: AppColors.mediumText),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => isSignUp = !isSignUp);
                            formKey.currentState?.reset();
                          },
                          child: Text(
                            isSignUp ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}
