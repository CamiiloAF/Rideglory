import 'package:flutter/material.dart';
import 'package:rideglory/features/users/presentation/widgets/rider_stat_cell.dart';

class RiderStatsRow extends StatelessWidget {
  const RiderStatsRow({
    super.key,
    required this.eventsLabel,
    required this.followersLabel,
    required this.followingLabel,
  });

  final String eventsLabel;
  final String followersLabel;
  final String followingLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RiderStatCell(value: '0', label: eventsLabel),
        const SizedBox(width: 8),
        RiderStatCell(value: '0', label: followersLabel),
        const SizedBox(width: 8),
        RiderStatCell(value: '0', label: followingLabel),
      ],
    );
  }
}
