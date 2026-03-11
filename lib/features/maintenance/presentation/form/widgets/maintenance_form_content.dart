import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/change_vehicle_mileage_bottom_sheet.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/save_maintenance_button.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class MaintenanceFormContent extends StatefulWidget {
  const MaintenanceFormContent({super.key});

  @override
  State<MaintenanceFormContent> createState() => _MaintenanceFormContentState();
}

class _MaintenanceFormContentState extends State<MaintenanceFormContent> {
  VehicleModel? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MaintenanceFormCubit>();
    final vehicleCubit = context.read<VehicleCubit>();

    // Determine initial vehicle
    _selectedVehicle = cubit.preselectedVehicle ?? vehicleCubit.currentVehicle;

    final editingMaintenance = cubit.editingMaintenance;
    if (editingMaintenance != null && editingMaintenance.vehicleId != null) {
      final availableVehicles = vehicleCubit.availableVehicles;
      final vehicle = availableVehicles.firstWhere(
        (v) => v.id == editingMaintenance.vehicleId,
        orElse: () => _selectedVehicle!,
      );
      _selectedVehicle = vehicle;
    }
  }

  Map<String, dynamic> _getInitialValues() {
    final cubit = context.read<MaintenanceFormCubit>();
    final currentVehicleId = context.read<VehicleCubit>().currentVehicle?.id;
    final preselectedVehicleId = cubit.preselectedVehicle?.id;
    final maintenance = cubit.editingMaintenance;

    if (maintenance != null) {
      return {
        MaintenanceFormFields.name: maintenance.name,
        MaintenanceFormFields.type: maintenance.type,
        MaintenanceFormFields.notes: maintenance.notes,
        MaintenanceFormFields.date: maintenance.date,
        MaintenanceFormFields.nextMaintenanceDate:
            maintenance.nextMaintenanceDate,
        MaintenanceFormFields.currentMileage: maintenance.maintanceMileage
            .toString(),
        MaintenanceFormFields.receiveAlert: maintenance.receiveAlert,
        MaintenanceFormFields.receiveMileageAlert:
            maintenance.receiveMileageAlert,
        MaintenanceFormFields.receiveDateAlert: maintenance.receiveDateAlert,
        MaintenanceFormFields.nextMaintenanceMileage: maintenance
            .nextMaintenanceMileage
            ?.toString(),
        MaintenanceFormFields.vehicleId:
            maintenance.vehicleId ?? currentVehicleId,
        MaintenanceFormFields.cost: maintenance.cost?.toString(),
      };
    }

    return {
      MaintenanceFormFields.date: DateTime.now(),
      MaintenanceFormFields.distanceUnit: DistanceUnit.kilometers,
      MaintenanceFormFields.type: MaintenanceType.oilChange,
      MaintenanceFormFields.receiveAlert: false,
      MaintenanceFormFields.receiveMileageAlert: false,
      MaintenanceFormFields.receiveDateAlert: false,
      MaintenanceFormFields.vehicleId: preselectedVehicleId ?? currentVehicleId,
    };
  }

  void _saveMaintenance() {
    final cubit = context.read<MaintenanceFormCubit>();
    final maintenanceToSave = cubit.buildMaintenanceToSave();

    if (maintenanceToSave == null) {
      return;
    }

    final currentMileage = context.read<VehicleCubit>().currentMileage;

    final shouldSyncMileage = cubit.shouldChangeVehicleMileage(
      currentMileage ?? 0,
      maintenanceToSave.maintanceMileage.toInt(),
    );

    if (shouldSyncMileage) {
      return _showChangeVehicleMileageDialog(
        maintenanceToSave,
        currentMileage,
        cubit,
      );
    }

    cubit.saveMaintenance(maintenanceToSave);
  }

  void _showChangeVehicleMileageDialog(
    MaintenanceModel maintenanceToSave,
    int? currentMileage,
    MaintenanceFormCubit cubit,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (dialogContext) => ChangeVehicleMileageBottomSheet(
        maintenanceToSave: maintenanceToSave,
        currentMileage: currentMileage,
        saveMaintenance: (maintenance) {
          cubit.saveMaintenance(maintenance);
        },
      ),
    );
  }

  void validateAndSyncMileageIfNeeded() {}

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MaintenanceFormCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Nombre del Mantenimiento
            AppTextField(
              name: MaintenanceFormFields.name,
              labelText: MaintenanceStrings.maintenanceName,
              isRequired: true,
              hintText: 'Ej: Cambio de aceite sintético',
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: MaintenanceStrings.nameRequired,
                ),
                FormBuilderValidators.minLength(
                  3,
                  errorText: MaintenanceStrings.minCharacters,
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // 2. Tipo de Mantenimiento
            AppDropdown<MaintenanceType>(
              name: MaintenanceFormFields.type,
              labelText: MaintenanceStrings.maintenanceType,
              isRequired: true,
              validator: FormBuilderValidators.required(
                errorText: MaintenanceStrings.typeRequired,
              ),
              items: MaintenanceType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            // 3. Vehículo
            AppDropdown<String>(
              name: MaintenanceFormFields.vehicleId,
              labelText: MaintenanceStrings.vehicle,
              isRequired: true,
              validator: FormBuilderValidators.required(
                errorText: MaintenanceStrings.selectVehicle,
              ),
              items: context
                  .read<VehicleCubit>()
                  .availableVehicles
                  .where((v) => !v.isArchived)
                  .map(
                    (v) => DropdownMenuItem(
                      value: v.id,
                      child: Text('${v.brand} ${v.model}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  final vehicle = context
                      .read<VehicleCubit>()
                      .availableVehicles
                      .firstWhere((v) => v.id == value);
                  setState(() {
                    _selectedVehicle = vehicle;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // 4. Fecha de Servicio
            AppDatePicker(
              fieldName: MaintenanceFormFields.date,
              lastDate: DateTime.now(),
              labelText: MaintenanceStrings.maintenanceDateLabel,
              isRequired: true,
              hintText: 'mm/dd/yyyy',
            ),
            const SizedBox(height: 20),

            // 5. Kilometraje Actual
            AppTextField(
              name: MaintenanceFormFields.currentMileage,
              labelText: MaintenanceStrings.maintenanceMileage,
              isRequired: true,
              suffixText: 'KM',
              suffixStyle: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurfaceVariant,
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.numeric(),
              ]),
            ),
            const SizedBox(height: 20),

            // 6. Costo del Mantenimiento
            AppTextField(
              name: MaintenanceFormFields.cost,
              labelText: MaintenanceStrings.maintenanceCost,
              prefixIcon: Icons.attach_money,
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // 7. Notas / Observaciones
            AppTextField(
              name: MaintenanceFormFields.notes,
              labelText: MaintenanceStrings.maintenanceNotes,
              hintText: 'Detalles adicionales sobre el trabajo realizado...',
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // 8. Alertas de próximo servicio
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MaintenanceStrings.alertsConfiguration,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Alerta por Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: context.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          MaintenanceStrings.dateAlert,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FormBuilderField<bool>(
                        name: MaintenanceFormFields.receiveDateAlert,
                        builder: (field) {
                          return Switch(
                            value: field.value ?? false,
                            onChanged: (val) => field.didChange(val),
                            activeThumbColor: context.colorScheme.primary,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppDatePicker(
                    fieldName: MaintenanceFormFields.nextMaintenanceDate,
                    labelText: MaintenanceStrings.nextMaintenanceDate,
                    firstDate: DateTime.now(),
                    hintText: 'mm/dd/yyyy',
                  ),
                  const SizedBox(height: 8),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),

                  // Alerta por Kilometraje
                  Row(
                    children: [
                      Icon(
                        Icons.speed_outlined,
                        color: context.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          MaintenanceStrings.mileageAlert,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FormBuilderField<bool>(
                        name: MaintenanceFormFields.receiveMileageAlert,
                        builder: (field) {
                          return Switch(
                            value: field.value ?? false,
                            onChanged: (val) => field.didChange(val),
                            activeThumbColor: context.colorScheme.primary,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    name: MaintenanceFormFields.nextMaintenanceMileage,
                    labelText: MaintenanceStrings.nextMaintenanceMileageLabel,
                    hintText: 'Ej: 15000',
                    suffixText: 'KM',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Botón de guardado
            SaveMaintenanceButton(onSave: _saveMaintenance),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
