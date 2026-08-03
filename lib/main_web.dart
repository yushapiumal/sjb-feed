import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:statelink/firebase_options.dart';
import 'package:statelink/provider/feed_provider.dart';
import 'package:statelink/screens/feed_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error on web: $e");
  }

  // Parse query parameters from the browser URL (e.g., https://domain.com/?userId=123&userName=Akesh)
  final uri = Uri.base;
  final userId = uri.queryParameters['userId'] ?? 'guest';
  final userName = uri.queryParameters['userName'] ?? 'Guest User';
  final userPhoto = uri.queryParameters['userPhoto'] ?? '';

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PostProvider()..fetchPosts()),
        ],
        child: WebFeedApp(
          userId: userId,
          userName: userName,
          userPhoto: userPhoto,
        ),
      ),
    ),
  );
}

class WebFeedApp extends StatelessWidget {
  final String userId;
  final String userName;
  final String userPhoto;

  const WebFeedApp({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SJB Feed Web',
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: FeedTab(
          userId: userId,
          userName: userName,
          userPhoto: userPhoto,
          scrollController: ScrollController(),
        ),
      ),
    );
  }
}
