import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_content.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

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
            ? MaintenanceStrings.editRecord
            : MaintenanceStrings.newRecord,
      ),
      body: BlocListener<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
        listener: (context, state) {
          state.whenOrNull(
            data: (maintenance) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.savedSuccessfully),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(maintenance);
            },
            error: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.errorMessage(error.message)),
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
