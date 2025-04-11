import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/thank_you_screen.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/motel_detail_screen.dart';
import 'screens/add_motel_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/access_expired_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/add_review_screen.dart';
import 'screens/support_screen.dart';
import 'main_navigation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialisation Firebase avec firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 Initialisation notifications locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(TrouvezMotelApp());
}

class TrouvezMotelApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrouvezMotel',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainNavigation(),
        '/home': (context) => HomeScreen(),
        '/motelDetail': (context) => MotelDetailScreen(),
        '/addMotel': (context) => AddMotelScreen(),
        '/addReview': (context) => AddReviewScreen(),
        '/profile': (context) => ProfileScreen(),
        '/accessExpired': (context) => AccessExpiredScreen(),
        '/completeProfile': (context) => CompleteProfileScreen(),
        '/support': (context) => SupportScreen(),
        '/thankYou': (context) => ThankYouScreen(),
      },
    );
  }
}
