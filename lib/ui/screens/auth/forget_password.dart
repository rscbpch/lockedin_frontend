import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

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
                      'assets/images/forgetPass.png',
                      width: 259,
                      height: 259,
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: const Text(
                        "Forget password",
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Don’t worry! it happens. Please enter the email that associate with your account",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 26),
                    ForgetPasswordForm(
                      onSubmit: (email) {
                        // Handle forget password - send OTP
                        context.push('/OTP/${Uri.encodeComponent(email)}');
                      },
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

class ForgetPasswordForm extends StatefulWidget {
  final void Function(String email)? onSubmit;
  const ForgetPasswordForm({super.key, this.onSubmit});

  @override
  State<ForgetPasswordForm> createState() => _ForgetPasswordFormState();
}

class _ForgetPasswordFormState extends State<ForgetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool get isFormValid {
    return _emailController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty ||
                  !EmailValidator.validate(value)) {
                return "Please enter a valid email address";
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          LongButton(
            text: 'Get OTP',
            onPressed: isFormValid
                ? () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit?.call(_emailController.text.trim());
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
