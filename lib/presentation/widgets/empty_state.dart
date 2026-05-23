import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.vanilla.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon,
                  color: AppColors.vanilla.withOpacity(0.5), size: 32),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTypography.headlineSmall.copyWith(color: AppColors.white),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: AppTypography.bodyMediumOnDark,
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 28),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}