import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purepond_app/screens/login_screen.dart';
import 'package:purepond_app/screens/main_screen.dart';
import 'package:purepond_app/services/auth_service_mock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthServiceMock(),
      child: MaterialApp(
        title: 'PurePond Monitoring',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Consumer<AuthServiceMock>(
          builder: (context, authService, child) {
            if (authService.isLoggedIn) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
