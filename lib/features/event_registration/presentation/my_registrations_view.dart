import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/constants/registration_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_data_view.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';

class MyRegistrationsView extends StatelessWidget {
  const MyRegistrationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: const AppAppBar(title: RegistrationStrings.myRegistrations),
      body: SafeArea(
        child:
            BlocBuilder<
              MyRegistrationsCubit,
              ResultState<List<RegistrationWithEvent>>
            >(
              builder: (context, state) {
                final cubit = context.read<MyRegistrationsCubit>();
                return state.when(
                  initial: () =>
                      Center(child: CircularProgressIndicator()),
                  loading: () =>
                      Center(child: CircularProgressIndicator()),
                  data: (items) => MyRegistrationsDataView(items: items),
                  empty: () => EmptyStateWidget(
                    icon: Icons.event_busy_outlined,
                    title: RegistrationStrings.noRegistrations,
                    description: RegistrationStrings.noRegistrationsDescription,
                    actionButtonText: RegistrationStrings.goToEvents,
                    showButtonIcon: false,
                    onActionPressed: () => context.pushNamed(AppRoutes.events),
                    onRefresh: () => cubit.fetchMyRegistrations(),
                  ),
                  error: (error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            RegistrationStrings.errorLoadingRegistrations,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          AppButton(
                            label: AppStrings.retry,
                            onPressed: () => cubit.fetchMyRegistrations(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
