import 'package:flutter/material.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_stat_cell.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_stat_divider.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.eventsLabel,
    required this.kmLabel,
    required this.followersLabel,
    this.eventsCount = 0,
    this.kmCount = 0,
    this.followersCount = 0,
  });

  final String eventsLabel;
  final String kmLabel;
  final String followersLabel;
  final int eventsCount;
  final int kmCount;
  final int followersCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileStatCell(value: eventsCount.toString(), label: eventsLabel),
        const ProfileStatDivider(),
        ProfileStatCell(value: kmCount.toString(), label: kmLabel),
        const ProfileStatDivider(),
        ProfileStatCell(value: followersCount.toString(), label: followersLabel),
      ],
    );
  }
}
