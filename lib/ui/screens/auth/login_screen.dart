import 'package:flutter/material.dart';
import 'package:lockedin_frontend/theme/app_colors.dart';
import 'package:lockedin_frontend/ui/screens/auth/sign_up_screen.dart';
import '../../widgets/long_button.dart';
import '../../widgets/login_form.dart';

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
                  LongButton(text: 'Login', onPressed: () {
                    // do login or navigate
                  }),
                  SizedBox(height: 16,),
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
                  SizedBox(height: 16,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Nunito'
                      )),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                        },
                        child: Text(" Sign up",style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Nunito'
                        ),),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
