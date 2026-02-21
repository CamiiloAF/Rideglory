import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_list.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

class AttendeesView extends StatelessWidget {
  final EventModel event;

  const AttendeesView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: EventStrings.attendees),
      body:
          BlocBuilder<
            AttendeesCubit,
            ResultState<List<EventRegistrationModel>>
          >(
            builder: (context, state) {
              return state.when(
                initial: () => const SizedBox.shrink(),
                loading: () => const Center(child: CircularProgressIndicator()),
                data: (registrations) =>
                    AttendeesList(registrations: registrations, event: event),
                empty: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        EventStrings.noAttendees,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                error: (error) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<AttendeesCubit>()
                            .fetchAttendees(event.id!),
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
