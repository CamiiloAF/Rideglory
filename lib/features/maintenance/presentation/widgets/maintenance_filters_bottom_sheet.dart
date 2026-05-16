import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class MaintenanceFiltersBottomSheet extends StatefulWidget {
  final MaintenanceFilters initialFilters;
  final List<VehicleModel> availableVehicles;

  const MaintenanceFiltersBottomSheet({
    super.key,
    required this.initialFilters,
    required this.availableVehicles,
  });

  @override
  State<MaintenanceFiltersBottomSheet> createState() =>
      _MaintenanceFiltersBottomSheetState();
}

class _MaintenanceFiltersBottomSheetState
    extends State<MaintenanceFiltersBottomSheet> {
  late MaintenanceFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _clearAll() {
    setState(() {
      _filters = const MaintenanceFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.darkBorderPrimary),
          left: BorderSide(color: AppColors.darkBorderPrimary),
          right: BorderSide(color: AppColors.darkBorderPrimary),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HandleBar(),
          _PanelHeader(
            hasActiveFilters: _filters.hasActiveFilters,
            onClearAll: _clearAll,
          ),
          const _Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _TypeSection(
                    selectedTypes: _filters.types,
                    onChanged: (types) =>
                        setState(() => _filters = _filters.copyWith(types: types)),
                  ),
                  const _Divider(),
                  _StatusSection(
                    selected: _filters.statusFilter,
                    onChanged: (status) => setState(
                      () => _filters = _filters.copyWith(statusFilter: status),
                    ),
                  ),
                  const _Divider(),
                  _DateRangeSection(
                    selected: _filters.dateRange,
                    onChanged: (range) => setState(
                      () => _filters = _filters.copyWith(
                        dateRange: () => range,
                        customStartDate: null,
                        customEndDate: null,
                      ),
                    ),
                  ),
                  const _Divider(),
                ],
              ),
            ),
          ),
          _CtaBar(
            activeFilterCount: _filters.activeFilterCount,
            onClear: _clearAll,
            onApply: () => Navigator.pop(context, _filters),
          ),
        ],
      ),
    );
  }
}

class _HandleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A44),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClearAll;

  const _PanelHeader({required this.hasActiveFilters, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (hasActiveFilters)
            GestureDetector(
              onTap: onClearAll,
              child: Text(
                context.l10n.maintenance_filter_clear_all,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFF2A2A32));
  }
}

class _TypeSection extends StatelessWidget {
  final List<MaintenanceType> selectedTypes;
  final ValueChanged<List<MaintenanceType>> onChanged;

  const _TypeSection({
    required this.selectedTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(context.l10n.maintenance_filter_type_label),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MaintenanceType.values.map((type) {
              final isSelected = selectedTypes.contains(type);
              return _TypeChip(
                label: type.label,
                isSelected: isSelected,
                onTap: () {
                  final updated = List<MaintenanceType>.from(selectedTypes);
                  if (isSelected) {
                    updated.remove(type);
                  } else {
                    updated.add(type);
                  }
                  onChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : const Border.fromBorderSide(
                  BorderSide(color: Color(0xFF2A2A32)),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final MaintenanceStatusFilter selected;
  final ValueChanged<MaintenanceStatusFilter> onChanged;

  const _StatusSection({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(context.l10n.maintenance_filter_status_label),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: context.l10n.maintenance_filter_status_all,
                textColor: const Color(0xFF9CA3AF),
                fillColor: const Color(0xFF1A1A1F),
                borderColor: const Color(0xFF2A2A32),
                isSelected: selected == MaintenanceStatusFilter.all,
                onTap: () => onChanged(MaintenanceStatusFilter.all),
              ),
              _StatusChip(
                label: context.l10n.maintenance_filter_status_overdue,
                textColor: const Color(0xFFEF4444),
                fillColor: const Color(0x20EF4444),
                borderColor: const Color(0x50EF4444),
                isSelected: selected == MaintenanceStatusFilter.overdue,
                onTap: () => onChanged(MaintenanceStatusFilter.overdue),
              ),
              _StatusChip(
                label: context.l10n.maintenance_filter_status_upcoming,
                textColor: const Color(0xFFEAB308),
                fillColor: const Color(0x20EAB308),
                borderColor: const Color(0x50EAB308),
                isSelected: selected == MaintenanceStatusFilter.next,
                onTap: () => onChanged(MaintenanceStatusFilter.next),
              ),
              _StatusChip(
                label: context.l10n.maintenance_filter_status_on_track,
                textColor: const Color(0xFF22C55E),
                fillColor: const Color(0x2022C55E),
                borderColor: const Color(0x5022C55E),
                isSelected: selected == MaintenanceStatusFilter.upToDate,
                onTap: () => onChanged(MaintenanceStatusFilter.upToDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color fillColor;
  final Color borderColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.textColor,
    required this.fillColor,
    required this.borderColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(
            BorderSide(
              color: isSelected ? textColor : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _DateRangeSection extends StatelessWidget {
  final MaintenanceDateRange? selected;
  final ValueChanged<MaintenanceDateRange?> onChanged;

  const _DateRangeSection({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (MaintenanceDateRange.thisMonth, context.l10n.maintenance_filter_date_this_month),
      (MaintenanceDateRange.last3Months, context.l10n.maintenance_filter_date_last_3_months),
      (MaintenanceDateRange.lastYear, context.l10n.maintenance_filter_date_last_year),
      (MaintenanceDateRange.custom, context.l10n.maintenance_filter_date_custom),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(context.l10n.maintenance_filter_date_range_label),
          const SizedBox(height: 4),
          ...options.map((entry) {
            final (range, label) = entry;
            final isSelected = selected == range;
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : range),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    _RadioIndicator(isSelected: isSelected),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;

  const _RadioIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A2A32), width: 1.5),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CtaBar extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const _CtaBar({
    required this.activeFilterCount,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFF2A2A32)),
                  ),
                ),
                child: Center(
                  child: Text(
                    context.l10n.maintenance_filter_clear,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onApply,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Aplicar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (activeFilterCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(77),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
