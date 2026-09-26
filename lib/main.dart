import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sih_2026/screens/language_selection_screen.dart';
import 'package:sih_2026/screens/splash_screen.dart';
import 'flashcard_image_test.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: AdiVaaniApp()));
}

class AdiVaaniApp extends StatelessWidget {
  const AdiVaaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoolBhasha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
