import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/screens/auth/forget_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/getting_started_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/input_otp.dart';
import 'package:lockedin_frontend/ui/screens/auth/login_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/reset_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/sign_up_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/productivity_hub_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/todo_list/todo_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // auth
    GoRoute(
      path: '/',
      builder: (context, state) => const GettingStartedScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/forget-password',
      builder: (context, state) => const ForgetPasswordScreen(),
    ),
    GoRoute(
      path: '/OTP/:email',
      builder: (context, state) {
        final email = state.pathParameters['email'] ?? '';
        return OTPScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password/:email/:otp',
      builder: (context, state) {
        final email = state.pathParameters['email'] ?? '';
        final otp = state.pathParameters['otp'] ?? '';
        return ResetPasswordScreen(email: email, otp: otp);
      },
    ),

    // main tabs
    GoRoute(
      path: '/productivity-hub',
      builder: (context, state) => const ProductivityHubScreen(),
    ),

    // productivity tools
    GoRoute(
      path: '/todo-list',
      builder: (context, state) => const TodoListScreen(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
