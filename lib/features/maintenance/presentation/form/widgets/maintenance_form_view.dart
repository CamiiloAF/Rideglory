import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_content.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenanceFormView extends StatefulWidget {
  const MaintenanceFormView({super.key});

  @override
  State<MaintenanceFormView> createState() => _MaintenanceFormViewState();
}

class _MaintenanceFormViewState extends State<MaintenanceFormView> {
  @override
  Widget build(BuildContext context) {
    final isEditing = context.select(
      (MaintenanceFormCubit cubit) => cubit.isEditing,
    );

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppAppBar(
        title: isEditing
            ? context.l10n.maintenance_editRecord
            : context.l10n.maintenance_newRecord,
      ),
      body: BlocListener<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
        listener: (context, state) {
          state.whenOrNull(
            data: (maintenance) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.savedSuccessfully),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(maintenance);
            },
            error: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.errorMessage(error.message)),
                  backgroundColor: Colors.red,
                ),
              );
            },
          );
        },
        child: const MaintenanceFormContent(),
      ),
    );
  }
}
