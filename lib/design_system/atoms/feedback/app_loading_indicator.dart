import 'package:flutter/material.dart';

import '../../foundation/extensions/theme_extensions.dart';

enum AppLoadingIndicatorVariant {
  inline,
  page,
  sliver,
}

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.variant = AppLoadingIndicatorVariant.page,
    this.size = 24,
    this.strokeWidth = 2.5,
  });

  /// Inline variant size in logical pixels.
  final double size;

  /// Circular progress stroke width.
  final double strokeWidth;

  final AppLoadingIndicatorVariant variant;

  Widget _buildIndicator(BuildContext context, {required bool centered}) {
    final cs = context.colorScheme;

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
      ),
    );

    if (!centered) return indicator;
    return Center(child: indicator);
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppLoadingIndicatorVariant.inline:
        return _buildIndicator(context, centered: false);
      case AppLoadingIndicatorVariant.page:
        return _buildIndicator(context, centered: true);
      case AppLoadingIndicatorVariant.sliver:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildIndicator(context, centered: true),
        );
    }
  }
}

