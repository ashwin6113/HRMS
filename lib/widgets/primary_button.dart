import 'package:flutter/material.dart';
import 'package:hrms/common/constants/app_text_style.dart';

import '../common/constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled = isDisabled || isLoading || onPressed == null;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      height: height ?? 44,
      child: ElevatedButton(
        onPressed: isButtonDisabled ? null : onPressed,
        style:
            ElevatedButton.styleFrom(
              splashFactory: InkRipple.splashFactory,
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              disabledBackgroundColor: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.5),
              disabledForegroundColor: textTheme.titleMedium?.color,
              elevation: isButtonDisabled ? 0 : 2,
              shadowColor: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(12)),
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: 0.2);
                }
                return null;
              }),
            ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.backgroundLight)))
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20, color: AppColors.backgroundLight), const SizedBox(width: 8)],
                  Text(text, style: AppTextStyles.buttonMedium.copyWith(color: textColor)),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final String? image;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.borderColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled = isDisabled || isLoading || onPressed == null;
    final Color effectiveBorderColor = borderColor ?? AppColors.primary;
    final Color effectiveTextColor = textColor ?? AppColors.primary;

    return SizedBox(
      width: width,
      height: height ?? 44,
      child: OutlinedButton(
        onPressed: isButtonDisabled ? null : onPressed,
        style:
            OutlinedButton.styleFrom(
              splashFactory: InkRipple.splashFactory,
              foregroundColor: effectiveTextColor,
              disabledForegroundColor: AppColors.textTertiaryLight,
              side: BorderSide(color: isButtonDisabled ? AppColors.textTertiaryLight : effectiveBorderColor, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(12)),
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return (textColor ?? AppColors.primary).withValues(alpha: 0.1);
                }
                return null;
              }),
            ),
        child: isLoading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor)))
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
                  if (image != null) ...[Image.asset('$image', width: 20), const SizedBox(width: 10)],
                  Text(text, style: AppTextStyles.buttonLarge.copyWith(color: effectiveTextColor)),
                ],
              ),
      ),
    );
  }
}
