import 'dart:async';
import 'dart:developer' as developer;

import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/start_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/stop_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_location_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/watch_active_riders_use_case.dart';
import 'package:rideglory/features/events/presentation/tracking/tracking_location_settings.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

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
    required TrackingRepository trackingRepository,
    required AnalyticsService analyticsService,
  }) : _eventId = eventId,
       _eventOwnerId = eventOwnerId,
       _watchActiveRidersUseCase = watchActiveRidersUseCase,
       _startTrackingUseCase = startTrackingUseCase,
       _updateLocationUseCase = updateLocationUseCase,
       _stopTrackingUseCase = stopTrackingUseCase,
       _getRiderProfileUseCase = getRiderProfileUseCase,
       _authService = authService,
       _trackingRepository = trackingRepository,
       _analyticsService = analyticsService,
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
  final TrackingRepository _trackingRepository;
  final AnalyticsService _analyticsService;

  StreamSubscription<List<RiderTrackingModel>>? _ridersSubscription;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<SosAlertModel>? _sosSubscription;
  StreamSubscription<String>? _sosClearedSubscription;
  StreamSubscription<void>? _eventEndedSubscription;
  final Battery _battery = Battery();
  Timer? _ridersReconnectTimer;

  double? _lastLatitude;
  double? _lastLongitude;
  double _accumulatedDistanceMeters = 0;
  DateTime? _lastBackendPush;
  String? _userId;

  // --- Analytics anti-doble-conteo flags ---
  // Reseteados al inicio de cada sesión en _startSharingMyLocation.
  bool _sessionEndLogged = false;
  bool _snapshotLogged = false;
  // Reseteados cuando el rider activa o cancela un SOS propio.
  bool _sosClearedLogged = false;
  bool _sosConfirmedLogged = false;

  Future<void> start() async {
    if (_eventId.isEmpty) {
      emit(
        state.copyWith(
          ridersResult: const ResultState.error(
            error: DomainException(message: EventStrings.trackingEventMissing),
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

    _subscribeToRiders();
    _subscribeToSosAlerts();
    _subscribeToSosCleared();
    _subscribeToEventEnded();

    await _startSharingMyLocation();
  }

  Future<void> _startSharingMyLocation() async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }
    _userId = user.id;

    final trackingPermission =
        await LocationPermissionHandler.requestForLiveTracking();
    if (trackingPermission == LiveTrackingLocationPermissionOutcome.denied) {
      emit(
        state.copyWith(
          ridersResult: state.ridersResult.maybeMap(
            data: (d) =>
                ResultState<List<RiderTrackingModel>>.data(data: d.data),
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

    final trackingFullName = _trackingFullName(profile, user);

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: TrackingLocationSettings.currentFix(),
      );
    } catch (_) {
      emit(
        state.copyWith(
          ridersResult: state.ridersResult.maybeMap(
            data: (d) =>
                ResultState<List<RiderTrackingModel>>.data(data: d.data),
            orElse: () => const ResultState.error(
              error: DomainException(message: EventStrings.trackingStartFailed),
            ),
          ),
        ),
      );
      return;
    }

    final battery = await _readBatteryPercent();
    final role = user.id == _eventOwnerId
        ? RiderTrackingRole.lead
        : RiderTrackingRole.rider;

    final initial = RiderTrackingModel(
      userId: user.id,
      fullName: trackingFullName,
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
    developer.log('Live tracking start result: $startResult');

    startResult.fold(
      (_) {
        emit(
          state.copyWith(
            isTracking: false,
            ridersResult: state.ridersResult.maybeMap(
              data: (d) =>
                  ResultState<List<RiderTrackingModel>>.data(data: d.data),
              orElse: () => const ResultState.error(
                error: DomainException(
                  message: EventStrings.trackingStartFailed,
                ),
              ),
            ),
          ),
        );
      },
      (_) {
        // Reset per-session analytics flags before logging the start event.
        _sessionEndLogged = false;
        _snapshotLogged = false;
        _sosClearedLogged = false;
        _sosConfirmedLogged = false;

        // Hito: arranque exitoso de tracking (una vez por sesión).
        // NO incluir coordenadas ni uid como parámetro.
        _analyticsService.logEvent(AnalyticsEvents.trackingSessionStarted, {
          AnalyticsParams.trackingRole: role == RiderTrackingRole.lead
              ? AnalyticsParams.trackingRoleLead
              : AnalyticsParams.trackingRoleRider,
        }).ignore();

        _accumulatedDistanceMeters = 0;
        _lastLatitude = position.latitude;
        _lastLongitude = position.longitude;
        _lastBackendPush = DateTime.now();
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

  /// Emite [AnalyticsEvents.trackingSessionEnded] exactamente una vez por sesión.
  /// El flag [_sessionEndLogged] previene doble-conteo cuando concurren
  /// signOut, close() y/o eventEnded.
  void _logSessionEnded(String endReason) {
    if (_sessionEndLogged) return;
    _sessionEndLogged = true;
    _analyticsService.logEvent(AnalyticsEvents.trackingSessionEnded, {
      AnalyticsParams.trackingEndReason: endReason,
    }).ignore();
  }

  void _listenPosition(LocationPermission geolocatorPermission) {
    // PROHIBICIÓN DE ANALYTICS: nunca emitir un evento por cada ping de
    // ubicación (publishLocation / _updateLocationUseCase). Las coordenadas
    // (latitude/longitude) NUNCA van como param de ningún evento de analítica.
    final uid = _userId;
    if (uid == null) {
      return;
    }

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
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
          if (_lastBackendPush != null &&
              now.difference(_lastBackendPush!) < const Duration(seconds: 4)) {
            emit(
              state.copyWith(
                totalDistanceMeters: _accumulatedDistanceMeters,
                currentUserLatitude: position.latitude,
                currentUserLongitude: position.longitude,
              ),
            );
            return;
          }
          _lastBackendPush = now;

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

  String _trackingFullName(RiderProfileModel? profile, UserModel user) {
    final fromProfile = profile?.fullName?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) {
      return fromProfile;
    }
    final authName = user.fullName?.trim();
    if (authName != null && authName.isNotEmpty) {
      return authName;
    }
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Rider';
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
    await _sosSubscription?.cancel();
    _sosSubscription = null;
    await _sosClearedSubscription?.cancel();
    _sosClearedSubscription = null;
    await _eventEndedSubscription?.cancel();
    _eventEndedSubscription = null;
    _ridersReconnectTimer?.cancel();

    final uid = _userId;
    final wasTracking = state.isTracking;

    if (uid != null && wasTracking) {
      // Hito: fin de sesión por cierre de sesión del usuario.
      _logSessionEnded(AnalyticsParams.trackingEndReasonSignedOut);
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
        hasSentSos: false,
        sosAlertResult: const ResultState.initial(),
      ),
    );
  }

  @override
  Future<void> close() async {
    _ridersReconnectTimer?.cancel();
    await _authSubscription?.cancel();
    await _ridersSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _sosSubscription?.cancel();
    await _sosClearedSubscription?.cancel();
    await _eventEndedSubscription?.cancel();
    final uid = _userId;
    if (uid != null && state.isTracking) {
      // Hito: fin de sesión por cierre del cubit (el rider salió de la pantalla).
      _logSessionEnded(AnalyticsParams.trackingEndReasonUserLeft);
      await _stopTrackingUseCase(eventId: _eventId, userId: uid);
    }
    return super.close();
  }

  /// Test-only seam: deja el cubit listo para ejercitar los hitos de SOS sin
  /// pasar por el flujo de Geolocator/permisos (que usa APIs estáticas). Fija
  /// el [userId] de la sesión y activa las suscripciones de SOS. NO se usa en
  /// producción.
  @visibleForTesting
  void debugPrimeSosForTest(String userId) {
    _userId = userId;
    _subscribeToSosAlerts();
    _subscribeToSosCleared();
  }

  /// Publishes an SOS alert via the tracking repository. Sets [hasSentSos] to true.
  void triggerSos() {
    final userId = _userId;
    if (userId == null) return;

    _trackingRepository.publishSos(
      eventId: _eventId,
      userId: userId,
      latitude: state.currentUserLatitude,
      longitude: state.currentUserLongitude,
    );
    emit(state.copyWith(hasSentSos: true));

    // Hito SOS: el usuario activó un SOS propio. NUNCA lat/lng ni uid.
    _sosClearedLogged = false;
    _sosConfirmedLogged = false;
    _analyticsService.logEvent(AnalyticsEvents.sosActivated, {
      AnalyticsParams.trackingRole: userId == _eventOwnerId
          ? AnalyticsParams.trackingRoleLead
          : AnalyticsParams.trackingRoleRider,
    }).ignore();
  }

  /// Deactivates the current user's own SOS (toggle off) and notifies peers via
  /// the gateway so their banners disappear.
  void cancelSos() {
    final userId = _userId;
    if (userId != null) {
      _trackingRepository.cancelSos(eventId: _eventId, userId: userId);
      // Hito SOS: cancelación propia (una vez por activación).
      if (!_sosClearedLogged) {
        _sosClearedLogged = true;
        _analyticsService.logEvent(AnalyticsEvents.sosCleared, {
          AnalyticsParams.sosClearReason:
              AnalyticsParams.sosClearReasonUserCancel,
        }).ignore();
      }
    }
    emit(state.copyWith(hasSentSos: false));
  }

  /// Called by the organizer to end the ride via the tracking repository.
  Future<void> endRide(String eventId) async {
    final result = await _trackingRepository.endRide(eventId);
    result.fold((error) => developer.log('End ride failed: $error'), (_) {});
  }

  void _subscribeToSosAlerts() {
    _sosSubscription?.cancel();
    _sosSubscription = _trackingRepository.sosAlerts.listen((alert) {
      if (isClosed) return;
      // Hito SOS: el sistema confirmó/propagó mi propio SOS (una vez por activación).
      if (alert.userId == _userId && !_sosConfirmedLogged) {
        _sosConfirmedLogged = true;
        _analyticsService.logEvent(AnalyticsEvents.sosConfirmed).ignore();
      }
      emit(state.copyWith(sosAlertResult: ResultState.data(data: alert)));
    });
  }

  void _subscribeToSosCleared() {
    _sosClearedSubscription?.cancel();
    _sosClearedSubscription = _trackingRepository.sosCleared.listen((userId) {
      if (isClosed) return;
      final current = state.sosAlertResult.maybeMap(
        data: (d) => d.data,
        orElse: () => null,
      );
      final clearsBanner = current != null && current.userId == userId;
      final clearsOwnSos = userId == _userId && state.hasSentSos;
      if (!clearsBanner && !clearsOwnSos) return;
      // Hito SOS: mi SOS fue limpiado remotamente (una vez por activación).
      if (clearsOwnSos && !_sosClearedLogged) {
        _sosClearedLogged = true;
        _analyticsService.logEvent(AnalyticsEvents.sosCleared, {
          AnalyticsParams.sosClearReason:
              AnalyticsParams.sosClearReasonRemoteClear,
        }).ignore();
      }
      emit(
        state.copyWith(
          sosAlertResult: clearsBanner
              ? const ResultState.initial()
              : state.sosAlertResult,
          hasSentSos: clearsOwnSos ? false : state.hasSentSos,
        ),
      );
    });
  }

  void _subscribeToEventEnded() {
    _eventEndedSubscription?.cancel();
    _eventEndedSubscription = _trackingRepository.eventEnded.listen((_) async {
      if (isClosed) return;
      if (state.isTracking) {
        _logSessionEnded(AnalyticsParams.trackingEndReasonEventEnded);
      }
      // Capturar antes de que el emit cambie el estado.
      final wasTracking = state.isTracking;
      final uid = _userId;
      // Emitir de inmediato para que el overlay aparezca sin esperar cleanup.
      if (!isClosed) {
        emit(state.copyWith(isTracking: false, isFinished: true));
      }
      // Cleanup GPS y WS en background.
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      if (wasTracking && uid != null) {
        await _stopTrackingUseCase(eventId: _eventId, userId: uid);
      }
    });
  }

  /// Deja el cubit con sesión de rider activa para tests de eventEnded.
  /// Fija [userId] como rider activo, emite isTracking=true, y activa el listener.
  @visibleForTesting
  void debugPrimeForEventEndedTest(String userId) {
    _userId = userId;
    emit(state.copyWith(isTracking: true));
    _subscribeToEventEnded();
  }

  /// Activa solo el listener de eventEnded sin sesión activa (estado inicial).
  /// Usado para Caso C: rider que recibe el broadcast sin estar en tracking.
  @visibleForTesting
  void debugSubscribeEventEndedForTest() {
    _subscribeToEventEnded();
  }

  void _scheduleRidersResubscribe() {
    _ridersReconnectTimer?.cancel();
    _ridersReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (isClosed) {
        return;
      }
      _subscribeToRiders();
    });
  }

  Future<void> _subscribeToRiders() async {
    await _ridersSubscription?.cancel();
    _ridersSubscription = _watchActiveRidersUseCase(_eventId).listen(
      (riders) {
        developer.log('Live tracking riders emission: ${riders.length}');
        _ridersReconnectTimer?.cancel();
        // Hito: primer snapshot con riders en la sesión (el mapa se pobló).
        // Una sola vez por sesión; param agregado (conteo), nunca ids/coords.
        if (!_snapshotLogged && riders.isNotEmpty) {
          _snapshotLogged = true;
          _analyticsService.logEvent(AnalyticsEvents.trackingSnapshotReceived, {
            AnalyticsParams.riderCount: riders.length,
          }).ignore();
        }
        emit(state.copyWith(ridersResult: ResultState.data(data: riders)));
      },
      onError: (error) {
        developer.log('Live tracking riders stream error: $error');
        _scheduleRidersResubscribe();
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
      onDone: _scheduleRidersResubscribe,
    );
  }
}
