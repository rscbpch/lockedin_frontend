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
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/provider/chat_provider.dart';
import 'package:lockedin_frontend/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/screens/chat/chat_list_screen.dart';


final StreamChatClient streamClient = StreamChatClient(
  dotenv.env['STREAM_API_KEY'] ?? '',
  logLevel: Level.OFF,
);

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
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChannelListScreen(),
    ),
    
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            streamClient: streamClient,
            chatService: ChatService(
              getAuthToken: () async => authProvider.token,
            ),
          ),
        ),
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
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      // REQUIRED for stream_chat_flutter
      localizationsDelegates: const[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],

      builder: (context, child) {
        return StreamChat(
          client: streamClient,
          child: child!,
        );
      },
    );
  }
}