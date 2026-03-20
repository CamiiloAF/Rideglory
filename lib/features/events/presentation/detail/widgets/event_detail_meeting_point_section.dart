import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

const Color _mapPlaceholderBackground = Color(0xFF1F2B3B);

class EventDetailMeetingPointSection extends StatelessWidget {
  const EventDetailMeetingPointSection({
    super.key,
    required this.location,
    this.onViewMap,
  });

  final String location;
  final VoidCallback? onViewMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_meetingPointLabel,
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        AppSpacing.gapMd,
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 168,
                width: double.infinity,
                color: _mapPlaceholderBackground,
                child: Center(
                  child: Icon(
                    Icons.place,
                    color: context.colorScheme.primary,
                    size: 56,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.event_meetingPointLabel,
                            style: TextStyle(
                              color: context.colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.gapXxs,
                          Text(
                            location,
                            style: TextStyle(
                              color: context.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onViewMap != null) ...[
                      AppSpacing.hGapMd,
                      Material(
                        color: context.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: onViewMap,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                AppSpacing.hGapSm,
                                Text(
                                  context.l10n.event_viewMap,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
