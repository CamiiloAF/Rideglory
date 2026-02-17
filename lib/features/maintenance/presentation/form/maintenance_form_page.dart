import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/change_vehicle_mileage_bottom_sheet.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_checkbox.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/form/mileages_and_unit_fields.dart';

class MaintenanceFormPage extends StatelessWidget {
  final MaintenanceModel? maintenance;
  final VehicleModel? preselectedVehicle;

  const MaintenanceFormPage({
    super.key,
    this.maintenance,
    this.preselectedVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceFormCubit>()
        ..initialize(
          maintenance: maintenance,
          preselectedVehicle: preselectedVehicle,
        ),
      child: const _MaintenanceFormView(),
    );
  }
}

class _MaintenanceFormView extends StatefulWidget {
  const _MaintenanceFormView();

  @override
  State<_MaintenanceFormView> createState() => _MaintenanceFormViewState();
}

class _MaintenanceFormViewState extends State<_MaintenanceFormView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Mantenimiento'),
      body: BlocListener<MaintenanceFormCubit, MaintenanceFormState>(
        listener: (context, state) {
          state.whenOrNull(
            success: (maintenance) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mantenimiento guardado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(true);
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $message'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          );
        },
        child: const _MaintenanceFormContent(),
      ),
    );
  }
}

class _MaintenanceFormContent extends StatefulWidget {
  const _MaintenanceFormContent();

  @override
  State<_MaintenanceFormContent> createState() =>
      _MaintenanceFormContentState();
}

class _MaintenanceFormContentState extends State<_MaintenanceFormContent> {
  bool _shouldValidateNextMaintenanceMileage = false;
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
          'name': maintenance.name,
          'type': maintenance.type,
          'notes': maintenance.notes,
          'date': maintenance.date,
          'nextMaintenanceDate': maintenance.nextMaintenanceDate,
          'currentMileage': maintenance.maintanceMileage.toString(),
          'distanceUnit': maintenance.distanceUnit,
          'receiveAlert': maintenance.receiveAlert,
          'nextMaintenanceMileage': maintenance.nextMaintenanceMileage
              ?.toString(),
          'vehicleId': maintenance.vehicleId ?? currentVehicleId,
        };
      },
      orElse: () => {
        'date': DateTime.now(),
        'distanceUnit': DistanceUnit.kilometers,
        'type': MaintenanceType.oilChange,
        'receiveAlert': false,
        'vehicleId': preselectedVehicleId ?? currentVehicleId,
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
    final vehicleListState = context.read<VehicleListCubit>().state;

    if (vehicleListState is! Data<List<VehicleModel>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay vehículos disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final vehicles = vehicleListState.data;

    final selectedVehicle = await showModalBottomSheet<VehicleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Vehículo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elige el vehículo para este mantenimiento',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Vehicles list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final isSelected = vehicle.id == _selectedVehicle?.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(sheetContext, vehicle),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Vehicle icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : const Color(
                                            0xFF6366F1,
                                          ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    vehicle.vehicleType ==
                                            VehicleType.motorcycle
                                        ? Icons.two_wheeler_rounded
                                        : Icons.directions_car_rounded,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF6366F1),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Vehicle info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      if (vehicle.brand != null ||
                                          vehicle.model != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            vehicle.brand,
                                            vehicle.model,
                                          ].where((e) => e != null).join(' '),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected
                                                ? Colors.white.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Selection indicator
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 16),
          ],
        ),
      ),
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
          ?.fields['vehicleId']
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
              name: 'name',
              labelText: 'Nombre del mantenimiento',
              isRequired: true,
              prefixIcon: Icons.build,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: 'El nombre es requerido',
                ),
                FormBuilderValidators.minLength(
                  3,
                  errorText: 'Mínimo 3 caracteres',
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Tipo de mantenimiento
            AppDropdown<MaintenanceType>(
              name: 'type',
              labelText: 'Tipo de mantenimiento',
              validator: FormBuilderValidators.required(
                errorText: 'El tipo es requerido',
              ),
              prefixIcon: Icon(Icons.category),
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
              InkWell(
                onTap: _showVehicleSelectionDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.08),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          currentVehicle.vehicleType == VehicleType.motorcycle
                              ? Icons.two_wheeler_rounded
                              : Icons.directions_car_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Vehículo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentVehicle.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                                height: 1.2,
                              ),
                            ),
                            if (currentVehicle.brand != null ||
                                currentVehicle.model != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                [
                                  currentVehicle.brand,
                                  currentVehicle.model,
                                ].where((e) => e != null).join(' '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Color(0xFF6366F1),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FormBuilderField<String>(
                name: 'vehicleId',
                builder: (field) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
            ],

            // Fecha
            AppDatePicker(
              fieldName: 'date',
              lastDate: DateTime.now(),
              labelText: 'Fecha del mantenimiento',
              isRequired: true,
              prefixIcon: Icon(Icons.calendar_today),
            ),
            const SizedBox(height: 16),

            MileagesAndUnitFields(
              validatorsType: MileageValidatorsType.currentMileage,
              distanceUnitFieldName: 'distanceUnit',
              mileageFieldName: 'currentMileage',
            ),

            const SizedBox(height: 16),

            // Notas
            AppTextField(
              name: 'notes',
              labelText: 'Notas',
              prefixIcon: Icons.notes,
              maxLines: 4,
              minLines: 1,
            ),
            const SizedBox(height: 16),

            // Fecha del próximo mantenimiento
            AppDatePicker(
              fieldName: 'nextMaintenanceDate',
              labelText: 'Fecha del próximo mantenimiento',
              firstDate: DateTime.now(),
            ),

            const SizedBox(height: 16),

            // Kilometraje del próximo mantenimiento
            AppTextField(
              name: 'nextMaintenanceMileage',
              labelText: 'Kilometraje del próximo mantenimiento',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.speed,
              onChanged: (value) {
                setState(() {
                  _shouldValidateNextMaintenanceMileage =
                      value != null && value.isNotEmpty;
                });
              },
              validator: _shouldValidateNextMaintenanceMileage
                  ? FormBuilderValidators.compose([
                      FormBuilderValidators.numeric(
                        errorText: 'Debe ser un número',
                      ),
                      (value) {
                        if (value == null || value.isEmpty) return null;
                        final mileage = int.tryParse(value);
                        if (mileage != null &&
                            currentMileage != null &&
                            mileage <= currentMileage) {
                          return 'Debe ser mayor al kilometraje actual ($currentMileage)';
                        }
                        return null;
                      },
                    ])
                  : null,
            ),
            const SizedBox(height: 16),

            // Recibir alerta
            AppCheckbox(
              name: 'receiveAlert',
              title: 'Recibir alerta de mantenimiento',
              initialValue: false,
            ),
            const SizedBox(height: 24),

            // Save button
            BlocBuilder<MaintenanceFormCubit, MaintenanceFormState>(
              builder: (context, state) {
                final isLoading = state.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );
                return AppButton(
                  label: 'Guardar Mantenimiento',
                  icon: Icons.check_rounded,
                  variant: AppButtonVariant.primary,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _saveMaintenance,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
