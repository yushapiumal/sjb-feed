import 'package:go_router/go_router.dart';
import 'package:statelink/screens/feed_new.dart';
import 'package:statelink/screens/login_id.dart';
import 'package:statelink/screens/logn_fb&google.dart';
import 'package:statelink/screens/registration.dart';
import 'package:statelink/screens/splashScreen.dart';


final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen()
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ), GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationForm(),
    ), GoRoute(
      path: '/social_login',
      builder: (context, state) => const SocialLoginPage(message: '',),
    ), GoRoute(
  path: '/home',
  builder: (context, state) {
    final userData = state.extra as Map<String, dynamic>? ?? {};
    return FeedScreen(userData: userData);
  },
),

  ],
);
