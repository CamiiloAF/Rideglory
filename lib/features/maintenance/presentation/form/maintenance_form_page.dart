import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/change_vehicle_mileage_dialog.dart';
import 'package:rideglory/shared/widgets/app_button.dart';

class MaintenanceFormPage extends StatelessWidget {
  final MaintenanceModel? maintenance;

  const MaintenanceFormPage({super.key, this.maintenance});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<MaintenanceFormCubit>()..initialize(maintenance: maintenance),
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
      appBar: AppBar(title: const Text('Mantenimiento')),
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
  DistanceUnit _selectedDistanceUnit = DistanceUnit.kilometers;
  bool _shouldValidateNextMaintenanceMileage = false;

  Map<String, dynamic> _getInitialValues() {
    final state = context.read<MaintenanceFormCubit>().state;

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
        };
      },
      orElse: () => {
        'date': DateTime.now(),
        'distanceUnit': DistanceUnit.kilometers,
        'receiveAlert': false,
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
    showDialog(
      context: context,
      builder: (dialogContext) => ChangeVehicleMileageDialog(
        context: context,
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
    final currentMileage = context.read<VehicleCubit>().currentMileage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del mantenimiento
            FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(
                labelText: 'Nombre del mantenimiento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
              ),
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
            FormBuilderDropdown<MaintenanceType>(
              name: 'type',
              decoration: const InputDecoration(
                labelText: 'Tipo de mantenimiento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              validator: FormBuilderValidators.required(
                errorText: 'El tipo es requerido',
              ),
              items: MaintenanceType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Fecha
            FormBuilderDateTimePicker(
              name: 'date',
              inputType: InputType.date,
              lastDate: DateTime.now(),
              decoration: const InputDecoration(
                labelText: 'Fecha del mantenimiento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              validator: FormBuilderValidators.required(
                errorText: 'La fecha es requerida',
              ),
            ),
            const SizedBox(height: 16),

            // Kilometraje actual y unidad
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FormBuilderTextField(
                    name: 'currentMileage',
                    initialValue: currentMileage?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Kilometraje actual',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'El kilometraje es requerido',
                      ),
                      FormBuilderValidators.numeric(
                        errorText: 'Debe ser un número',
                      ),
                      FormBuilderValidators.min(
                        0,
                        errorText: 'Debe ser mayor a 0',
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderDropdown<DistanceUnit>(
                    name: 'distanceUnit',
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedDistanceUnit,
                    items: DistanceUnit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDistanceUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notas
            FormBuilderTextField(
              name: 'notes',
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 1,
            ),
            const SizedBox(height: 16),

            // Fecha del próximo mantenimiento
            FormBuilderDateTimePicker(
              name: 'nextMaintenanceDate',
              inputType: InputType.date,
              firstDate: DateTime.now(),
              decoration: const InputDecoration(
                labelText: 'Fecha del próximo mantenimiento (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
            ),
            const SizedBox(height: 16),

            // Kilometraje del próximo mantenimiento
            FormBuilderTextField(
              name: 'nextMaintenanceMileage',
              decoration: InputDecoration(
                labelText:
                    'Kilometraje del próximo mantenimiento (${_selectedDistanceUnit.label})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.timeline),
              ),
              keyboardType: TextInputType.number,
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
            FormBuilderCheckbox(
              name: 'receiveAlert',
              title: const Text('Recibir alerta de mantenimiento'),
              initialValue: false,
              decoration: const InputDecoration(border: InputBorder.none),
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
