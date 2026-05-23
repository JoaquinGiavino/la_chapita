import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) =>
                FadeTransition(opacity: animation, child: const DashboardScreen()),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _FallbackLogo(),
            ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 800.ms,
              curve: Curves.easeOut,
            ),
            const SizedBox(height: 28),
            Text('La Chapita', style: AppTypography.displayMedium)
                .animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'Gestión de ventas y deudores',
              style: AppTypography.bodyMediumOnDark.copyWith(
                color: AppColors.vanilla.withOpacity(0.55),
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.vanilla.withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.vanilla.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text('LC', style: AppTypography.displayMedium.copyWith(fontSize: 36)),
      ),
    );
  }
}