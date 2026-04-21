import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/user_main_vehicle_repository.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_main_vehicle_id_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_vehicles_usecase.dart';

void main() {
  group('HomeCubit', () {
    late _StubEventRepository eventRepository;
    late _StubVehicleRepository vehicleRepository;
    late _StubUserMainVehicleRepository userMainVehicleRepository;
    late HomeCubit cubit;

    setUp(() {
      eventRepository = _StubEventRepository();
      vehicleRepository = _StubVehicleRepository();
      userMainVehicleRepository = _StubUserMainVehicleRepository();
      cubit = HomeCubit(
        GetEventsUseCase(eventRepository),
        GetVehiclesUseCase(vehicleRepository),
        GetMainVehicleIdUseCase(userMainVehicleRepository),
      );
    });

    test('emits loading then loaded with selected main vehicle and 5 upcoming events', () async {
      final now = DateTime.now();
      final activeOne = _buildVehicle(id: 'v1', name: 'Moto 1');
      final activeTwo = _buildVehicle(id: 'v2', name: 'Moto 2');
      final archived = _buildVehicle(id: 'v3', name: 'Moto 3', isArchived: true);
      vehicleRepository.vehiclesResult = right([activeOne, activeTwo, archived]);
      userMainVehicleRepository.mainVehicleIdResult = const Right('v2');
      eventRepository.eventsResult = right([
        _buildEvent(id: 'e1', startDate: now.add(const Duration(days: 1))),
        _buildEvent(id: 'e2', startDate: now.add(const Duration(days: 2))),
        _buildEvent(id: 'e3', startDate: now.add(const Duration(days: 3))),
        _buildEvent(id: 'e4', startDate: now.add(const Duration(days: 4))),
        _buildEvent(id: 'e5', startDate: now.add(const Duration(days: 5))),
        _buildEvent(id: 'e6', startDate: now.add(const Duration(days: 6))),
      ]);

      final emitted = await _collectStates(cubit, () => cubit.loadHomeData());

      expect(emitted.first, isA<HomeLoading>());
      final loaded = emitted.last as HomeLoaded;
      expect(loaded.mainVehicle, activeTwo);
      expect(loaded.upcomingEvents, hasLength(5));
      expect(loaded.upcomingEvents.map((event) => event.id), ['e1', 'e2', 'e3', 'e4', 'e5']);
    });

    test('falls back to first active vehicle when main vehicle id is null', () async {
      final firstActive = _buildVehicle(id: 'v10', name: 'First');
      final secondActive = _buildVehicle(id: 'v11', name: 'Second');
      vehicleRepository.vehiclesResult = right([firstActive, secondActive]);
      userMainVehicleRepository.mainVehicleIdResult = const Right(null);
      eventRepository.eventsResult = const Right([]);

      final emitted = await _collectStates(cubit, () => cubit.loadHomeData());

      final loaded = emitted.last as HomeLoaded;
      expect(loaded.mainVehicle, firstActive);
    });

    test('uses first active vehicle when main vehicle id does not exist', () async {
      final firstActive = _buildVehicle(id: 'v21', name: 'First');
      final secondActive = _buildVehicle(id: 'v22', name: 'Second');
      vehicleRepository.vehiclesResult = right([firstActive, secondActive]);
      userMainVehicleRepository.mainVehicleIdResult = const Right('missing-id');
      eventRepository.eventsResult = const Right([]);

      final emitted = await _collectStates(cubit, () => cubit.loadHomeData());

      final loaded = emitted.last as HomeLoaded;
      expect(loaded.mainVehicle, firstActive);
    });

    test('returns null main vehicle when there are no active vehicles', () async {
      vehicleRepository.vehiclesResult = right([
        _buildVehicle(id: 'archived', name: 'Archived', isArchived: true),
      ]);
      userMainVehicleRepository.mainVehicleIdResult = const Right('archived');
      eventRepository.eventsResult = const Right([]);

      final emitted = await _collectStates(cubit, () => cubit.loadHomeData());

      final loaded = emitted.last as HomeLoaded;
      expect(loaded.mainVehicle, isNull);
    });

    test('filters out past events and keeps only upcoming', () async {
      final now = DateTime.now();
      vehicleRepository.vehiclesResult = right([_buildVehicle(id: 'v50', name: 'Main')]);
      userMainVehicleRepository.mainVehicleIdResult = const Right(null);
      eventRepository.eventsResult = right([
        _buildEvent(id: 'past', startDate: now.subtract(const Duration(days: 1))),
        _buildEvent(id: 'future', startDate: now.add(const Duration(days: 1))),
      ]);

      final emitted = await _collectStates(cubit, () => cubit.loadHomeData());

      final loaded = emitted.last as HomeLoaded;
      expect(loaded.upcomingEvents.map((event) => event.id), ['future']);
    });

    test('still emits loaded when repositories return errors', () async {
      vehicleRepository.vehiclesResult = left(const DomainException(message: 'vehicles error'));
      userMainVehicleRepository.mainVehicleIdResult = left(
        const DomainException(message: 'main vehicle error'),
      );
      eventRepository.eventsResult = left(const DomainException(message: 'events error'));

      final emitted = await _collectStates(cubit, () => cubit.loadHomeData());

      expect(emitted.first, isA<HomeLoading>());
      final loaded = emitted.last as HomeLoaded;
      expect(loaded.mainVehicle, isNull);
      expect(loaded.upcomingEvents, isEmpty);
    });
  });
}

