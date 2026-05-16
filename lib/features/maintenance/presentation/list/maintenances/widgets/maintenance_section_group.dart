import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart';

class MaintenanceSectionGroup extends StatelessWidget {
  final String label;
  final Color accentColor;
  final List<MaintenanceModel> items;
  final MaintenanceItemStatus status;
  final Future<void> Function(MaintenanceModel) onTap;

  const MaintenanceSectionGroup({
    super.key,
    required this.label,
    required this.accentColor,
    required this.items,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final countLabel = items.length == 1
        ? '1 servicio'
        : '${items.length} servicios';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                countLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textOnDarkTertiary,
                  fontWeight: FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ...items.map(
          (maintenance) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MaintenanceGroupedListItem(
              maintenance: maintenance,
              status: status,
              onTap: () => onTap(maintenance),
            ),
          ),
        ),
      ],
    );
  }
}
