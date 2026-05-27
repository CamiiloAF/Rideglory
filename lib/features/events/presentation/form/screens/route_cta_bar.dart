import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class RouteCtaBar extends StatelessWidget {
  const RouteCtaBar({super.key, required this.hasWaypoints});

  final bool hasWaypoints;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Opacity(
          opacity: hasWaypoints ? 1.0 : 0.4,
          child: AppButton(
            label: context.l10n.route_builder_continue,
            onPressed: hasWaypoints ? () => Navigator.of(context).pop() : null,
          ),
        ),
      ),
    );
  }
}
