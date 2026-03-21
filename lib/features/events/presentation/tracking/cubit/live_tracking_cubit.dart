import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/start_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/stop_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_location_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/watch_active_riders_use_case.dart';
import 'package:rideglory/features/events/presentation/tracking/tracking_location_settings.dart';

part 'live_tracking_state.dart';
part 'live_tracking_cubit.freezed.dart';

class LiveTrackingCubit extends Cubit<LiveTrackingState> {
  LiveTrackingCubit({
    required String eventId,
    required String eventOwnerId,
    required WatchActiveRidersUseCase watchActiveRidersUseCase,
    required StartTrackingUseCase startTrackingUseCase,
    required UpdateLocationUseCase updateLocationUseCase,
    required StopTrackingUseCase stopTrackingUseCase,
    required GetRiderProfileUseCase getRiderProfileUseCase,
    required AuthService authService,
  }) : _eventId = eventId,
       _eventOwnerId = eventOwnerId,
       _watchActiveRidersUseCase = watchActiveRidersUseCase,
       _startTrackingUseCase = startTrackingUseCase,
       _updateLocationUseCase = updateLocationUseCase,
       _stopTrackingUseCase = stopTrackingUseCase,
       _getRiderProfileUseCase = getRiderProfileUseCase,
       _authService = authService,
       super(
         const LiveTrackingState(
           ridersResult: ResultState.initial(),
           isTracking: false,
           totalDistanceMeters: 0,
           currentUserLatitude: null,
           currentUserLongitude: null,
         ),
       );

  final String _eventId;
  final String _eventOwnerId;
  final WatchActiveRidersUseCase _watchActiveRidersUseCase;
  final StartTrackingUseCase _startTrackingUseCase;
  final UpdateLocationUseCase _updateLocationUseCase;
  final StopTrackingUseCase _stopTrackingUseCase;
  final GetRiderProfileUseCase _getRiderProfileUseCase;
  final AuthService _authService;

  StreamSubscription<List<RiderTrackingModel>>? _ridersSubscription;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<User?>? _authSubscription;
  final Battery _battery = Battery();

  double? _lastLatitude;
  double? _lastLongitude;
  double _accumulatedDistanceMeters = 0;
  DateTime? _lastFirebasePush;
  String? _userId;

  Future<void> start() async {
    if (_eventId.isEmpty) {
      emit(
        state.copyWith(
          ridersResult: const ResultState.error(
            error: DomainException(
              message: EventStrings.trackingEventMissing,
            ),
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(ridersResult: const ResultState.loading()));

    await _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user == null) {
        unawaited(_handleAuthSignedOut());
      }
    });

    _ridersSubscription = _watchActiveRidersUseCase(_eventId).listen(
      (riders) {
        emit(state.copyWith(ridersResult: ResultState.data(data: riders)));
      },
      onError: (_) {
        emit(
          state.copyWith(
            ridersResult: const ResultState.error(
              error: DomainException(
                message: EventStrings.trackingLoadRidersFailed,
              ),
            ),
          ),
        );
      },
    );

    await _startSharingMyLocation();
  }

