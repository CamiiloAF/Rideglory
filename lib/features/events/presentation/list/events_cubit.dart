import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';

class EventFilters {
  final Set<EventType> types;
  final Set<EventDifficulty> difficulties;
  final String? city;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool freeOnly;
  final bool multiBrandOnly;

  const EventFilters({
    this.types = const {},
    this.difficulties = const {},
    this.city,
    this.startDate,
    this.endDate,
    this.freeOnly = false,
    this.multiBrandOnly = false,
  });

  bool get hasFilters =>
      types.isNotEmpty ||
      difficulties.isNotEmpty ||
      city != null ||
      startDate != null ||
      endDate != null ||
      freeOnly ||
      multiBrandOnly;

  EventFilters copyWith({
    Set<EventType>? types,
    Set<EventDifficulty>? difficulties,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    bool? freeOnly,
    bool? multiBrandOnly,
  }) {
    return EventFilters(
      types: types ?? this.types,
      difficulties: difficulties ?? this.difficulties,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      freeOnly: freeOnly ?? this.freeOnly,
      multiBrandOnly: multiBrandOnly ?? this.multiBrandOnly,
    );
  }
}

class EventsCubit extends Cubit<ResultState<List<EventModel>>> {
  EventsCubit(GetEventsUseCase getEventsUseCase)
    : _fetchFn = getEventsUseCase.call,
      super(const ResultState.initial());

  EventsCubit.myEvents(GetMyEventsUseCase getMyEventsUseCase)
    : _fetchFn = getMyEventsUseCase.call,
      super(const ResultState.initial());

  final Future<dynamic> Function() _fetchFn;

  List<EventModel> _allEvents = [];
  EventFilters _filters = const EventFilters();
  String _searchQuery = '';

  EventFilters get filters => _filters;
  String get searchQuery => _searchQuery;

  Future<void> fetchEvents() async {
    emit(const ResultState.loading());
    final result = await _fetchFn();

    result.fold((error) => emit(ResultState.error(error: error)), (events) {
      _allEvents = events;
      _applyFiltersAndEmit();
    });
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndEmit();
  }

  void updateFilters(EventFilters filters) {
    _filters = filters;
    _applyFiltersAndEmit();
  }

  void clearFilters() {
    _filters = const EventFilters();
    _applyFiltersAndEmit();
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

  void _applyFiltersAndEmit() {
    emit(const ResultState.initial());

    var filtered = List<EventModel>.from(_allEvents);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) =>
                e.name.toLowerCase().contains(_searchQuery) ||
                e.city.toLowerCase().contains(_searchQuery),
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

    if (_filters.city != null && _filters.city!.isNotEmpty) {
      filtered = filtered
          .where(
            (e) => e.city.toLowerCase().contains(_filters.city!.toLowerCase()),
          )
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
