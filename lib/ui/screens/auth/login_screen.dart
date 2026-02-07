import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/agreement_box.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/icon.png",
                          height: 81,
                          width: 81,
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Please login to your account",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 26),
                    LoginForm(
                      onSubmit: (email, password) async {
                        final auth = context.read<AuthProvider>();
                        final success = await auth.login(
                          email: email,
                          password: password,
                        );

                        if (!context.mounted) return;
                        
                        if (success) {
                          context.push('/productivity-hub');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ?? 'Login failed',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    LongButton(
                      text: "Continue with Google",
                      onPressed: () async {
                        final auth = context.read<AuthProvider>();
                        final success = await auth.signInWithGoogle();
                        
                        if (success) {
                          context.push('/productivity-hub');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(auth.errorMessage ?? 'Google sign-in failed'),
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
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 12, fontFamily: 'Nunito'),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/register');
                          },
                          child: Text(
                            " Sign up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'Nunito',
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

class LoginForm extends StatefulWidget {
  final void Function(String email, String password)? onSubmit;
  const LoginForm({super.key, this.onSubmit});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  bool get isFormValid {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty ||
                  !EmailValidator.validate(value)) {
                return "Email is required";
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            isPassword: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Password is required";
              }
              return null;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AgreementCheckbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  text: 'Remember me',
                ),
              ),
              TextButton(
                onPressed: () {
                  // Handle forget password
                  context.push('/forget-password');
                },
                child: const Text(
                  'Forget Password?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LongButton(
            text: auth.isLoading ? 'Logging in...' : 'Login',
            onPressed: (!isFormValid || auth.isLoading)
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit?.call(
                        _emailController.text,
                        _passwordController.text,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
