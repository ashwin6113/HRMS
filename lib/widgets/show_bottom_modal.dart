import 'dart:ui';

import 'package:flutter/material.dart';

Future<T?> showBottomModal<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
  bool useRootNavigator = false,
  Color? backgroundColor,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
}) async =>
    await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      useRootNavigator: useRootNavigator,
      barrierColor: Colors.black26,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3,
            sigmaY: 3,
          ),
          child: Material(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        );
      },
    );
