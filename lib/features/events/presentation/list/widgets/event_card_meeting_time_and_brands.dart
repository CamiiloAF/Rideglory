import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventCardMeetingTimeAndBrands extends StatelessWidget {
  final String formattedTime;
  final bool isMultiBrand;
  final List<String> allowedBrands;

  const EventCardMeetingTimeAndBrands({
    super.key,
    required this.formattedTime,
    required this.isMultiBrand,
    required this.allowedBrands,
  });

  static const double _iconSize = 14.0;

  String allowedBrandsText(BuildContext context) {
    if (allowedBrands.isEmpty) return context.l10n.event_allBrands;
    if (allowedBrands.length == 1) return allowedBrands.first;
    return allowedBrands.take(2).join(', ') +
        (allowedBrands.length > 2 ? ', +${allowedBrands.length - 2}' : '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onSurface.withValues(alpha: .6);
    final textColor = colorScheme.onSurface.withValues(alpha: .7);

    return Row(
      children: [
        Icon(Icons.access_time_outlined, size: _iconSize, color: iconColor),
        AppSpacing.hGapXxs,
        Text(
          '${context.l10n.event_meetingTimePrefix}$formattedTime',
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
        const Spacer(),
        if (!isMultiBrand) ...[
          Icon(
            Icons.shield_outlined,
            size: _iconSize,
            color: colorScheme.secondary,
          ),
          AppSpacing.hGapXxs,
          Text(
            allowedBrandsText(context),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
