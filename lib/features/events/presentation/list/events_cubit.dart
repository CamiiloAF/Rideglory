import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';

class EventFilters {
  final Set<EventType> types;
  final Set<EventDifficulty> difficulties;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool freeOnly;
  final bool multiBrandOnly;

  const EventFilters({
    this.types = const {},
    this.difficulties = const {},
    this.startDate,
    this.endDate,
    this.freeOnly = false,
    this.multiBrandOnly = false,
  });

  bool get hasFilters =>
      types.isNotEmpty ||
      difficulties.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      freeOnly ||
      multiBrandOnly;

  EventFilters copyWith({
    Set<EventType>? types,
    Set<EventDifficulty>? difficulties,
    DateTime? startDate,
    DateTime? endDate,
    bool? freeOnly,
    bool? multiBrandOnly,
  }) {
    return EventFilters(
      types: types ?? this.types,
      difficulties: difficulties ?? this.difficulties,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      freeOnly: freeOnly ?? this.freeOnly,
      multiBrandOnly: multiBrandOnly ?? this.multiBrandOnly,
    );
  }
}

class EventsCubit extends Cubit<ResultState<List<EventModel>>> {
  EventsCubit(
    GetEventsUseCase getEventsUseCase,
    this._updateEventUseCase,
    this._analytics,
  ) : _fetchFn = (({String? type, String? dateFrom, String? dateTo}) =>
            getEventsUseCase(
              type: type,
              dateFrom: dateFrom,
              dateTo: dateTo,
            )),
      _isMyEvents = false,
      super(const ResultState.initial());

  EventsCubit.myEvents(
    GetMyEventsUseCase getMyEventsUseCase,
    this._updateEventUseCase,
    this._analytics,
  ) : _fetchFn = (({String? type, String? dateFrom, String? dateTo}) =>
            getMyEventsUseCase()),
      _isMyEvents = true,
      super(const ResultState.initial());

  final Future<dynamic> Function({
    String? type,
    String? dateFrom,
    String? dateTo,
  }) _fetchFn;
  final UpdateEventUseCase _updateEventUseCase;
  final AnalyticsService _analytics;

  /// `true` cuando el cubit fue creado con [EventsCubit.myEvents].
  /// Alimenta el param `list_scope` del evento de analytics sin acoplarse al use case.
  final bool _isMyEvents;

  List<EventModel> _allEvents = [];
  EventFilters _filters = const EventFilters();
  String _searchQuery = '';

  EventFilters get filters => _filters;
  String get searchQuery => _searchQuery;

  Future<void> fetchEvents() async {
    emit(const ResultState.loading());
    final filters = _filters;
    final result = await _fetchFn(
      type: filters.types.isNotEmpty ? filters.types.first.apiValue : null,
      dateFrom: filters.startDate?.toIso8601String().substring(0, 10),
      dateTo: filters.endDate?.toIso8601String().substring(0, 10),
    );

    result.fold((error) => emit(ResultState.error(error: error)), (events) {
      _allEvents = events;
      _applyFiltersAndEmit();
      // Emitir AQUÍ (post-fetch real), nunca dentro de _applyFiltersAndEmit().
      // _applyFiltersAndEmit() se llama también en updateSearchQuery/addEvent/
      // updateEvent/removeEvent — emitir allí dispararía el evento en cada tecla
      // y cada mutación local (ver Fase 6, Riesgo #4).
      final filtered = state.maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );
      _analytics
          .logEvent(AnalyticsEvents.eventsListViewed, {
            AnalyticsParams.resultCount: filtered,
            AnalyticsParams.listScope:
                _isMyEvents
                    ? AnalyticsParams.listScopeMine
                    : AnalyticsParams.listScopeAll,
          })
          .ignore();
    });
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndEmit();
  }

  void updateFilters(EventFilters filters) {
    _filters = filters;
    fetchEvents();
  }

  void clearFilters() {
    _filters = const EventFilters();
    fetchEvents();
  }

  /// Adds a newly created event to the local list without re-fetching.
  void addEvent(EventModel event) {
    _allEvents = [event, ..._allEvents];
    _applyFiltersAndEmit();
  }

  /// Replaces an updated event in the local list without re-fetching.
  void updateEvent(EventModel event) {
    final index = _allEvents.indexWhere((e) => e.id == event.id);
    if (index == -1) return;
    _allEvents[index] = event;

    _applyFiltersAndEmit();
  }

  /// Removes a deleted event from the local list without re-fetching.
  void removeEvent(String eventId) {
    _allEvents = _allEvents.where((e) => e.id != eventId).toList();
    if (_allEvents.isEmpty) {
      emit(const ResultState.empty());
    } else {
      _applyFiltersAndEmit();
    }
  }

  Future<void> startEvent(EventModel event) async {
    final id = event.id;
    if (id == null || id.isEmpty || event.state != EventState.scheduled) {
      return;
    }
    final result = await _updateEventUseCase(
      event.copyWith(state: EventState.inProgress),
    );
    result.fold((_) {}, (savedEvent) => updateEvent(savedEvent));
  }

  void _applyFiltersAndEmit() {
    emit(const ResultState.initial());

    var filtered = List<EventModel>.from(_allEvents);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) => e.name.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    if (_filters.types.isNotEmpty) {
      filtered = filtered
          .where((e) => _filters.types.contains(e.eventType))
          .toList();
    }

    if (_filters.difficulties.isNotEmpty) {
      filtered = filtered
          .where((e) => _filters.difficulties.contains(e.difficulty))
          .toList();
    }

    if (_filters.startDate != null) {
      filtered = filtered
          .where((e) => !e.startDate.isBefore(_filters.startDate!))
          .toList();
    }

    if (_filters.endDate != null) {
      filtered = filtered
          .where(
            (e) => e.startDate.isBefore(
              _filters.endDate!.add(const Duration(days: 1)),
            ),
          )
          .toList();
    }

    if (_filters.freeOnly) {
      filtered = filtered.where((e) => e.isFree).toList();
    }

    if (_filters.multiBrandOnly) {
      filtered = filtered.where((e) => e.isMultiBrand).toList();
    }

    if (_allEvents.isEmpty) {
      emit(const ResultState.empty());
    } else {
      emit(ResultState.data(data: filtered));
    }
  }
}
