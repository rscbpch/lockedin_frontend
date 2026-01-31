import 'package:flutter/material.dart';
import 'text_field.dart';
import 'agreement_box.dart';
import 'long_button.dart';
import 'validator.dart';

class SignUpForm extends StatefulWidget {
  final void Function(
    String email,
    String username,
    String password,
  )? onSubmit;

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
                Validators.confirmPassword(
              v,
              passwordController.text,
            ),
          ),

          const SizedBox(height: 10),

          AgreementCheckbox(
            value: agree,
            text: 'I agree with the terms and conditions',
            onChanged: (v) =>
                setState(() => agree = v ?? false),
          ),

          const SizedBox(height: 16),

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
