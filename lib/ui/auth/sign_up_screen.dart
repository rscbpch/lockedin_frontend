import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../widgets/long_button.dart';
import '../widgets/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset("assets/icon.png", height: 81, width: 81),
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
                  const SizedBox(height: 16,),
                  SignUpForm(),
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
                  Align(
                    alignment: Alignment.center,
                    child: LongButton(
                      text: "Continue with Google",
                      onPressed: () {},
                      isOutlined: true,
                      icon: Image.asset(
                        "assets/google.png",
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: 16,),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
