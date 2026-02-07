import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/agreement_box.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';
// import 'package:lockedin_frontend/utils/validator.dart';
import '../../../provider/auth_provider.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/images/icon.png", height: 81, width: 81),
                        const SizedBox(width: 15),
                        const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      "Please sign up to create your account",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SignUpForm(
                      onSubmit: (email, username, password, confirmPassword) async {
                        final authProvider = context.read<AuthProvider>();

                        final success = await authProvider.register(
                          email: email,
                          username: username,
                          password: password,
                          confirmPassword: confirmPassword,
                        );

                        if (!context.mounted) return;

                        if (success) {
                          context.push('/productivity-hub');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authProvider.errorMessage ?? 'Something went wrong'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppColors.textPrimary,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.textPrimary,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(fontSize: 12, fontFamily: 'Nunito'),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/login');
                          },
                          child: Text(
                            " Login",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: LongButton(
                        text: "Continue with Google",
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          final success = await authProvider.signInWithGoogle();
                          
                          if (success) {
                            context.push('/productivity-hub');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProvider.errorMessage ?? 'Google sign-in failed'),
                              ),
                            );
                          }
                        },
                        isOutlined: true,
                        icon: Image.asset(
                          "assets/images/google.png",
                          height: 24,
                          width: 24,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
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

class SignUpForm extends StatefulWidget {
  final void Function(String email, String username, String password, String confirmPassword)? onSubmit;

  const SignUpForm({super.key, this.onSubmit});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  
  bool agree = false;
  
  @override
  void initState() {
    super.initState();
    // Update form state when any controller changes so `isFormValid` is recalculated
    emailController.addListener(_onFieldChanged);
    usernameController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
    confirmController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  bool get isFormValid {
    return agree &&
        emailController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmController.text.isNotEmpty;
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    emailController.removeListener(_onFieldChanged);
    usernameController.removeListener(_onFieldChanged);
    passwordController.removeListener(_onFieldChanged);
    confirmController.removeListener(_onFieldChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),

          AppTextField(
            label: 'Username',
            hint: 'Enter your username',
            controller: usernameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              if (value.length < 3) {
                return 'At least 3 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),

          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: passwordController,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) {
                return 'At least 8 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),

          AppTextField(
            label: 'Confirm Password',
            hint: 'Enter your password again',
            controller: confirmController,
            isPassword: true,
            validator: (value) {
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),

          AgreementCheckbox(
            value: agree,
            text: 'I agree with the terms and conditions',
            onChanged: (v) => setState(() => agree = v ?? false),
          ),

          const SizedBox(height: 12),
          LongButton(
            text: auth.isLoading ? 'Signing Up...' : 'Sign Up',
            onPressed: (!isFormValid || auth.isLoading)
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit?.call(
                        emailController.text,
                        usernameController.text,
                        passwordController.text,
                        confirmController.text
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
