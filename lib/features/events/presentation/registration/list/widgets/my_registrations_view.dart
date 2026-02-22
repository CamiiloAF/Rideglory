import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/list/my_registrations_cubit.dart';
import 'package:rideglory/features/events/presentation/registration/list/widgets/registration_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';

class MyRegistrationsView extends StatelessWidget {
  const MyRegistrationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: RegistrationStrings.myRegistrations),
      drawer: const AppDrawer(currentRoute: AppRoutes.myRegistrations),
      body:
          BlocBuilder<
            MyRegistrationsCubit,
            ResultState<List<EventRegistrationModel>>
          >(
            builder: (context, state) {
              return state.when(
                initial: () => const SizedBox.shrink(),
                loading: () => const Center(child: CircularProgressIndicator()),
                data: (registrations) => RefreshIndicator(
                  onRefresh: () => context
                      .read<MyRegistrationsCubit>()
                      .fetchMyRegistrations(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: registrations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reg = registrations[index];
                      return RegistrationCard(
                        registration: reg,
                        onViewDetails: () => context.pushNamed(
                          AppRoutes.registrationDetail,
                          extra: (
                            reg,
                            reg.id != null
                                ? () async => context
                                      .read<MyRegistrationsCubit>()
                                      .cancelRegistration(reg.id!)
                                : null as Future<bool> Function()?,
                          ),
                        ),
                        onViewEvent: () => context.pushNamed(
                          AppRoutes.eventDetailById,
                          extra: reg.eventId,
                        ),
                      );
                    },
                  ),
                ),
                empty: () => EmptyStateWidget(
                  icon: Icons.event_busy_outlined,
                  title: RegistrationStrings.noRegistrations,
                  description: RegistrationStrings.noRegistrationsDescription,
                  actionButtonText: RegistrationStrings.goToEvents,
                  showButtonIcon: false,
                  onActionPressed: () => context.pushNamed(AppRoutes.events),
                  onRefresh: () => context
                      .read<MyRegistrationsCubit>()
                      .fetchMyRegistrations(),
                ),
                error: (error) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(RegistrationStrings.errorLoadingRegistrations),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<MyRegistrationsCubit>()
                            .fetchMyRegistrations(),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
