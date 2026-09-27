import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final TextStyle? messageStyle;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 32.0,
    this.messageStyle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.secondary6,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style:
                    messageStyle ??
                    AppTypography.subtitle.copyWith(color: AppColors.neutral8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
