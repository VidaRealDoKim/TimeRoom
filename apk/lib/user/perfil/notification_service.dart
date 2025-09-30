// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;



/// Serviço responsável por gerenciar notificações locais no aplicativo.
class NotificationService {
  /// Instância singleton do serviço de notificação.
  static final NotificationService _notificationService =
  NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  /// Instância principal do plugin de notificações.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Inicializa as configurações de notificações para Android e iOS.
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Inicializa suporte a fusos horários.
    tz.initializeTimeZones();

    // Inicializa o plugin de notificações.
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Pede permissão de notificação no Android (API 33+).
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Exibe uma notificação imediata.
  Future<void> showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'main_channel_id', // ID do canal
      'Main Channel', // Nome do canal
      channelDescription: 'Canal principal de notificações do aplicativo',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Agenda uma notificação para ser exibida após uma duração.
  Future<void> scheduleNotification(
      int id, String title, String body, Duration duration) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(duration), // Horário agendado
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel_id',
          'Scheduled Channel',
          channelDescription: 'Canal para notificações agendadas',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime, // <- AQUI é o lugar certo
    );
  }
}
