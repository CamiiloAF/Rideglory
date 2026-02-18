import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class MaintenanceFilters {
  final String? searchQuery;
  final List<MaintenanceType> types;
  final List<String> vehicleIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? showUrgentOnly;
  final MaintenanceSortOption sortBy;

  const MaintenanceFilters({
    this.searchQuery,
    this.types = const [],
    this.vehicleIds = const [],
    this.startDate,
    this.endDate,
    this.showUrgentOnly,
    this.sortBy = MaintenanceSortOption.nextMaintenance,
  });

  MaintenanceFilters copyWith({
    String? searchQuery,
    List<MaintenanceType>? types,
    List<String>? vehicleIds,
    DateTime? startDate,
    DateTime? endDate,
    bool Function()? showUrgentOnly,
    MaintenanceSortOption? sortBy,
  }) {
    return MaintenanceFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      types: types ?? this.types,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showUrgentOnly: showUrgentOnly != null
          ? showUrgentOnly()
          : this.showUrgentOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      (searchQuery?.isNotEmpty ?? false) ||
      types.isNotEmpty ||
      vehicleIds.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      showUrgentOnly == true;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery?.isNotEmpty ?? false) count++;
    if (types.isNotEmpty) count++;
    if (vehicleIds.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    if (showUrgentOnly == true) count++;
    return count;
  }
}

enum MaintenanceSortOption { nextMaintenance, date, name }

extension MaintenanceSortOptionExt on MaintenanceSortOption {
  String get label {
    switch (this) {
      case MaintenanceSortOption.nextMaintenance:
        return 'Próximo mantenimiento';
      case MaintenanceSortOption.date:
        return 'Fecha de realización';
      case MaintenanceSortOption.name:
        return 'Nombre';
    }
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                if (_filters.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filters = const MaintenanceFilters();
                      });
                    },
                    child: const Text('Limpiar'),
                  ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort by
                  _buildSectionTitle('Ordenar por'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MaintenanceSortOption.values.map((option) {
                      final isSelected = _filters.sortBy == option;
                      return FilterChip(
                        label: Text(option.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filters = _filters.copyWith(sortBy: option);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Maintenance types
                  _buildSectionTitle('Tipos de mantenimiento'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MaintenanceType.values.map((type) {
                      final isSelected = _filters.types.contains(type);
                      return FilterChip(
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            final newTypes = List<MaintenanceType>.from(
                              _filters.types,
                            );
                            if (selected) {
                              newTypes.add(type);
                            } else {
                              newTypes.remove(type);
                            }
                            _filters = _filters.copyWith(types: newTypes);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Vehicles
                  if (widget.availableVehicles.isNotEmpty) ...[
                    _buildSectionTitle('Vehículos'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availableVehicles.map((vehicle) {
                        final isSelected = _filters.vehicleIds.contains(
                          vehicle.id,
                        );
                        return FilterChip(
                          label: Text(vehicle.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              final newIds = List<String>.from(
                                _filters.vehicleIds,
                              );
                              if (selected && vehicle.id != null) {
                                newIds.add(vehicle.id!);
                              } else {
                                newIds.remove(vehicle.id);
                              }
                              _filters = _filters.copyWith(vehicleIds: newIds);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Urgent only
                  SwitchListTile(
                    title: const Text('Solo urgentes'),
                    subtitle: const Text(
                      'Próximo mantenimiento en 7 días o menos',
                    ),
                    value: _filters.showUrgentOnly ?? false,
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(
                          showUrgentOnly: () => value,
                        );
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  // Date range
                  _buildSectionTitle('Rango de fechas'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _filters.startDate != null
                                ? '${_filters.startDate!.day}/${_filters.startDate!.month}/${_filters.startDate!.year}'
                                : 'Fecha inicio',
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _filters.startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _filters = _filters.copyWith(startDate: date);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _filters.endDate != null
                                ? '${_filters.endDate!.day}/${_filters.endDate!.month}/${_filters.endDate!.year}'
                                : 'Fecha fin',
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _filters.endDate ?? DateTime.now(),
                              firstDate: _filters.startDate ?? DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _filters = _filters.copyWith(endDate: date);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _filters),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
    );
  }
}
