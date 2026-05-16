import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_context_card.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_cta_bar.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_mileage_update_banner.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_next_service_card.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_status_toggle.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class MaintenanceFormContent extends StatefulWidget {
  final MaintenanceType selectedType;
  final VoidCallback onChangeType;

  const MaintenanceFormContent({
    super.key,
    required this.selectedType,
    required this.onChangeType,
  });

  @override
  State<MaintenanceFormContent> createState() => _MaintenanceFormContentState();
}

class _MaintenanceFormContentState extends State<MaintenanceFormContent> {
  bool _isCompleted = true;
  int? _maintenanceOdometer;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MaintenanceFormCubit>();
    final editing = cubit.editingMaintenance;
    if (editing != null) {
      _isCompleted = !editing.isScheduled;
      _maintenanceOdometer = editing.maintanceMileage;
    }
    final vehicleCubit = context.read<VehicleCubit>();
    cubit.setVehicleId(vehicleCubit.currentVehicle?.id);
    cubit.setCurrentVehicleMileage(vehicleCubit.currentMileage);
  }

  Map<String, dynamic> _getInitialValues() {
    final cubit = context.read<MaintenanceFormCubit>();
    final currentVehicleId = context.read<VehicleCubit>().currentVehicle?.id;
    final preselectedVehicleId = cubit.preselectedVehicle?.id;
    final maintenance = cubit.editingMaintenance;

    if (maintenance != null) {
      final vehicleKm = context.read<VehicleCubit>().currentMileage
          ?? cubit.currentVehicleMileage
          ?? cubit.preselectedVehicle?.currentMileage
          ?? 0;
      // Scheduled: base is current vehicle km (how far until due)
      // Completed: base is the maintenance odometer (how far until next)
      final base = maintenance.isScheduled ? vehicleKm : maintenance.maintanceMileage;
      final relativeNextKm = maintenance.nextMaintenanceMileage != null
          ? (maintenance.nextMaintenanceMileage! - base).clamp(0, double.maxFinite.toInt())
          : null;
      return {
        MaintenanceFormFields.type: maintenance.type,
        MaintenanceFormFields.notes: maintenance.notes,
        MaintenanceFormFields.date: maintenance.date,
        MaintenanceFormFields.nextMaintenanceDate:
            maintenance.nextMaintenanceDate,
        MaintenanceFormFields.currentMileage:
            maintenance.maintanceMileage.toString(),
        MaintenanceFormFields.nextMaintenanceMileage:
            relativeNextKm?.toString(),
        MaintenanceFormFields.vehicleId:
            maintenance.vehicleId ?? currentVehicleId,
        MaintenanceFormFields.cost: maintenance.cost?.toString(),
      };
    }

    return {
      MaintenanceFormFields.type: widget.selectedType,
      MaintenanceFormFields.date: DateTime.now(),
      MaintenanceFormFields.vehicleId: preselectedVehicleId ?? currentVehicleId,
    };
  }

  void _saveMaintenance() {
    final cubit = context.read<MaintenanceFormCubit>();
    var maintenanceToSave = cubit.buildMaintenanceToSave(isScheduled: !_isCompleted);
    if (maintenanceToSave == null) return;

    final vehicleCubit = context.read<VehicleCubit>();
    final vehicleKm = vehicleCubit.currentMileage ?? cubit.currentVehicleMileage ?? 0;

    if (!_isCompleted) {
      // Scheduled: next fields belong to this record; compute absolute km from current vehicle km.
      final base = vehicleKm;
      final absoluteNextKm = maintenanceToSave.nextMaintenanceMileage != null
          ? base + maintenanceToSave.nextMaintenanceMileage!
          : null;
      maintenanceToSave = maintenanceToSave.copyWith(
        maintanceMileage: vehicleKm,
        nextMaintenanceMileage: absoluteNextKm,
      );
    } else {
      // Completed: next fields must NOT be stored on the record.
      // If filled → create a follow-up scheduled maintenance instead.
      final base = _maintenanceOdometer ?? vehicleKm;
      final relativeNextKm = maintenanceToSave.nextMaintenanceMileage;
      final absoluteNextKm = relativeNextKm != null ? base + relativeNextKm : null;
      final nextDate = maintenanceToSave.nextMaintenanceDate;

      maintenanceToSave = maintenanceToSave.copyWith(
        nextMaintenanceMileage: null,
        nextMaintenanceDate: null,
      );

      if (maintenanceToSave.maintanceMileage > vehicleKm) {
        vehicleCubit.updateMileage(maintenanceToSave.maintanceMileage);
      }

      if (absoluteNextKm != null || nextDate != null) {
        cubit.createFollowUpScheduled(
          MaintenanceModel(
            vehicleId: maintenanceToSave.vehicleId,
            userId: maintenanceToSave.userId,
            type: maintenanceToSave.type,
            date: nextDate ?? DateTime.now(),
            maintanceMileage: vehicleKm,
            isScheduled: true,
            nextMaintenanceMileage: absoluteNextKm,
            nextMaintenanceDate: nextDate,
          ),
        );
      }
    }

    cubit.saveMaintenance(maintenanceToSave);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MaintenanceFormCubit>();
    final now = DateTime.now();
    final vehicleCurrentMileage = context.read<VehicleCubit>().currentMileage
        ?? cubit.currentVehicleMileage
        ?? cubit.preselectedVehicle?.currentMileage;
    final showMileageBanner =
        _isCompleted &&
        _maintenanceOdometer != null &&
        vehicleCurrentMileage != null &&
        _maintenanceOdometer! > vehicleCurrentMileage;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: FormBuilder(
              key: cubit.formKey,
              initialValue: _getInitialValues(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MaintenanceContextCard(
                    selectedType: widget.selectedType,
                    onChangeType: widget.onChangeType,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.maintenance_form_estado_section,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkTertiary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MaintenanceStatusToggle(
                    isCompleted: _isCompleted,
                    onToggle: (value) => setState(() {
                      _isCompleted = value;
                      if (!value) _maintenanceOdometer = null;
                    }),
                  ),
                  if (_isCompleted) ...[
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.maintenance_sectionDetails,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDarkTertiary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppDatePicker(
                      fieldName: MaintenanceFormFields.date,
                      labelText: context.l10n.maintenance_maintenanceDateLabel,
                      isRequired: true,
                      firstDate: DateTime(2000),
                      lastDate: now,
                    ),
                    const SizedBox(height: 12),
                    AppMileageField(
                      name: MaintenanceFormFields.currentMileage,
                      labelText: context.l10n.maintenance_form_km_label,
                      isRequired: true,
                      validators:
                          AppMileageField.defaultCurrentMileageValidators(
                            context,
                          ),
                      onChanged: (value) => setState(
                        () => _maintenanceOdometer = int.tryParse(value ?? ''),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.maintenance_form_cost_taller_section,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDarkTertiary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      name: MaintenanceFormFields.cost,
                      labelText: context.l10n.maintenance_totalCost,
                      prefixText: '\$',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0.00',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      name: MaintenanceFormFields.workshop,
                      labelText: context.l10n.maintenance_form_taller_label,
                      suffixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                      ),
                      hintText: 'Ej: Taller Moto Service',
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.maintenance_form_notes_section,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkTertiary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: MaintenanceFormFields.notes,
                    labelText: context.l10n.maintenance_maintenanceNotes,
                    maxLines: null,
                    minLines: 4,
                    hintText:
                        'Detalles adicionales sobre el trabajo realizado...',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isCompleted
                        ? 'CREAR PRÓXIMO MANTENIMIENTO'
                        : 'PROGRAMADO PARA',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkTertiary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MaintenanceNextServiceCard(
                    isCompleted: _isCompleted,
                    currentMileage: vehicleCurrentMileage,
                    baseKm: _maintenanceOdometer ?? vehicleCurrentMileage,
                    initialNextMileage: () {
                      final editing = cubit.editingMaintenance;
                      if (editing?.nextMaintenanceMileage == null) return null;
                      final base = editing!.maintanceMileage;
                      return (editing.nextMaintenanceMileage! - base).clamp(0, double.maxFinite.toInt());
                    }(),
                    initialNextDate:
                        cubit.editingMaintenance?.nextMaintenanceDate,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showMileageBanner)
          MaintenanceMileageUpdateBanner(
            currentMileage: vehicleCurrentMileage,
            newMileage: _maintenanceOdometer!,
          ),
        MaintenanceFormCtaBar(
          onSave: _saveMaintenance,
          onDiscard: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
