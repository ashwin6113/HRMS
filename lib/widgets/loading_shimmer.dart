import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../common/constants/app_colors.dart';

class LoadingShimmer extends StatelessWidget {
  final double height, width;

  const LoadingShimmer({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.shimmerBaseLight;
    final highlightColor = AppColors.shimmerHighlightLight;
    final backgroundColor = AppColors.shimmerBaseLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth = width == double.infinity ? (constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width) : width;
        return Shimmer(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0.33, 0.66, 0.99], colors: [baseColor, highlightColor, baseColor]),
          child: Container(height: height, width: safeWidth, color: backgroundColor),
        );
      },
    );
  }
}

class LoadingCard extends StatelessWidget {
  final bool isPortrait, hasImage;
  final double imageHeight, titleHeight, subtitleHeight, spacing;

  const LoadingCard({super.key, this.isPortrait = true, this.hasImage = true, this.imageHeight = 50.0, this.titleHeight = 20.0, this.subtitleHeight = 16.0, this.spacing = 8.0});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(padding: const EdgeInsets.all(16.0), child: isPortrait ? _buildPortraitLayout(context) : _buildLandscapeLayout(context)),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          Center(
            child: LoadingShimmer(width: screenWidth * 0.9, height: imageHeight),
          ),
          SizedBox(height: spacing * 2),
        ],
        LoadingShimmer(width: screenWidth * 0.9, height: titleHeight),
        SizedBox(height: spacing),
        LoadingShimmer(width: screenWidth * 0.7, height: subtitleHeight),
        SizedBox(height: spacing),
        LoadingShimmer(width: screenWidth * 0.5, height: subtitleHeight),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) LoadingShimmer(width: imageHeight, height: imageHeight),
        if (hasImage) SizedBox(width: spacing * 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingShimmer(width: screenWidth * 0.7, height: titleHeight),
              SizedBox(height: spacing),
              LoadingShimmer(width: screenWidth * 0.2, height: subtitleHeight),
            ],
          ),
        ),
      ],
    );
  }
}
