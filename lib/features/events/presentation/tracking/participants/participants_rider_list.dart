import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_section_header.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/rider_list_item.dart';

class ParticipantsRiderList extends StatelessWidget {
  const ParticipantsRiderList({super.key, required this.riders});

  final List<RiderTrackingModel> riders;

  @override
  Widget build(BuildContext context) {
    final active = riders.where((r) => r.isActive).toList();
    final inactive = riders.where((r) => !r.isActive).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (active.isNotEmpty) ...[
          ParticipantsSectionHeader(
            label: context.l10n.map_activeRiders.toUpperCase(),
            count: active.length,
          ),
          ...active.map((r) => RiderListItem(rider: r)),
        ],
        if (inactive.isNotEmpty) ...[
          AppSpacing.gapMd,
          ParticipantsSectionHeader(
            label: context.l10n.map_riderRole.toUpperCase(),
            count: inactive.length,
            isInactive: true,
          ),
          ...inactive.map((r) => RiderListItem(rider: r)),
        ],
      ],
    );
  }
}