  Future<void> _startSharingMyLocation() async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }
    _userId = user.uid;

    final trackingPermission =
        await LocationPermissionHandler.requestForLiveTracking();
    if (trackingPermission == LiveTrackingLocationPermissionOutcome.denied) {
      emit(
        state.copyWith(
          ridersResult: state.ridersResult.maybeMap(
            data: (d) => ResultState<List<RiderTrackingModel>>.data(
              data: d.data,
            ),
            orElse: () => const ResultState.error(
              error: DomainException(message: EventStrings.trackingStartFailed),
            ),
          ),
        ),
      );
      return;
    }

    await Geolocator.requestPermission();
    final geolocatorPermission = await Geolocator.checkPermission();

    final profileResult = await _getRiderProfileUseCase();
    final profile = profileResult.fold((_) => null, (p) => p);

    final firstName = profile?.firstName?.trim().isNotEmpty == true
        ? profile!.firstName!.trim()
        : _firstNameFromAuth(user);
    final lastName = profile?.lastName?.trim().isNotEmpty == true
        ? profile!.lastName!.trim()
        : _lastNameFromAuth(user);

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: TrackingLocationSettings.currentFix(),
      );
    } catch (_) {
      emit(
        state.copyWith(
          ridersResult: state.ridersResult.maybeMap(
            data: (d) => ResultState<List<RiderTrackingModel>>.data(
              data: d.data,
            ),
            orElse: () => const ResultState.error(
              error: DomainException(message: EventStrings.trackingStartFailed),
            ),
          ),
        ),
      );
      return;
    }

    final battery = await _readBatteryPercent();
    final role = user.uid == _eventOwnerId
        ? RiderTrackingRole.lead
        : RiderTrackingRole.rider;

    final initial = RiderTrackingModel(
      userId: user.uid,
      firstName: firstName,
      lastName: lastName,
      role: role,
      latitude: position.latitude,
      longitude: position.longitude,
      speedKmh: _speedKmh(position),
      distanceMeters: 0,
      batteryPercent: battery,
      isActive: true,
      deviceLabel: _deviceLabel(),
      lastUpdated: DateTime.now(),
    );

    final startResult = await _startTrackingUseCase(
      eventId: _eventId,
      initialData: initial,
    );

    startResult.fold(
      (_) {
        emit(
          state.copyWith(
            isTracking: false,
            ridersResult: state.ridersResult.maybeMap(
              data: (d) => ResultState<List<RiderTrackingModel>>.data(
                data: d.data,
              ),
              orElse: () => const ResultState.error(
                error: DomainException(message: EventStrings.trackingStartFailed),
              ),
            ),
          ),
        );
      },
      (_) {
        _accumulatedDistanceMeters = 0;
        _lastLatitude = position.latitude;
        _lastLongitude = position.longitude;
        _lastFirebasePush = DateTime.now();
        emit(
          state.copyWith(
            isTracking: true,
            totalDistanceMeters: 0,
            currentUserLatitude: position.latitude,
            currentUserLongitude: position.longitude,
          ),
        );
        _listenPosition(geolocatorPermission);
      },
    );
  }

  void _listenPosition(LocationPermission geolocatorPermission) {
    final uid = _userId;
    if (uid == null) {
      return;
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: TrackingLocationSettings.positionStream(
        geolocatorPermission: geolocatorPermission,
      ),
    ).listen((position) async {
      if (_lastLatitude != null && _lastLongitude != null) {
        final delta = Geolocator.distanceBetween(
          _lastLatitude!,
          _lastLongitude!,
          position.latitude,
          position.longitude,
        );
        _accumulatedDistanceMeters += delta;
      }
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;

      final now = DateTime.now();
      if (_lastFirebasePush != null &&
          now.difference(_lastFirebasePush!) <
              const Duration(seconds: 4)) {
        emit(
          state.copyWith(
            totalDistanceMeters: _accumulatedDistanceMeters,
            currentUserLatitude: position.latitude,
            currentUserLongitude: position.longitude,
          ),
        );
        return;
      }
      _lastFirebasePush = now;

      final battery = await _readBatteryPercent();

      final request = UpdateLocationRequest(
        eventId: _eventId,
        userId: uid,
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: _speedKmh(position),
        distanceMeters: _accumulatedDistanceMeters,
        batteryPercent: battery,
      );

      final result = await _updateLocationUseCase(request);
      result.fold((_) {}, (_) {
        emit(
          state.copyWith(
            totalDistanceMeters: _accumulatedDistanceMeters,
            currentUserLatitude: position.latitude,
            currentUserLongitude: position.longitude,
          ),
        );
      });
    });
  }

  Future<int> _readBatteryPercent() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return -1;
    }
  }

  String _deviceLabel() {
    return EventStrings.trackingDefaultDeviceLabel;
  }

  String _firstNameFromAuth(User user) {
    final display = user.displayName;
    if (display != null && display.trim().isNotEmpty) {
      final parts = display.trim().split(RegExp(r'\s+'));
      return parts.first;
    }
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Rider';
  }

  String _lastNameFromAuth(User user) {
    final display = user.displayName;
    if (display != null && display.trim().isNotEmpty) {
      final parts = display.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return parts.sublist(1).join(' ');
      }
    }
    return '';
  }

  double _speedKmh(Position position) {
    final speed = position.speed;
    if (speed.isNaN || speed <= 0) {
      return 0;
    }
    return speed * 3.6;
  }

  Future<void> _handleAuthSignedOut() async {
    if (isClosed) {
      return;
    }
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _ridersSubscription?.cancel();
    _ridersSubscription = null;

    final uid = _userId;
    final wasTracking = state.isTracking;

    if (uid != null && wasTracking) {
      await _stopTrackingUseCase(eventId: _eventId, userId: uid);
    }
    _userId = null;

    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        isTracking: false,
        totalDistanceMeters: 0,
        ridersResult: const ResultState.empty(),
        currentUserLatitude: null,
        currentUserLongitude: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _ridersSubscription?.cancel();
    await _positionSubscription?.cancel();
    final uid = _userId;
    if (uid != null && state.isTracking) {
      await _stopTrackingUseCase(eventId: _eventId, userId: uid);
    }
    return super.close();
  }
}
