import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> showThankYouNotification(String name, int amount) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'don_channel',
      'Donations',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Merci $name ❤️',
      'Votre don de $amount CFA a bien été reçu !',
      details,
    );
  }
}