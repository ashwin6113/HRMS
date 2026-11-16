import 'package:flutter/material.dart';

Future<void> showCustomBottomSheet({required BuildContext context, required String title, String? description, required final Widget widget1, required final Widget widget2, required bool isRow}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return _CustomBottomSheetContent(title: title, description: description, widget1: widget1, widget2: widget2, isRow: isRow);
    },
  );
}

class _CustomBottomSheetContent extends StatelessWidget {
  const _CustomBottomSheetContent({required this.title, this.description, required this.widget1, required this.widget2, required this.isRow});

  final String title;
  final bool isRow;
  final String? description;
  final Widget widget1;
  final Widget widget2;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 10.0),
                child: Text(description!, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 8),

            isRow
                ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [widget1, widget2])
                : Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [widget1, widget2]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
