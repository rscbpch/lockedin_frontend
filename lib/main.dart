import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lockedin_frontend/firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/provider/follow_provider.dart';
import 'package:lockedin_frontend/services/follow_service.dart';
import 'package:lockedin_frontend/services/notification_service.dart';
import 'package:lockedin_frontend/ui/screens/auth/forget_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/getting_started_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/input_otp.dart';
import 'package:lockedin_frontend/ui/screens/auth/login_screen.dart';
import 'package:lockedin_frontend/ui/screens/auth/reset_password.dart';
import 'package:lockedin_frontend/ui/screens/auth/sign_up_screen.dart';
import 'package:lockedin_frontend/ui/widgets/display/main_shell.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/manage_flashcard_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/flashcard_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/flashcard_view_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/flashcard_test_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/flashcard_test_result_screen.dart';
import 'package:lockedin_frontend/services/flashcard_service.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/ai_breakdown_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/productivity_hub_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/todo_list/todo_list_screen.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/pomodoro/pomodoro_screen.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/book_summary_screen.dart';
import 'package:lockedin_frontend/ui/screens/profile/user_own_profile_screen.dart';
import 'package:lockedin_frontend/ui/widgets/display/no_transition_builder.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/provider/chat_provider.dart';
import 'package:lockedin_frontend/provider/streak_provider.dart';
import 'package:lockedin_frontend/provider/group_chat_provider.dart';
import 'package:lockedin_frontend/provider/pomodoro_timer_provider.dart';
import 'package:lockedin_frontend/ui/widgets/notifications/app_alert_dialog.dart';
import 'package:lockedin_frontend/services/chat_service.dart';
import 'package:lockedin_frontend/services/group_chat_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/screens/chat/chat_list_screen.dart';
import 'ui/screens/chat/widgets/stream_chat_theme.dart';
import 'provider/study_room_provider.dart';
import 'services/study_room_api_service.dart';
import 'ui/screens/study_room/lobby_screen.dart';

final StreamChatClient streamClient = StreamChatClient(dotenv.env['STREAM_API_KEY'] ?? '', logLevel: Level.OFF);

final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();

  final notificationSettings =
      await FirebaseMessaging.instance.requestPermission();
  debugPrint(
    '🔔 Notification permission: ${notificationSettings.authorizationStatus}',
  );

  await _logFcmTokenWithRetry();

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('🔄 FCM Token refreshed: $newToken');
  }, onError: (error) {
    debugPrint('❌ FCM token refresh error: $error');
  });

  await dotenv.load(fileName: '.env');

  final authProvider = AuthProvider();
  await authProvider.initialize();
  if (authProvider.isAuthenticated) {
  await NotificationService.saveTokenToBackend(() async => authProvider.token);
}

  final streakProvider = StreakProvider();
  await streakProvider.restoreSession();
  
  final bookProvider = BookProvider();

  if (authProvider.isAuthenticated) {
    bookProvider.loadBooks();
    bookProvider.loadCategories();
    bookProvider.loadFavorites();
  }

  final chatProvider = ChatProvider(
    streamClient: streamClient,
    chatService: ChatService(getAuthToken: () async => authProvider.token),
  );
  final groupChatProvider = GroupChatProvider(
    streamClient: streamClient,
    service: GroupChatService(getAuthToken: () async => authProvider.token),
  );
  final pomodoroProvider = PomodoroTimerProvider();
  pomodoroProvider.setStreakProvider(streakProvider);
  final studyRoomProvider = StudyRoomProvider(
    StudyRoomApiService(
      getToken: () => authProvider.token,
      jaasAppId: dotenv.env['JAAS_APP_ID'] ?? '',
    ),
  );
  final FollowProvider followProvider = FollowProvider(
    service: FollowService(getAuthToken: () async => authProvider.token),
  );

  AuthProvider.onSessionCleanup = () async {
    await chatProvider.disconnectUser();
    groupChatProvider.reset();
    streakProvider.reset();
    bookProvider.clear();
    await NotificationService.removeTokenFromBackend(() async => authProvider.token);
  };
  AuthProvider.onForceLogout = () async => authProvider.logout();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: bookProvider),
        ChangeNotifierProvider.value(value: streakProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider.value(value: groupChatProvider),
        ChangeNotifierProvider.value(value: pomodoroProvider),
        ChangeNotifierProvider.value(value: studyRoomProvider),
        ChangeNotifierProvider.value(value: followProvider),
      ],
      child: MyApp(authProvider: authProvider),
    ),
  );
}