Future<List<HomeState>> _collectStates(
  HomeCubit cubit,
  Future<void> Function() action,
) async {
  final emitted = <HomeState>[];
  final subscription = cubit.stream.listen(emitted.add);
  await action();
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();
  return emitted;
}

VehicleModel _buildVehicle({
  required String id,
  required String name,
  bool isArchived = false,
}) {
  return VehicleModel(
    id: id,
    name: name,
    currentMileage: 1000,
    isArchived: isArchived,
  );
}

EventModel _buildEvent({required String id, required DateTime startDate}) {
  return EventModel(
    id: id,
    ownerId: 'owner',
    name: 'Event $id',
    description: 'Description',
    city: 'Medellin',
    startDate: startDate,
    difficulty: EventDifficulty.one,
    meetingPoint: 'Point A',
    destination: 'Point B',
    meetingTime: startDate,
    eventType: EventType.onRoad,
  );
}

class _StubVehicleRepository implements VehicleRepository {
  Either<DomainException, List<VehicleModel>> vehiclesResult = const Right([]);

  @override
  Future<Either<DomainException, List<VehicleModel>>> getVehiclesByUserId() async =>
      vehiclesResult;

  @override
  Future<Either<DomainException, VehicleModel>> addVehicle(VehicleModel vehicle) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, void>> deleteVehicle(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, String>> uploadVehicleImage({
    required String vehicleId,
    required String localImagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, VehicleModel>> updateVehicle(VehicleModel vehicle) {
    throw UnimplementedError();
  }
}

class _StubEventRepository implements EventRepository {
  Either<DomainException, List<EventModel>> eventsResult = const Right([]);

  @override
  Future<Either<DomainException, List<EventModel>>> getEvents() async => eventsResult;

  @override
  Future<Either<DomainException, EventModel>> addEvent(EventModel event) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, Nothing>> deleteEvent(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, EventModel>> getEventById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, List<EventModel>>> getMyEvents() {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, String>> uploadEventImage({
    required String eventId,
    required String localImagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, EventModel>> updateEvent(EventModel event) {
    throw UnimplementedError();
  }
}

class _StubUserMainVehicleRepository implements UserMainVehicleRepository {
  Either<DomainException, String?> mainVehicleIdResult = const Right(null);

  @override
  Future<Either<DomainException, String?>> getMainVehicleId() async => mainVehicleIdResult;

  @override
  Future<Either<DomainException, UserMainVehicleModel?>> getMainVehicle() {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, UserMainVehicleModel>> setMainVehicleId(String vehicleId) {
    throw UnimplementedError();
  }
}
