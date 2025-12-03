import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:statelink/api/route.dart';
import 'package:statelink/screens/old_feed/auth_provider.dart';
import 'package:statelink/provider/feed_provider.dart';
import 'package:statelink/screens/splashScreen.dart';
import 'package:statelink/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
  await NotificationService.showNotification(message);
  print("Background notification handled successfully");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully");
    } else {
      print("Firebase already initialized, skipping initialization");
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  try {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print("Background message handler registered");
  } catch (e) {
    print("Error setting up background messaging: $e");
  }

  try {
    await NotificationService.initialize();
    print("NotificationService initialized successfully");
  } catch (e) {
    print("NotificationService initialization error: $e");
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
    print("App check initialized successfully");
  } catch (e) {
    print("NotificationService initialization error: $e");
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message received: ${message.messageId}");
    NotificationService.showNotification(message);
  });

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PostProvider()..fetchPosts()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SJB Mobile App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        routerConfig: appRouter,

       // home: const SplashScreen(),
      ),
    );
  }
}
