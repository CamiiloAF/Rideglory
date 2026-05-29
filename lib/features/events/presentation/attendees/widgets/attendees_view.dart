import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_data_view.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class AttendeesView extends StatefulWidget {
  final EventModel event;

  const AttendeesView({super.key, required this.event});

  @override
  State<AttendeesView> createState() => _AttendeesViewState();
}

class _AttendeesViewState extends State<AttendeesView> {
  StreamSubscription<DomainException>? _actionErrorSubscription;

  @override
  void initState() {
    super.initState();
    _actionErrorSubscription = context
        .read<AttendeesCubit>()
        .actionErrors
        .listen(_showActionError);
  }

  @override
  void dispose() {
    _actionErrorSubscription?.cancel();
    super.dispose();
  }

  void _showActionError(DomainException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: AppColors.error),
    );
  }

  EventModel get event => widget.event;

  int _pendingCount(List<EventRegistrationModel> registrations) {
    return registrations
        .where(
          (registration) =>
              registration.userId != event.ownerId &&
              (registration.status == RegistrationStatus.pending ||
                  registration.status == RegistrationStatus.readyForEdit),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title:
            BlocBuilder<
              AttendeesCubit,
              ResultState<List<EventRegistrationModel>>
            >(
              builder: (context, state) {
                final pendingCount = state.maybeWhen(
                  data: (registrations) => _pendingCount(registrations),
                  orElse: () => 0,
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.event_manageAttendeesTitle,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      AppSpacing.hGapSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: AppColors.darkBgPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
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
      body:
          BlocBuilder<
            AttendeesCubit,
            ResultState<List<EventRegistrationModel>>
          >(
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
                            border: Border.all(
                              color: AppColors.darkBorderPrimary,
                            ),
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
