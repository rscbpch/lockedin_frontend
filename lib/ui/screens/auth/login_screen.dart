import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/theme/app_colors.dart';
import 'package:lockedin_frontend/ui/widgets/agreement_box.dart';
import 'package:lockedin_frontend/ui/widgets/long_button.dart';

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Image.asset("assets/icon.png", height: 81, width: 81),
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
                  LoginForm(),
                  LongButton(
                    text: 'Login',
                    onPressed: () {
                      // do login or navigate
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
                    onPressed: () {},
                    isOutlined: true,
                    icon: Image.asset(
                      "assets/google.png",
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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty ||
                  !EmailValidator.validate(value)) {
                return "Email is required";
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              hintStyle: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _emailController.clear(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Password is required";
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              hintStyle: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
        ],
      ),
    );
  }
}
