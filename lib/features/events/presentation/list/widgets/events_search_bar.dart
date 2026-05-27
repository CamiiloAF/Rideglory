import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventsSearchBar extends StatelessWidget {
  const EventsSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.textOnDarkPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.event_searchEvents,
          hintStyle: const TextStyle(
            color: AppColors.textOnDarkTertiary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textOnDarkTertiary,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          isDense: true,
        ),
      ),
    );
  }
}
