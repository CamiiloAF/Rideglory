import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/event.dart';
import 'package:rideglory/features/events/domain/event_difficulty.dart';
import 'package:rideglory/features/events/domain/event_state.dart';
import 'package:rideglory/features/events/domain/usecases/get_my_events_use_case.dart';
import 'package:rideglory/features/events/domain/usecases/get_upcoming_events_use_case.dart';
import 'package:rideglory/features/events/presentation/cubit/events_list_cubit.dart';
import 'package:rideglory/features/events/presentation/cubit/events_list_state.dart';

class _MockGetUpcoming extends Mock implements GetUpcomingEventsUseCase {}

class _MockGetMine extends Mock implements GetMyEventsUseCase {}

void main() {
  late _MockGetUpcoming getUpcoming;
  late _MockGetMine getMine;

  final event = Event(
    id: 'e1',
    ownerId: 'owner-1',
    ownerName: 'Camilo',
    name: 'Rodada al Nevado',
    startAt: DateTime(2026, 9, 20, 6),
    difficulty: EventDifficulty.medium,
    state: EventState.published,
    price: 0,
    approvedCount: 3,
  );

  setUp(() {
    getUpcoming = _MockGetUpcoming();
    getMine = _MockGetMine();
  });

  EventsListCubit buildCubit() => EventsListCubit(getUpcoming, getMine);

  blocTest<EventsListCubit, EventsListState>(
    'load() populates both segments independently',
    build: () {
      when(() => getUpcoming()).thenAnswer((_) async => Right([event]));
      when(() => getMine()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.upcoming, ResultState.data(data: [event]));
      expect(cubit.state.mine, const ResultState.data(data: <Event>[]));
      expect(cubit.state.items, [event]);
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  blocTest<EventsListCubit, EventsListState>(
    'selectSegment switches which result state is current',
    build: () {
      when(() => getUpcoming()).thenAnswer((_) async => Right([event]));
      when(() => getMine()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      cubit.selectSegment(EventsSegment.mine);
    },
    verify: (cubit) {
      expect(cubit.state.segment, EventsSegment.mine);
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  blocTest<EventsListCubit, EventsListState>(
    'load() surfaces an error for the upcoming segment on failure',
    build: () {
      when(() => getUpcoming()).thenAnswer(
        (_) async => const Left(DomainException(message: 'unknown_error')),
      );
      when(() => getMine()).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.hasError, isTrue);
    },
  );
}
