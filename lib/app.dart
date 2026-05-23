import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

class LaChapitaApp extends StatelessWidget {
  const LaChapitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Chapita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}