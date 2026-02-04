import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';

class GettingStartedScreen extends StatelessWidget {
  const GettingStartedScreen({super.key});

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
                        "LockedIn",
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
                    "LockedIn is a mobile app designed for learning and productivity purposes to help students learn more effectively.",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 59),
                  LongButton(
                    text: "Login",
                    onPressed: () {
                      context.push('/login');
                    },
                  ),
                  const SizedBox(height: 16),
                  LongButton(
                    text: "Sign up",
                    onPressed: () {
                      context.push('/register');
                    },
                  ),
                  const SizedBox(height: 24),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
