import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/screens/auth/forget_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/getting_started_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/input_otp.dart';
import 'package:lockedin_frontend/ui/screens/auth/login_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/reset_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/sign_up_screen.dart';
import 'package:lockedin_frontend/ui/widgets/display/main_shell.dart';
import 'package:lockedin_frontend/ui/widgets/display/placeholder_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/manage_flashcard_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/flashcard_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/flashcard_view_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/ai_breakdown_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/productivity_hub_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/todo_list/todo_list_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/pomodoro/pomodoro_screen.dart';
import 'package:lockedin_frontend/ui/screens/profile/user_own_profile_screen.dart';
import 'package:lockedin_frontend/ui/widgets/display/no_transition_builder.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/provider/flashcard_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

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

  static const _authPaths = {'/', '/login', '/register', '/forget-password'};

  static const _protectedPaths = {'/home', '/social', '/productivity-hub', '/books', '/profile', '/todo-list', '/pomodoro', '/flashcard', '/task-breakdown'};

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: widget.authProvider,
      redirect: (context, state) {
        final isAuth = widget.authProvider.isAuthenticated;
        final path = state.matchedLocation;

        if (isAuth && _authPaths.contains(path)) {
          return '/productivity-hub';
        }
        if (!isAuth && _protectedPaths.contains(path)) {
          return '/';
        }
        return null;
      },

      routes: [
        // ── Auth routes ──────────────────────────────
        GoRoute(
          path: '/',
          pageBuilder: (_, s) => const NoTransitionPage(child: GettingStartedScreen()),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (_, s) => const NoTransitionPage(child: LoginScreen()),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (_, s) => const NoTransitionPage(child: SignUpScreen()),
        ),
        GoRoute(
          path: '/forget-password',
          pageBuilder: (_, s) => const NoTransitionPage(child: ForgetPasswordScreen()),
        ),
        GoRoute(
          path: '/OTP/:email',
          pageBuilder: (_, s) {
            final email = s.pathParameters['email'] ?? '';
            return NoTransitionPage(child: OTPScreen(email: email));
          },
        ),
        GoRoute(
          path: '/reset-password/:email/:otp',
          pageBuilder: (_, s) {
            final email = s.pathParameters['email'] ?? '';
            final otp = s.pathParameters['otp'] ?? '';
            return NoTransitionPage(
              child: ResetPasswordScreen(email: email, otp: otp),
            );
          },
        ),

        // ── Main tabs with navbar ──────────────────────
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(state: state, child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, s) => const NoTransitionPage(
                child: PlaceholderScreen(title: 'Home', icon: FeatherIcons.home),
              ),
            ),
            GoRoute(
              path: '/social',
              pageBuilder: (_, s) => const NoTransitionPage(
                child: PlaceholderScreen(title: 'Social', icon: FeatherIcons.users),
              ),
            ),
            GoRoute(
              path: '/productivity-hub',
              pageBuilder: (_, s) => const NoTransitionPage(child: ProductivityHubScreen()),
            ),
            GoRoute(
              path: '/books',
              pageBuilder: (_, s) => const NoTransitionPage(
                child: PlaceholderScreen(title: 'Books', icon: FeatherIcons.bookOpen),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (_, s) => const NoTransitionPage(child: UserOwnProfileScreen()),
            ),
          ],
        ),

        // ── Productivity tools routes ──────────────────────────────
        GoRoute(
          path: '/todo-list',
          pageBuilder: (_, s) => const NoTransitionPage(child: TodoListScreen()),
        ),
        GoRoute(
          path: '/pomodoro',
          pageBuilder: (_, s) => const NoTransitionPage(child: PomodoroScreen()),
        ),
        ShellRoute(
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              child: ChangeNotifierProvider(
                create: (_) => FlashcardProvider(),
                child: child,
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/flashcard',
              pageBuilder: (_, s) =>
                  const NoTransitionPage(child: FlashcardScreen()),
            ),
            GoRoute(
              path: '/flashcard/create',
              pageBuilder: (_, s) =>
                  const NoTransitionPage(child: ManageFlashcardScreen()),
            ),
            GoRoute(
              path: '/flashcard/edit/:id',
              pageBuilder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return NoTransitionPage(
                  child: ManageFlashcardScreen(editSetId: id),
                );
              },
            ),
            GoRoute(
              path: '/flashcard/:id',
              pageBuilder: (_, s) {
                final id = s.pathParameters['id'] ?? '';
                return NoTransitionPage(
                  child: FlashcardViewScreen(setId: id),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/task-breakdown',
          pageBuilder: (_, s) => const NoTransitionPage(child: AiBreakdownScreen()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
            TargetPlatform.macOS: NoTransitionsBuilder(),
            TargetPlatform.windows: NoTransitionsBuilder(),
            TargetPlatform.linux: NoTransitionsBuilder(),
          },
        ),
      ),
    );
  }
}
