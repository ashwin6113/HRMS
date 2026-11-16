import 'package:flutter/material.dart';

class StaticSearchBar extends StatelessWidget {
  final Icon prefixIcon;
  final String hintText;

  const StaticSearchBar({
    super.key,
    required this.prefixIcon,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          prefixIcon,
          const SizedBox(width: 10),
          Text(
            hintText,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
