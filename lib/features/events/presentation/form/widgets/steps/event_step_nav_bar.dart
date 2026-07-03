import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/navigation_row.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/publish_row.dart';

/// Bottom navigation bar for the multi-step event creation wizard.
///
/// - Steps 1–3: "Atrás" (hidden on step 0) + "Continuar" (validates step before advancing)
/// - Step 4: "Publicar evento" [AppButton] + "Guardar borrador" [AppTextButton]
class EventStepNavBar extends StatelessWidget {
  const EventStepNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      builder: (context, state) {
        final cubit = context.read<EventFormCubit>();
        final isSaving = state.saveResult is Loading<EventModel>;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBgPrimary,
            border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
          ),
          padding: EdgeInsets.fromLTRB(20, 10, 20, max(16.0, bottomPadding)),
          child: state.currentStep < 3
              ? NavigationRow(
                  currentStep: state.currentStep,
                  isSaving: isSaving,
                  cubit: cubit,
                )
              : PublishRow(isSaving: isSaving, cubit: cubit),
        );
      },
    );
  }
}
