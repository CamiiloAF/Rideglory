import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_data_view.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MyRegistrationsView extends StatelessWidget {
  const MyRegistrationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppAppBar(title: context.l10n.registration_myRegistrations),
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
                      AppLoadingIndicator(variant: AppLoadingIndicatorVariant.page),
                  loading: () =>
                      AppLoadingIndicator(variant: AppLoadingIndicatorVariant.page),
                  data: (items) => MyRegistrationsDataView(items: items),
                  empty: () => EmptyStateWidget(
                    icon: Icons.event_busy_outlined,
                    title: context.l10n.registration_noRegistrations,
                    description: context.l10n.registration_noRegistrationsDescription,
                    actionButtonText: context.l10n.registration_goToEvents,
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
                          Text(
                            context.l10n.registration_errorLoadingRegistrations,
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.gapLg,
                          AppButton(
                            label: context.l10n.retry,
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
