import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/event.dart';
import 'package:rideglory/features/events/domain/event_difficulty.dart';
import 'package:rideglory/features/events/domain/event_state.dart';
import 'package:rideglory/features/events/domain/usecases/add_route_change_use_case.dart';
import 'package:rideglory/features/events/domain/usecases/cancel_event_use_case.dart';
import 'package:rideglory/features/events/domain/usecases/cancel_my_registration_use_case.dart';
import 'package:rideglory/features/events/domain/usecases/get_event_detail_use_case.dart';
import 'package:rideglory/features/events/domain/usecases/get_route_changes_use_case.dart';
import 'package:rideglory/features/events/domain/usecases/start_event_use_case.dart';
import 'package:rideglory/features/events/presentation/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/cubit/event_detail_state.dart';

class _MockGetDetail extends Mock implements GetEventDetailUseCase {}

class _MockGetRouteChanges extends Mock implements GetRouteChangesUseCase {}

class _MockCancelMyRegistration extends Mock
    implements CancelMyRegistrationUseCase {}

class _MockStartEvent extends Mock implements StartEventUseCase {}

class _MockCancelEvent extends Mock implements CancelEventUseCase {}

class _MockAddRouteChange extends Mock implements AddRouteChangeUseCase {}

void main() {
  late _MockGetDetail getDetail;
  late _MockGetRouteChanges getRouteChanges;
  late _MockCancelMyRegistration cancelMyRegistration;
  late _MockStartEvent startEvent;
  late _MockCancelEvent cancelEvent;
  late _MockAddRouteChange addRouteChange;

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
    getDetail = _MockGetDetail();
    getRouteChanges = _MockGetRouteChanges();
    cancelMyRegistration = _MockCancelMyRegistration();
    startEvent = _MockStartEvent();
    cancelEvent = _MockCancelEvent();
    addRouteChange = _MockAddRouteChange();
  });

  EventDetailCubit buildCubit() => EventDetailCubit(
    getDetail,
    getRouteChanges,
    cancelMyRegistration,
    startEvent,
    cancelEvent,
    addRouteChange,
  );

  blocTest<EventDetailCubit, EventDetailState>(
    'load() populates the event and its route changes',
    build: () {
      when(() => getDetail('e1')).thenAnswer((_) async => Right(event));
      when(
        () => getRouteChanges('e1'),
      ).thenAnswer((_) async => const Right([]));
      return buildCubit();
    },
    act: (cubit) => cubit.load('e1'),
    verify: (cubit) {
      expect(cubit.state.event, ResultState.data(data: event));
    },
  );

  blocTest<EventDetailCubit, EventDetailState>(
    'startEvent() reloads the detail after a successful call',
    build: () {
      when(() => getDetail('e1')).thenAnswer((_) async => Right(event));
      when(
        () => getRouteChanges('e1'),
      ).thenAnswer((_) async => const Right([]));
      when(() => startEvent('e1')).thenAnswer((_) async => const Right(unit));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load('e1');
      await cubit.startEvent();
    },
    verify: (cubit) {
      verify(() => startEvent('e1')).called(1);
      verify(() => getDetail('e1')).called(2);
      expect(cubit.state.isActionInFlight, isFalse);
    },
  );

  blocTest<EventDetailCubit, EventDetailState>(
    'cancelMyRegistration() surfaces the error without reloading',
    build: () {
      when(() => getDetail('e1')).thenAnswer((_) async => Right(event));
      when(
        () => getRouteChanges('e1'),
      ).thenAnswer((_) async => const Right([]));
      when(() => cancelMyRegistration('e1')).thenAnswer(
        (_) async => const Left(DomainException(message: 'unknown_error')),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load('e1');
      await cubit.cancelMyRegistration();
    },
    verify: (cubit) {
      verify(() => getDetail('e1')).called(1);
      expect(
        cubit.state.action.maybeWhen(error: (_) => true, orElse: () => false),
        isTrue,
      );
    },
  );
}
