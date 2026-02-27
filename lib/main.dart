import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/screens/auth/forget_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/getting_started_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/input_otp.dart';
import 'package:lockedin_frontend/ui/screens/auth/login_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/reset_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/sign_up_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/ai_breakdown_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/productivity_hub_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/todo_list/todo_list_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/pomodoro/pomodoro_screen.dart';
import 'package:lockedin_frontend/ui/screens/profile/user_own_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Restore persisted session before showing any UI.
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: authProvider)],
      child: MyApp(authProvider: authProvider),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthProvider authProvider;
  const MyApp({super.key, required this.authProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  // Auth-only paths that logged-in users should skip.
  static const _authPaths = {'/', '/login', '/register', '/forget-password'};

  // Protected paths that require a valid token.
  static const _protectedPaths = {
    '/productivity-hub',
    '/todo-list',
    '/pomodoro',
    '/task-breakdown',
    '/profile',
  };

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: widget.authProvider,
      redirect: (context, state) {
        final isAuth = widget.authProvider.isAuthenticated;
        final path = state.matchedLocation;

        // Logged-in user trying to view an auth screen → send to main app.
        if (isAuth && _authPaths.contains(path)) {
          return '/productivity-hub';
        }

        // Guest trying to view a protected screen → send to landing.
        if (!isAuth && _protectedPaths.contains(path)) {
          return '/';
        }

        return null; // no redirect needed
      },
      routes: [
        // auth
        GoRoute(
          path: '/',
          builder: (context, state) => const GettingStartedScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
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
        GoRoute(
          path: '/pomodoro',
          builder: (context, state) => const PomodoroScreen(),
        ),
        GoRoute(
          path: '/task-breakdown',
          builder: (context, state) => const AiBreakdownScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const UserOwnProfileScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
