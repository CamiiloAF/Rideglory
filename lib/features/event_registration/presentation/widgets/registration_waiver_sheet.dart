import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_waiver_error.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_step_header.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// Opens the risk-waiver acceptance sheet as the final registration gate.
///
/// The sheet reuses the caller's [RegistrationFormCubit] (via [BlocProvider.value]
/// because a modal route does not inherit the page's providers). It resolves to
/// the saved [EventRegistrationModel] when the rider accepts and the submission
/// succeeds, or to null if they cancel/dismiss.
Future<EventRegistrationModel?> showRegistrationWaiverSheet({
  required BuildContext context,
  required EventModel event,
}) {
  final cubit = context.read<RegistrationFormCubit>();
  return showModalBottomSheet<EventRegistrationModel>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: RegistrationWaiverSheet(event: event),
    ),
  );
}

/// Risk-waiver acceptance sheet: organizer name (when available), a scrollable
/// legal text, an inline error block that differentiates local/underage/server
/// errors, and the final accept/cancel actions. Accepting submits the whole
/// registration; a successful submission pops the sheet with the saved model.
class RegistrationWaiverSheet extends StatelessWidget {
  const RegistrationWaiverSheet({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BlocConsumer<
      RegistrationFormCubit,
      ResultState<EventRegistrationModel>
    >(
      listener: (context, state) {
        state.whenOrNull(
          data: (registration) => Navigator.of(context).pop(registration),
        );
      },
      builder: (context, state) {
        final isLoading = state is Loading;
        final errorOrNull = state.mapOrNull(error: (e) => e.error);
        final isUnderage =
            errorOrNull != null &&
            (errorOrNull.message ==
                    RegistrationFormCubit.underageErrorMessage ||
                errorOrNull.message.contains('UNDERAGE_RIDER'));

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RegistrationStepHeader(
                        icon: Icons.gavel_outlined,
                        title: context.l10n.registration_waiverTitle,
                        subtitle: context.l10n.registration_waiverSubtitle,
                      ),
                      AppSpacing.gapLg,
                      if (event.ownerName != null) ...[
                        Text(
                          event.ownerName!,
                          style: const TextStyle(
                            color: AppColors.textOnDarkPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.gapSm,
                      ],
                      Text(
                        context.l10n.registration_waiverBodyV0,
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (errorOrNull != null) ...[
                        AppSpacing.gapMd,
                        RegistrationWaiverError(
                          isUnderage: isUnderage,
                          message: errorOrNull.message,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: context.l10n.registration_waiverCtaButton,
                      onPressed: isLoading
                          ? null
                          : () => context
                                .read<RegistrationFormCubit>()
                                .saveRegistration(),
                      isLoading: isLoading,
                      shape: AppButtonShape.pill,
                      height: 52,
                    ),
                    AppSpacing.gapSm,
                    AppButton(
                      label: context.l10n.registration_waiverCancelButton,
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: AppButtonStyle.outlined,
                      shape: AppButtonShape.pill,
                      height: 52,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
