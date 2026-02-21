import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/list/my_registrations_cubit.dart';
import 'package:rideglory/features/events/presentation/registration/list/widgets/registration_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';

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
                    itemBuilder: (context, index) =>
                        RegistrationCard(registration: registrations[index]),
                  ),
                ),
                empty: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        RegistrationStrings.noRegistrations,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        RegistrationStrings.noRegistrationsDescription,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => context.pushNamed(AppRoutes.events),
                        child: const Text(EventStrings.events),
                      ),
                    ],
                  ),
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
                        child: const Text(EventStrings.retry),
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
