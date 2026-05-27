import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_content.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_progress_bars.dart';

class MaintenanceFormView extends StatelessWidget {
  final MaintenanceType selectedType;
  final VoidCallback onChangeType;

  const MaintenanceFormView({
    super.key,
    required this.selectedType,
    required this.onChangeType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
      builder: (context, state) {
        final isLoading = state is Loading;
        return Scaffold(
          backgroundColor: AppColors.darkBgPrimary,
          appBar: AppFormNavHeader(
            title: context.l10n.maintenance_form_new_title,
            height: 52,
            leading: AppFormNavAction.icon(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onChangeType,
              pill: true,
            ),
            trailing: AppFormNavAction.pillText(
              label: context.l10n.maintenance_form_save_done.split(' ').first,
              onTap: () {}, // Save is triggered from the bottom CTA bar
              isLoading: isLoading,
            ),
            bottom: const MaintenanceFormProgressBars(),
          ),
          body: MaintenanceFormContent(
            selectedType: selectedType,
            onChangeType: onChangeType,
          ),
        );
      },
    );
  }
}
