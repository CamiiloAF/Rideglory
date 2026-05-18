import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_view.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_type_selection.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenanceFormPage extends StatefulWidget {
  final MaintenanceModel? maintenance;
  final VehicleModel? preselectedVehicle;

  const MaintenanceFormPage({
    super.key,
    this.maintenance,
    this.preselectedVehicle,
  });

  @override
  State<MaintenanceFormPage> createState() => _MaintenanceFormPageState();
}

class _MaintenanceFormPageState extends State<MaintenanceFormPage> {
  late final MaintenanceFormCubit _cubit;
  MaintenanceType? _selectedType;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<MaintenanceFormCubit>()
      ..initialize(
        maintenance: widget.maintenance,
        preselectedVehicle: widget.preselectedVehicle,
      );
    if (widget.maintenance != null) {
      _selectedType = widget.maintenance!.type;
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
        listener: (context, state) {
          state.whenOrNull(
            data: (maintenance) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.savedSuccessfully),
                  backgroundColor: AppColors.success,
                ),
              );
              // Pop with the full list of saved records (1 or 2 for auto-created scheduled)
              final saved = _cubit.lastSavedRecords ?? [maintenance];
              Navigator.of(context).pop(saved);
            },
            error: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.errorMessage(error.message)),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          );
        },
        child: _selectedType == null
            ? MaintenanceTypeSelection(
                onContinue: (type) {
                  _cubit.updateSelectedType(type);
                  setState(() => _selectedType = type);
                },
                onBack: () => Navigator.of(context).pop(),
              )
            : MaintenanceFormView(
                selectedType: _selectedType!,
                onChangeType: () => setState(() => _selectedType = null),
              ),
      ),
    );
  }
}
