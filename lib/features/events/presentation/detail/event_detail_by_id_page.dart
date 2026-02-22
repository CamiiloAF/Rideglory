import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
import 'package:rideglory/features/events/presentation/detail/event_detail_page.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

class _EventDetailByIdCubit extends Cubit<ResultState<EventModel>> {
  _EventDetailByIdCubit(this._getEventByIdUseCase)
    : super(const ResultState.initial());

  final GetEventByIdUseCase _getEventByIdUseCase;

  Future<void> loadEvent(String eventId) async {
    emit(const ResultState.loading());
    final result = await _getEventByIdUseCase(eventId);
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (event) => emit(ResultState.data(data: event)),
    );
  }
}

class EventDetailByIdPage extends StatelessWidget {
  final String eventId;

  const EventDetailByIdPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          _EventDetailByIdCubit(getIt<GetEventByIdUseCase>())
            ..loadEvent(eventId),
      child: BlocBuilder<_EventDetailByIdCubit, ResultState<EventModel>>(
        builder: (context, state) {
          return state.when(
            initial: () => _shell(context, const SizedBox.shrink()),
            loading: () => _shell(
              context,
              const Center(child: CircularProgressIndicator()),
            ),
            data: (event) => EventDetailPage(event: event),
            empty: () => _shell(
              context,
              Center(
                child: Text(
                  RegistrationStrings.errorLoadingEvent,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            error: (error) => _shell(
              context,
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      RegistrationStrings.errorLoadingEvent,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<_EventDetailByIdCubit>()
                          .loadEvent(eventId),
                      child: const Text(AppStrings.retry),
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

  Widget _shell(BuildContext context, Widget body) {
    return Scaffold(
      appBar: const AppAppBar(title: EventStrings.eventDetail),
      body: body,
    );
  }
}
