import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/use_cases/delete_event_use_case.dart';

@injectable
class EventDeleteCubit extends Cubit<ResultState<String>> {
  EventDeleteCubit(this._deleteEventUseCase, this._analytics)
    : super(const ResultState.initial());

  final DeleteEventUseCase _deleteEventUseCase;
  final AnalyticsService _analytics;

  Future<void> deleteEvent(String eventId) async {
    emit(const ResultState.loading());

    _analytics.logEvent(AnalyticsEvents.eventsDeleteAttempted).ignore();

    final result = await _deleteEventUseCase(eventId);

    result.fold(
      (error) {
        _analytics.logEvent(AnalyticsEvents.eventsDeleteFailed, {
          AnalyticsParams.failureCategory: _categorizeFailure(error),
        }).ignore();
        emit(ResultState.error(error: error));
      },
      (_) {
        _analytics.logEvent(AnalyticsEvents.eventsDeleteSucceeded).ignore();
        emit(ResultState.data(data: eventId));
      },
    );
  }

  String _categorizeFailure(DomainException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('socket')) {
      return AnalyticsParams.failureCategoryNetwork;
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return AnalyticsParams.failureCategoryNotFound;
    }
    if (msg.contains('valid') || msg.contains('required')) {
      return AnalyticsParams.failureCategoryValidation;
    }
    return AnalyticsParams.failureCategoryUnknown;
  }
}
