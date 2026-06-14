import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'purepond_alert_channel',
    'PurePond Alerts',
    description: 'Notifikasi kualitas air dan pengurasan otomatis',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    try {
      await _requestPermission();
      await _initializeLocalNotification();
      await _saveFcmToken();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundFirebaseNotification(message);
      });

      _messaging.onTokenRefresh.listen((token) async {
        await _saveTokenToFirestore(token);
      });
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Request notification permission error: $e');
    }
  }

  Future<void> _initializeLocalNotification() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidInit,
      );

      await _localNotifications.initialize(initSettings);

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Local notification init error: $e');
    }
  }

  Future<void> _saveFcmToken() async {
    try {
      final token = await _messaging.getToken();

      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Get FCM token error: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('fcmTokens').doc(token).set({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'unknown',
        'userId': user?.uid,
        'email': user?.email,
        'enabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save FCM token error: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'purepond_alert_channel',
        'PurePond Alerts',
        channelDescription: 'Notifikasi kualitas air dan pengurasan otomatis',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Show local notification error: $e');
    }
  }

  Future<void> _showForegroundFirebaseNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;

    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'PurePond';

    final body = notification?.body ??
        message.data['body']?.toString() ??
        'Ada pembaruan kualitas air.';

    await showLocalNotification(
      title: title,
      body: body,
      payload: message.data.toString(),
    );
  }
}
