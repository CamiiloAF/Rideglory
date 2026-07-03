import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_card_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_row_divider.dart';

class _SpecRowData {
  const _SpecRowData({required this.label, required this.value});
  final String label;
  final String value;
}

class VehicleDetailSpecsCard extends StatelessWidget {
  const VehicleDetailSpecsCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  String _formatKm(int km) =>
      NumberFormat('#,###').format(km).replaceAll(',', '.');

  @override
  Widget build(BuildContext context) {
    final rows = <_SpecRowData>[
      if (vehicle.brand != null)
        _SpecRowData(
          label: context.l10n.vehicle_specBrand,
          value: vehicle.brand!,
        ),
      if (vehicle.model != null)
        _SpecRowData(
          label: context.l10n.vehicle_specModel,
          value: vehicle.model!,
        ),
      if (vehicle.year != null)
        _SpecRowData(
          label: context.l10n.vehicle_specYear,
          value: '${vehicle.year}',
        ),
      _SpecRowData(
        label: context.l10n.vehicle_currentMileageLabel,
        value: '${_formatKm(vehicle.currentMileage)} km',
      ),
      if (vehicle.purchaseDate != null)
        _SpecRowData(
          label: context.l10n.vehicle_specPurchaseDate,
          value: DateFormat.yMMMd('es').format(vehicle.purchaseDate!),
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleDetailCardHeader(
            icon: Icons.settings_outlined,
            label: context.l10n.vehicle_specs,
          ),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.value.label,
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        entry.value.value,
                        style: const TextStyle(
                          color: AppColors.textOnDarkPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const VehicleDetailRowDivider(),
              ],
            );
          }),
        ],
      ),
    );
  }
}
