import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_card.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class RiderTelemetryPanel extends StatefulWidget {
  const RiderTelemetryPanel({
    super.key,
    required this.event,
  });

  final EventModel event;

  @override
  State<RiderTelemetryPanel> createState() => _RiderTelemetryPanelState();
}

class _RiderTelemetryPanelState extends State<RiderTelemetryPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final mqHeight = MediaQuery.of(context).size.height;
    final height = _isExpanded ? mqHeight * 0.27 : mqHeight * 0.1;

    final mockRiders = <_MockRider>[
      _MockRider(
        name: context.l10n.map_mockRiderAlex,
        roleLabel: context.l10n.map_riderLead,
        deviceLabel: context.l10n.map_mockDeviceGarmin1040,
        speedKmh: 45,
        distanceMeters: 200,
        batteryPercent: 85,
        isActive: true,
      ),
      _MockRider(
        name: context.l10n.map_mockRiderMarkThompson,
        roleLabel: context.l10n.map_riderRole,
        deviceLabel: context.l10n.map_mockDeviceGarmin530,
        speedKmh: 42,
        distanceMeters: 420,
        batteryPercent: 62,
        isActive: true,
      ),
      _MockRider(
        name: context.l10n.map_mockRiderSarahJenkins,
        roleLabel: context.l10n.map_riderRole,
        deviceLabel: context.l10n.map_mockDeviceWahooElemnt,
        speedKmh: 38,
        distanceMeters: 510,
        batteryPercent: 44,
        isActive: true,
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.map_riderTelemetry,
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                    ),
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mockRiders.length,
                    separatorBuilder: (_, _) => SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final rider = mockRiders[index];
                      return RiderTelemetryCard(
                        name: rider.name,
                        roleLabel: rider.roleLabel,
                        deviceLabel: rider.deviceLabel,
                        speedKmh: rider.speedKmh,
                        distanceMeters: rider.distanceMeters,
                        batteryPercent: rider.batteryPercent,
                        isActive: rider.isActive,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MockRider {
  const _MockRider({
    required this.name,
    required this.roleLabel,
    required this.deviceLabel,
    required this.speedKmh,
    required this.distanceMeters,
    required this.batteryPercent,
    required this.isActive,
  });

  final String name;
  final String roleLabel;
  final String deviceLabel;
  final int speedKmh;
  final int distanceMeters;
  final int batteryPercent;
  final bool isActive;
}
