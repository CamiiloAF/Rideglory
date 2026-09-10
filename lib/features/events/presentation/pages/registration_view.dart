import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_page_header.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/saving_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../cubit/registration_cubit.dart';
import '../cubit/registration_state.dart';
import '../event_error_translator.dart';
import '../widgets/registration_form.dart';
import '../widgets/registration_incomplete_view.dart';
import '../../../../core/domain/result_state.dart';

/// EV4: cuerpo de la pantalla de inscripción.
class RegistrationView extends StatelessWidget {
  const RegistrationView({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    return BlocListener<RegistrationCubit, RegistrationState>(
      listenWhen: (previous, current) =>
          previous.submission != current.submission,
      listener: (context, state) {
        state.submission.whenOrNull(
          data: (_) => Navigator.of(context).pop(true),
          error: (error) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(eventErrorMessage(context, error))),
          ),
        );
      },
      child: Scaffold(
        appBar: AppPageHeader(title: context.l10n.events_register_title),
        body: SafeArea(
          top: false,
          child: BlocBuilder<RegistrationCubit, RegistrationState>(
            builder: (context, state) {
              final profileState = state.profile;
              final vehiclesState = state.vehicles;
              final isLoading =
                  profileState.maybeWhen(
                    loading: () => true,
                    initial: () => true,
                    orElse: () => false,
                  ) ||
                  vehiclesState.maybeWhen(
                    loading: () => true,
                    initial: () => true,
                    orElse: () => false,
                  );
              if (isLoading) return const SkeletonList();

              final hasError =
                  profileState.maybeWhen(
                    error: (_) => true,
                    orElse: () => false,
                  ) ||
                  vehiclesState.maybeWhen(
                    error: (_) => true,
                    orElse: () => false,
                  );
              if (hasError) {
                return ErrorStateView(onRetry: cubit.load);
              }

              if (!state.isProfileComplete) {
                return const RegistrationIncompleteView();
              }

              final profile = profileState.whenOrNull(
                data: (profile) => profile,
              )!;
              final vehicles =
                  vehiclesState.whenOrNull(data: (vehicles) => vehicles) ??
                  const [];

              return Column(
                children: [
                  Expanded(
                    child: RegistrationForm(
                      profile: profile,
                      vehicles: vehicles,
                      selectedVehicleId: state.selectedVehicleId,
                      onVehicleSelected: cubit.selectVehicle,
                      shareMedicalInfo: state.shareMedicalInfo,
                      onShareMedicalInfoChanged: cubit.toggleShareMedicalInfo,
                      allowOrganizerContact: state.allowOrganizerContact,
                      onAllowOrganizerContactChanged:
                          cubit.toggleAllowOrganizerContact,
                      acceptsRisk: state.acceptsRisk,
                      onAcceptsRiskChanged: cubit.toggleAcceptsRisk,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: state.isSubmitting
                        ? SavingButton(label: context.l10n.events_create_saving)
                        : AppPrimaryButton(
                            label: context.l10n.events_register_confirm_cta,
                            onPressed: state.canSubmit
                                ? () => cubit.submit(eventId)
                                : null,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
