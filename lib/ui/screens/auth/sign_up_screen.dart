import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/agreement_box.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';
import 'package:lockedin_frontend/utils/validator.dart';

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
                      onSubmit: (email, username, password) {
                        context.push('/productivity-hub');
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
                        onPressed: () {},
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
  final void Function(String email, String username, String password)? onSubmit;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),

          const SizedBox(height: 10),

          AppTextField(
            label: 'Username',
            hint: 'Enter your username',
            controller: usernameController,
            validator: Validators.username,
          ),

          const SizedBox(height: 10),

          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: passwordController,
            isPassword: true,
            validator: Validators.password,
          ),

          const SizedBox(height: 10),

          AppTextField(
            label: 'Confirm Password',
            hint: 'Enter your password again',
            controller: confirmController,
            isPassword: true,
            validator: (v) =>
                Validators.confirmPassword(v, passwordController.text),
          ),

          const SizedBox(height: 10),

          AgreementCheckbox(
            value: agree,
            text: 'I agree with the terms and conditions',
            onChanged: (v) => setState(() => agree = v ?? false),
          ),

          const SizedBox(height: 12),

          LongButton(
            text: 'Sign Up',
            onPressed: isFormValid
                ? () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit?.call(
                        emailController.text,
                        usernameController.text,
                        passwordController.text,
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
