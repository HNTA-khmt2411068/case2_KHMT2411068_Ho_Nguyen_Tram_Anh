import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/constants.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const taroPrimary = Color(0xFF8367D8);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: taroPrimary,
          primary: taroPrimary,
          surface: const Color(0xFFF5F0FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F0FF),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}