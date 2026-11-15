
import 'package:flutter/material.dart';

import 'onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduExam',
      theme: ThemeData(
        primaryColor: const Color(0xFF1565E8),
        scaffoldBackgroundColor: const Color(0xFFF3F7FC),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
