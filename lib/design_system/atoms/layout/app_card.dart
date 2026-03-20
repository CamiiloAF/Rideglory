import 'package:flutter/material.dart';

import '../../foundation/extensions/theme_extensions.dart';
import '../../foundation/tokens/app_radius.dart';

enum AppCardVariant {
  defaultCard,
  elevated,
  outlined,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.variant = AppCardVariant.defaultCard,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    const radius = Radius.circular(AppRadius.sm);

    final border = variant == AppCardVariant.outlined
        ? Border.all(color: cs.outlineVariant, width: 1.5)
        : null;

    final boxShadow = variant == AppCardVariant.elevated
        ? [
            BoxShadow(
              color: context.appColors.shadowMedium,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : null;

    final decoration = BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.all(radius),
      border: border,
      boxShadow: boxShadow,
    );

    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (onTap == null) {
      return Container(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.all(radius),
        onTap: onTap,
        child: Container(
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}

