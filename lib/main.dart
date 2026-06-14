import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:purepond_app/screens/login_screen.dart';
import 'package:purepond_app/screens/main_screen.dart';
import 'package:purepond_app/services/auth_service.dart';
import 'package:purepond_app/services/event_service.dart';
import 'package:purepond_app/services/firestore_service.dart' as fs;
import 'package:purepond_app/services/notification_service.dart';
import 'package:purepond_app/services/realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Untuk Android pakai google-services.json
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final notificationService = NotificationService();

    runApp(MyApp(notificationService: notificationService));

    // Jangan ditunggu sebelum runApp, supaya tidak blank hitam.
    Future.microtask(() async {
      try {
        await notificationService.initialize();
      } catch (e) {
        debugPrint('Notification init error: $e');
      }
    });
  } catch (e) {
    runApp(FirebaseErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => fs.FirestoreService()),
        Provider(create: (_) => RealtimeService()),
        Provider<NotificationService>.value(value: notificationService),
        ProxyProvider2<RealtimeService, NotificationService, EventService>(
          update: (_, realtimeService, notificationService, previous) {
            return previous ??
                EventService(
                  realtimeService: realtimeService,
                  notificationService: notificationService,
                );
          },
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'PurePond Monitoring',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, child) {
            if (authService.user != null) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;

  const FirebaseErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Firebase gagal dimuat:\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
