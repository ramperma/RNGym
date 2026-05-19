import 'package:flutter/material.dart';
import 'package:gym_trainer_app/core/theme/app_colors.dart';

class GymCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final double borderRadius;

  const GymCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.gradientColors,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradientColors == null ? AppColors.surface : null,
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.05),
          width: 1,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    Widget result = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: gradientColors == null ? AppColors.surface : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: content,
          ),
        ),
      ),
    );

    return result;
  }
}
