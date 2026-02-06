import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/auth_service.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';
import 'package:lockedin_frontend/utils/validator.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String email;
  final String otp;
  
  const ResetPasswordScreen({
    super.key, 
    required this.email, 
    required this.otp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: IconButton(
                          onPressed: () {
                            context.pop();
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.textPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/images/resetPass.png',
                      width: 259,
                      height: 259,
                    ),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "Reset Password",
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Enter your new password below",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    ResetPasswordForm(
                      email: email,
                      otp: otp,
                      onSubmit: (newPassword) async {
                        final result = await AuthService.resetPasswordWithOTP(
                          email: email,
                          otp: otp,
                          newPassword: newPassword,
                        );
                        
                        if (result['success']) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Password reset successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Navigate to login screen
                            context.go('/login');
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Failed to reset password'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
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

class ResetPasswordForm extends StatefulWidget {
  final String email;
  final String otp;
  final Future<void> Function(String newPassword)? onSubmit;
  
  const ResetPasswordForm({
    super.key, 
    required this.email,
    required this.otp,
    this.onSubmit,
  });

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool get isFormValid {
    return _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        !_isLoading;
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await widget.onSubmit?.call(_passwordController.text.trim());
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'New Password',
            hint: 'Enter your new password',
            controller: _passwordController,
            isPassword: true,
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirm New Password',
            hint: 'Confirm your new password',
            controller: _confirmPasswordController,
            isPassword: true,
            validator: (value) => Validators.confirmPassword(
              value,
              _passwordController.text,
            ),
          ),
          const SizedBox(height: 32),
          LongButton(
            text: _isLoading ? 'Resetting...' : 'Reset Password',
            onPressed: isFormValid ? _handleSubmit : null,
          ),
        ],
      ),
    );
  }
}