import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum StatCardVariant { normal, warning, critical }

class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.animationDelay = Duration.zero,
    this.variant = StatCardVariant.normal,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final Duration animationDelay;
  final StatCardVariant variant;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (widget.variant) {
      StatCardVariant.normal => AppColors.vanilla,
      StatCardVariant.warning => AppColors.warning,
      StatCardVariant.critical => AppColors.error,
    };

    return Animate(
      delay: widget.animationDelay,
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 400)),
        SlideEffect(
          begin: Offset(0, 0.15),
          end: Offset.zero,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
      ],
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(0.0, _hovered ? -4.0 : 0.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? AppColors.white.withOpacity(0.12)
                        : AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hovered
                          ? AppColors.vanilla.withOpacity(0.3)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.value,
                          style: AppTypography.amountLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(widget.title,
                          style: AppTypography.bodySmallOnDark
                              .copyWith(fontSize: 12, letterSpacing: 0.3)),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(widget.subtitle!,
                            style: AppTypography.bodySmall
                                .copyWith(fontSize: 11, color: iconColor)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}