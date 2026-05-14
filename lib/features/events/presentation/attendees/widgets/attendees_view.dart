import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_data_view.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class AttendeesView extends StatelessWidget {
  final EventModel event;

  const AttendeesView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.event_manageAttendeesTitle,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textOnDarkPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<AttendeesCubit, ResultState<List<EventRegistrationModel>>>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.page,
            ),
            data: (registrations) => AttendeesDataView(
              registrations: registrations,
              event: event,
            ),
            empty: () => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.darkBorderPrimary),
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 36,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                    AppSpacing.gapXxl,
                    Text(
                      context.l10n.event_noAttendees,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      context.l10n.event_attendeesCount,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    AppSpacing.gapLg,
                    Text(
                      error.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    AppSpacing.gapLg,
                    AppButton(
                      label: context.l10n.retry,
                      onPressed: () => context
                          .read<AttendeesCubit>()
                          .fetchAttendees(event.id!),
                      isFullWidth: false,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
