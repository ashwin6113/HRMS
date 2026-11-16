import 'package:flutter/material.dart';
import 'package:hrms/common/constants/constant.dart';

void showErrorSnackBar(BuildContext context, String text) => showSnackBar(context, text, color: AppColors.error.withValues(alpha: 0.8));

void showSuccessSnackBar(BuildContext context, String text) => showSnackBar(context, text, color: AppColors.success.withValues(alpha: 0.8));

void showSnackBar(BuildContext context, String text, {Color? color, Color? textColor}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      elevation: 10.0,
      margin: const EdgeInsets.only(bottom: 24.0, left: 12.0, right: 12.0),
      backgroundColor: color,
      showCloseIcon: false,
    ),
  );
}
