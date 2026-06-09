import 'package:go_router/go_router.dart';
import 'package:statelink/screens/feed_new.dart';
import 'package:statelink/screens/login_id.dart';
import 'package:statelink/screens/logn_fb&google.dart';
import 'package:statelink/screens/registration.dart';
import 'package:statelink/screens/splashScreen.dart';
import 'package:statelink/api/auth_services.dart'; // 👈 add this

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final loggedIn = await AuthService.isLoggedIn();
    final path = state.matchedLocation;

    // If logged in and trying to visit login or splash, skip to home
    if (loggedIn && (path == '/' || path == '/login')) {
      return '/home';
    }

    // If not logged in and trying to visit a protected page, send to login
    if (!loggedIn && (path == '/home' || path == '/social_login')) {
      return '/login';
    }

    return null; // no redirect needed
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationForm(),
    ),
    GoRoute(
      path: '/social_login',
      builder: (context, state) {
        final message = state.extra as String? ?? '';
        return SocialLoginPage(message: message);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final userData = state.extra as Map<String, dynamic>? ?? {};
        return FeedScreen(userData: userData);
      },
    ),
  ],
);