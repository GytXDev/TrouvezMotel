import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'main_navigation.dart';
import 'screens/home_screen.dart';
import 'screens/motels/motel_detail_screen.dart';
import 'screens/motels/add_motel_screen.dart';
import 'screens/add_review_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings/access_expired_screen.dart';
import 'screens/settings/complete_profile_screen.dart';
import 'screens/support_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/settings/contact_screen.dart';
import 'screens/restaurants/add_restaurant_screen.dart';
import 'screens/restaurants/restaurant_detail_screen.dart';
import 'screens/appartements/add_appartement_screen.dart';
import 'screens/appartements/appartement_detail_screen.dart';

// 🔔 Notifications plugin global
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase initialization
  try {
    await Firebase.initializeApp(
      name: 'trouvezmotel',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('🔥 Firebase déjà initialisé ou autre erreur : $e');
  }

  // ✅ Notification initialization
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final settings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(settings);

  runApp(const TrouvezMotelApp());
}

class TrouvezMotelApp extends StatelessWidget {
  const TrouvezMotelApp({super.key});

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
        '/about': (context) => AboutScreen(),
        '/contact': (context) => ContactScreen(),
        '/addRestaurant': (context) => AddRestaurantScreen(),
        '/restaurantDetail': (context) => RestaurantDetailScreen(),
        '/addAppartement': (context) => AddAppartementScreen(),
        '/appartementDetail': (context) => AppartementDetailScreen(),
      },
    );
  }
}
