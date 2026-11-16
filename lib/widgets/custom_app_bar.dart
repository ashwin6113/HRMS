import 'package:flutter/material.dart';
import 'package:hrms/common/constants/constant.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? subtitle;
  final String? subtext;
  final bool hasProfile;
  final bool hasTextButton;
  final String? textButtonName;
  final bool hasSearch;
  final Widget? actionWidget;
  final Widget? searchBar;
  final Widget? logo;
  final List<Widget>? actions;

  final VoidCallback? onProfilePressed;
  final VoidCallback? onSearchTap;
  final VoidCallback? onTextPressed;
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.subtext,
    this.hasProfile = false,
    this.hasTextButton = false,
    this.textButtonName,
    this.searchBar,
    this.showBackButton = false,
    this.hasSearch = false,
    this.actionWidget,
    this.onProfilePressed,
    this.onSearchTap,
    this.logo,
    this.onTextPressed,
    this.backgroundColor,
    this.onBackPressed,
    this.actions,
  });

  @override
  Size get preferredSize {
    double baseHeight = kToolbarHeight;
    double extraTextHeight = 0;

    if (subtitle != null) extraTextHeight += 20;
    if (subtext != null) extraTextHeight += 20;

    if (extraTextHeight > 0) extraTextHeight += 8;

    final searchHeight = hasSearch ? kToolbarHeight : 0;

    return Size.fromHeight(baseHeight + extraTextHeight + searchHeight);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: preferredSize.height - (hasSearch ? 100 : 0),
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: EdgeInsets.only(top: logo != null ? 12 : 0, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  Padding(padding: const EdgeInsets.only(right: 8.0), child: logo!)
                else if (showBackButton)
                  GestureDetector(
                    onTap: onBackPressed,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.chevron_left, size: 28, color: colorScheme.onSurface),
                    ),
                  ),
                if (title != null)
                  Expanded(
                    child: Text(title!, style: AppTextStyles.heading4, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: (showBackButton || logo != null) ? 36.0 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null) Text(subtitle!, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
                  if (subtext != null)
                    Text(
                      subtext!,
                      style: AppTextStyles.labelMedium.copyWith(color: colorScheme.onSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
      leading: null,
      actionsPadding: EdgeInsets.only(top: 8),
      actions: [
        ...?actions,
        if (hasProfile)
          IconButton(onPressed: onProfilePressed ?? () {}, icon: const Icon(Icons.account_circle_outlined, size: 28))
        else if (hasTextButton)
          TextButton(
            onPressed: onTextPressed,
            child: Text(textButtonName!, style: TextStyle()),
          ),
      ],
      bottom: hasSearch
          ? PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onSearchTap,
                      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12), child: searchBar),
                    ),
                  ),
                  ?actionWidget,
                ],
              ),
            ),
          ],
        ),
      )
          : null,
      elevation: 0,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
