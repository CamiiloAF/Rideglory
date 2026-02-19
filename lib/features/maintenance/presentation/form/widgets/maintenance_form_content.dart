import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/change_vehicle_mileage_bottom_sheet.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/next_maintenance_mileage_field.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/save_maintenance_button.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/selected_vehicle_card.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/vehicle_selection_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_checkbox.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/form/mileages_and_unit_fields.dart';

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
    final vehicleListCubit = context.read<VehicleListCubit>();

    // Determine initial vehicle
    _selectedVehicle = cubit.preselectedVehicle ?? vehicleCubit.currentVehicle;

    // If editing, get the vehicle from the list
    cubit.state.maybeWhen(
      editing: (maintenance) {
        if (maintenance.vehicleId != null) {
          final vehicleListState = vehicleListCubit.state;
          if (vehicleListState is Data<List<VehicleModel>>) {
            final vehicle = vehicleListState.data.firstWhere(
              (v) => v.id == maintenance.vehicleId,
              orElse: () => _selectedVehicle!,
            );
            _selectedVehicle = vehicle;
          }
        }
      },
      orElse: () {},
    );
  }

  Map<String, dynamic> _getInitialValues() {
    final state = context.read<MaintenanceFormCubit>().state;
    final cubit = context.read<MaintenanceFormCubit>();
    final currentVehicleId = context.read<VehicleCubit>().currentVehicle?.id;
    final preselectedVehicleId = cubit.preselectedVehicle?.id;

    return state.maybeWhen(
      editing: (maintenance) {
        return {
          MaintenanceFormFields.name: maintenance.name,
          MaintenanceFormFields.type: maintenance.type,
          MaintenanceFormFields.notes: maintenance.notes,
          MaintenanceFormFields.date: maintenance.date,
          MaintenanceFormFields.nextMaintenanceDate:
              maintenance.nextMaintenanceDate,
          MaintenanceFormFields.currentMileage: maintenance.maintanceMileage
              .toString(),
          MaintenanceFormFields.distanceUnit: maintenance.distanceUnit,
          MaintenanceFormFields.receiveAlert: maintenance.receiveAlert,
          MaintenanceFormFields.nextMaintenanceMileage: maintenance
              .nextMaintenanceMileage
              ?.toString(),
          MaintenanceFormFields.vehicleId:
              maintenance.vehicleId ?? currentVehicleId,
        };
      },
      orElse: () => {
        MaintenanceFormFields.date: DateTime.now(),
        MaintenanceFormFields.distanceUnit: DistanceUnit.kilometers,
        MaintenanceFormFields.type: MaintenanceType.oilChange,
        MaintenanceFormFields.receiveAlert: false,
        MaintenanceFormFields.vehicleId:
            preselectedVehicleId ?? currentVehicleId,
      },
    );
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

  Future<void> _showVehicleSelectionDialog() async {
    final vehicleListCubit = context.read<VehicleListCubit>();
    final vehicles = vehicleListCubit.activeVehicles;

    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(VehicleStrings.noVehiclesAvailable),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedVehicle = await VehicleSelectionBottomSheet.show(
      context: context,
      vehicles: vehicles,
      selectedVehicleId: _selectedVehicle?.id,
    );

    if (selectedVehicle != null && mounted) {
      setState(() {
        _selectedVehicle = selectedVehicle;
      });

      // Update form field
      context
          .read<MaintenanceFormCubit>()
          .formKey
          .currentState
          ?.fields[MaintenanceFormFields.vehicleId]
          ?.didChange(selectedVehicle.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MaintenanceFormCubit>();
    final currentVehicle = _selectedVehicle;
    final currentMileage = currentVehicle?.currentMileage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del mantenimiento
            AppTextField(
              name: MaintenanceFormFields.name,
              labelText: MaintenanceStrings.maintenanceName,
              isRequired: true,
              prefixIcon: Icons.build,
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
            const SizedBox(height: 16),

            // Tipo de mantenimiento
            AppDropdown<MaintenanceType>(
              name: MaintenanceFormFields.type,
              labelText: MaintenanceStrings.maintenanceType,
              validator: FormBuilderValidators.required(
                errorText: MaintenanceStrings.typeRequired,
              ),
              prefixIcon: const Icon(Icons.category),
              items: MaintenanceType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Vehículo asociado
            if (currentVehicle != null) ...[
              SelectedVehicleCard(
                vehicle: currentVehicle,
                onTap: _showVehicleSelectionDialog,
              ),
              FormBuilderField<String>(
                name: MaintenanceFormFields.vehicleId,
                builder: (field) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
            ],

            // Fecha
            AppDatePicker(
              fieldName: MaintenanceFormFields.date,
              lastDate: DateTime.now(),
              labelText: MaintenanceStrings.maintenanceDateLabel,
              isRequired: true,
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            const SizedBox(height: 16),

            MileagesAndUnitFields(
              validatorsType: MileageValidatorsType.currentMileage,
              distanceUnitFieldName: MaintenanceFormFields.distanceUnit,
              mileageFieldName: MaintenanceFormFields.currentMileage,
            ),

            const SizedBox(height: 16),

            // Notas
            AppTextField(
              name: MaintenanceFormFields.notes,
              labelText: MaintenanceStrings.maintenanceNotes,
              prefixIcon: Icons.notes,
              maxLines: 4,
              minLines: 1,
            ),
            const SizedBox(height: 16),

            // Fecha del próximo mantenimiento
            AppDatePicker(
              fieldName: MaintenanceFormFields.nextMaintenanceDate,
              labelText: MaintenanceStrings.nextMaintenanceDate,
              firstDate: DateTime.now(),
            ),

            const SizedBox(height: 16),

            // Kilometraje del próximo mantenimiento
            NextMaintenanceMileageField(
              currentMileage: currentMileage,
              onValidationChanged: (_) {},
            ),
            const SizedBox(height: 16),

            // Recibir alerta
            AppCheckbox(
              name: MaintenanceFormFields.receiveAlert,
              title: MaintenanceStrings.receiveMaintenanceAlert,
              initialValue: false,
            ),
            const SizedBox(height: 24),

            // Save button
            SaveMaintenanceButton(onSave: _saveMaintenance),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
