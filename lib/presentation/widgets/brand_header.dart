import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.trailing, this.showSubtitle = false});
  final Widget? trailing;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border(
          bottom: BorderSide(color: AppColors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          _Logo(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('La Chapita',
                  style: AppTypography.headlineMediumOnDark.copyWith(fontSize: 20)),
              if (showSubtitle)
                Text('Gestión de deudores',
                    style: AppTypography.bodySmallOnDark),
            ],
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: 44,
      width: 44,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.vanilla,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('LC',
              style: AppTypography.labelLarge.copyWith(
                  color: AppColors.black, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}