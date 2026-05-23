import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum AlertSeverity { warning, critical }

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    required this.severity,
    this.onTap,
  });

  final String message;
  final AlertSeverity severity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = severity == AlertSeverity.critical
        ? AppColors.error
        : AppColors.warning;

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 300)),
        SlideEffect(begin: Offset(0, -0.1), end: Offset.zero),
      ],
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                severity == AlertSeverity.critical
                    ? Icons.warning_rounded
                    : Icons.schedule_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: AppTypography.bodySmall.copyWith(color: color)),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}