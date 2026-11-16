import 'package:flutter/material.dart';
import '../common/constants/app_text_style.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final EdgeInsetsGeometry? padding;
  final String label;
  final VoidCallback? onTap;

  const CustomIconButton({super.key, required this.icon, required this.label, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconCardTheme = Theme.of(context).cardTheme;
    final iconTheme = Theme.of(context).iconTheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: iconCardTheme.color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: iconTheme.color),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(color: textTheme.displayMedium!.color, fontSize: 14, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