Future<void> _logFcmTokenWithRetry() async {
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      final token =
          await FirebaseMessaging.instance.getToken().timeout(
                const Duration(seconds: 12),
              );

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ FCM token is null/empty on attempt $attempt');
      } else {
        debugPrint('📱 FCM Token: $token');
        return;
      }
    } on TimeoutException {
      debugPrint('⏱️ Timed out getting FCM token on attempt $attempt');
    } catch (error) {
      debugPrint('❌ Error getting FCM token on attempt $attempt: $error');
    }

    await Future.delayed(const Duration(seconds: 2));
  }
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

  static const _protectedPaths = {'/study-room', '/productivity-hub', '/books', '/profile', '/todo-list', '/pomodoro', '/flashcard', '/task-breakdown', '/chat'};

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      navigatorKey: appRootNavigatorKey,
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
              path: '/study-room',
              pageBuilder: (_, s) => const NoTransitionPage(child: LobbyScreen()),
            ),
            GoRoute(
              path: '/productivity-hub',
              pageBuilder: (_, s) => const NoTransitionPage(child: ProductivityHubScreen()),
            ),
            GoRoute(
              path: '/books',
              pageBuilder: (_, s) => const NoTransitionPage(child: BookSummaryScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (_, s) => const NoTransitionPage(child: UserOwnProfileScreen()),
            ),
          ],
        ),

        // ── Chat route ──────────────────────────────
        GoRoute(
          path: '/chat',
          pageBuilder: (_, s) => const NoTransitionPage(child: ChannelListScreen()),
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
        GoRoute(
          path: '/flashcard',
          pageBuilder: (_, s) => const NoTransitionPage(child: FlashcardScreen()),
        ),
        GoRoute(
          path: '/flashcard/create',
          pageBuilder: (_, s) => const NoTransitionPage(child: ManageFlashcardScreen()),
        ),
        GoRoute(
          path: '/flashcard/edit/:id',
          pageBuilder: (_, s) {
            final id = s.pathParameters['id'] ?? '';
            return NoTransitionPage(child: ManageFlashcardScreen(editSetId: id));
          },
        ),
        GoRoute(
          path: '/flashcard/:id',
          pageBuilder: (_, s) {
            final id = s.pathParameters['id'] ?? '';
            return NoTransitionPage(child: FlashcardViewScreen(setId: id));
          },
        ),
        GoRoute(
          path: '/flashcard/:id/test',
          pageBuilder: (_, s) {
            final id = s.pathParameters['id'] ?? '';
            return NoTransitionPage(child: FlashcardTestScreen(setId: id));
          },
        ),
        GoRoute(
          path: '/flashcard/:id/test/result',
          pageBuilder: (_, s) {
            final id = s.pathParameters['id'] ?? '';
            final extra = s.extra as Map<String, dynamic>? ?? {};
            return NoTransitionPage(
              child: FlashcardTestResultScreen(
                setId: id,
                correctCount: extra['correctCount'] as int? ?? 0,
                wrongCount: extra['wrongCount'] as int? ?? 0,
                totalCards: extra['totalCards'] as int? ?? 0,
                cards: extra['cards'] as List<FlashcardCard>? ?? [],
                results: extra['results'] as List<bool>? ?? [],
              ),
            );
          },
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

      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('en')],

      builder: (context, child) {
        return StreamChat(
          client: streamClient,
          streamChatThemeData: StreamChatAppTheme.theme,
          child: _StreakCompletionHost(child: _PomodoroPromptHost(child: child!)),
        );
      },
    );
  }
}

class _StreakCompletionHost extends StatefulWidget {
  const _StreakCompletionHost({required this.child});
  final Widget child;

  @override
  State<_StreakCompletionHost> createState() => _StreakCompletionHostState();
}

class _StreakCompletionHostState extends State<_StreakCompletionHost> {
  bool _isDialogOpen = false;
  StreakProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<StreakProvider>();
    if (identical(_provider, nextProvider)) return;
    _provider?.removeListener(_onProviderChanged);
    _provider = nextProvider;
    _provider!.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    final provider = _provider;
    if (provider == null || _isDialogOpen) return;
    if (!provider.hasPendingGoalCompletion) return;
    _showCompletionDialog(provider);
  }

  void _showCompletionDialog(StreakProvider provider) {
    final rootContext = appRootNavigatorKey.currentContext;
    if (rootContext == null) return;

    _isDialogOpen = true;
    provider.acknowledgeGoalCompletion();

    showDialog<void>(
      context: rootContext,
      useRootNavigator: true,
      builder: (_) =>
          const AppAlertDialog(title: '🔥 Streak Goal Completed!', message: "Great job! You've hit your daily study goal. Keep the streak alive!", confirmLabel: 'Okay'),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isDialogOpen = false);
      } else {
        _isDialogOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }
}

class _PomodoroPromptHost extends StatefulWidget {
  const _PomodoroPromptHost({required this.child});

  final Widget child;

  @override
  State<_PomodoroPromptHost> createState() => _PomodoroPromptHostState();
}

class _PomodoroPromptHostState extends State<_PomodoroPromptHost> {
  int _lastHandledPromptId = 0;
  bool _isDialogOpen = false;
  PomodoroTimerProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<PomodoroTimerProvider>();
    if (identical(_provider, nextProvider)) {
      return;
    }

    _provider?.removeListener(_onProviderChanged);
    _provider = nextProvider;
    _provider!.addListener(_onProviderChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onProviderChanged();
      }
    });
  }

  void _onProviderChanged() {
    final provider = _provider;
    if (provider == null || _isDialogOpen) return;

    final prompt = provider.pendingPrompt;
    if (prompt == null || prompt.id == _lastHandledPromptId) return;

    _showPrompt(context, provider, prompt);
  }

  void _showPrompt(BuildContext context, PomodoroTimerProvider provider, PomodoroCompletionPrompt prompt) {
    final rootContext = appRootNavigatorKey.currentContext;
    if (rootContext == null) {
      _isDialogOpen = false;
      return;
    }

    _isDialogOpen = true;
    _lastHandledPromptId = prompt.id;

    showDialog<bool>(
          context: rootContext,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (ctx) => AppAlertDialog(title: prompt.title, message: prompt.message, cancelLabel: 'Later', confirmLabel: 'Continue'),
        )
        .then((result) {
          if (result == true) {
            provider.acceptPendingPromptAndStart();
            GoRouter.of(context).go('/pomodoro');
          } else {
            provider.dismissPendingPrompt();
          }
        })
        .whenComplete(() {
          if (mounted) {
            setState(() {
              _isDialogOpen = false;
            });
          } else {
            _isDialogOpen = false;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }
}
