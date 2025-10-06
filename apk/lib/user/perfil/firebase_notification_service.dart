import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initFirebaseMessaging() async {
    // Request permission (iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Permission status: ${settings.authorizationStatus}');

    // Get the FCM token (for testing or saving in Supabase)
    final token = await _messaging.getToken();
    print('🔥 FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Received message: ${message.notification?.title}');

      if (message.notification != null) {
        NotificationService().showNotification(
          0,
          message.notification!.title ?? "Notificação",
          message.notification!.body ?? "Sem conteúdo",
        );
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

// Must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Handling background message: ${message.messageId}');
}
