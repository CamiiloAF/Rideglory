import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../events/domain/usecases/get_event_detail_use_case.dart';
import '../../domain/background_tracking_service.dart';
import '../../domain/live_ride_contacts_cache.dart';
import '../../domain/location_permission_state.dart';
import '../../domain/location_service.dart';
import '../../domain/usecases/get_location_permission_state_use_case.dart';
import '../../domain/usecases/start_sharing_location_use_case.dart';
import '../../domain/usecases/stop_sharing_location_use_case.dart';
import '../../domain/usecases/watch_event_finished_use_case.dart';
import '../../domain/usecases/watch_live_riders_use_case.dart';
import '../live_ride_route_args.dart';
import 'live_ride_state.dart';
import 'sharing_status.dart';

/// Pantalla LV1: mapa + hoja de riders de una rodada en curso. Un mismo
/// cubit cubre la lista en vivo de participantes (Realtime), el ciclo de
/// "compartir mi ubicación" (D21) y la señal de fin de rodada (D22).
@injectable
class LiveRideCubit extends Cubit<LiveRideState> {
  LiveRideCubit(
    this._watchLiveRiders,
    this._watchEventFinished,
    this._getPermissionState,
    this._startSharing,
    this._stopSharing,
    this._locationService,
    this._contactsCache,
    this._backgroundTrackingService,
    this._getEventDetail,
  ) : super(const LiveRideState());

  final WatchLiveRidersUseCase _watchLiveRiders;
  final WatchEventFinishedUseCase _watchEventFinished;
  final GetLocationPermissionStateUseCase _getPermissionState;
  final StartSharingLocationUseCase _startSharing;
  final StopSharingLocationUseCase _stopSharing;
  final LocationService _locationService;
  final LiveRideContactsCache _contactsCache;
  final BackgroundTrackingService _backgroundTrackingService;
  final GetEventDetailUseCase _getEventDetail;

  StreamSubscription<dynamic>? _ridersSubscription;
  StreamSubscription<dynamic>? _eventFinishedSubscription;
  StreamSubscription<dynamic>? _myPositionSubscription;
  StreamSubscription<void>? _stoppedExternallySubscription;
  late String _eventId;

  Future<void> load(String eventId) async {
    _eventId = eventId;
    emit(state.copyWith(riders: const ResultState.loading()));

    final permission = await _getPermissionState();
    final contacts = await _contactsCache.read(eventId);
    final isRunning = await _backgroundTrackingService.isRunning();
    emit(
      state.copyWith(
        permission: permission,
        contacts: contacts,
        sharing: isRunning ? SharingStatus.sharing : SharingStatus.notSharing,
      ),
    );
    if (isRunning) _listenToMyPosition();

    // D22 extra: el botón "Detener" de la notificación (o el sistema
    // matando el servicio) termina el tracking fuera de `stopSharing()`
    // — sin esto, la UI seguiría mostrando "Compartiendo" con el
    // servicio nativo ya muerto.
    unawaited(_stoppedExternallySubscription?.cancel());
    _stoppedExternallySubscription = _backgroundTrackingService
        .stoppedExternally
        .listen((_) async {
          await _myPositionSubscription?.cancel();
          _myPositionSubscription = null;
          emit(
            state.copyWith(sharing: SharingStatus.notSharing, myPosition: null),
          );
        });

    unawaited(_ridersSubscription?.cancel());
    _ridersSubscription = _watchLiveRiders(eventId).listen((result) {
      result.fold(
        (error) =>
            emit(state.copyWith(riders: ResultState.error(error: error))),
        (riders) => emit(
          state.copyWith(
            riders: riders.isEmpty
                ? const ResultState.empty()
                : ResultState.data(data: riders),
          ),
        ),
      );
    });

    unawaited(_eventFinishedSubscription?.cancel());
    _eventFinishedSubscription = _watchEventFinished(eventId).listen((
      finished,
    ) {
      emit(state.copyWith(isEventFinished: finished));
      if (finished && state.sharing == SharingStatus.sharing) {
        stopSharing();
      }
    });
  }

  /// D21: se llama después de que la hoja de consentimiento propia (LV2) ya
  /// mostró el aviso y el rider confirmó — el diálogo del sistema lo
  /// dispara `GetLocationPermissionStateUseCase`/`LocationService` en la
  /// UI antes de invocar esto.
  Future<void> startSharing({
    required String notificationTitle,
    required String notificationBody,
    required String stopButtonLabel,
  }) async {
    emit(state.copyWith(sharing: SharingStatus.requestingPermission));
    final result = await _startSharing(
      eventId: _eventId,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
      stopButtonLabel: stopButtonLabel,
    );
    final permission = await _getPermissionState();
    result.fold(
      (_) => emit(
        state.copyWith(
          sharing: SharingStatus.notSharing,
          permission: permission,
        ),
      ),
      (_) => emit(
        state.copyWith(sharing: SharingStatus.sharing, permission: permission),
      ),
    );
    if (result.isRight()) {
      final contacts = await _contactsCache.read(_eventId);
      emit(state.copyWith(contacts: contacts));
      _listenToMyPosition();
    }
  }

  /// D21 paso 1: se llama al pulsar "Permitir" en la hoja LV2, antes de
  /// [startSharing]. Dispara el diálogo nativo del sistema.
  Future<LocationPermissionState> requestWhileInUsePermission() async {
    final permission = await _locationService.requestWhileInUse();
    emit(state.copyWith(permission: permission));
    return permission;
  }

  /// D21 paso 2: se llama al pulsar "Permitir todo el tiempo" en la hoja
  /// LV2b, ya con el tracking corriendo. Si el rider la niega, el
  /// tracking sigue mientras la app está abierta (la UI muestra un
  /// banner de advertencia con `state.permission != always`).
  Future<LocationPermissionState> requestAlwaysPermission() async {
    final permission = await _locationService.requestAlways();
    emit(state.copyWith(permission: permission));
    return permission;
  }

  Future<void> stopSharing() async {
    emit(state.copyWith(sharing: SharingStatus.stopping));
    await _myPositionSubscription?.cancel();
    _myPositionSubscription = null;
    await _stopSharing(_eventId);
    emit(state.copyWith(sharing: SharingStatus.notSharing, myPosition: null));
  }

  /// Se abre `/live` desde el push de un SOS (deep link) sin haber pasado
  /// por el detalle del evento (EV2), así que `extra` viene vacío. Si
  /// `provided` ya trae datos reales, se usan tal cual; si no, se resuelven
  /// contra `GetEventDetailUseCase` una sola vez por sesión.
  Future<void> resolveArgs(String eventId, LiveRideRouteArgs? provided) async {
    if (provided != null && provided != LiveRideRouteArgs.empty) {
      emit(state.copyWith(args: provided));
      return;
    }
    if (state.args != LiveRideRouteArgs.empty) return;

    final result = await _getEventDetail(eventId);
    result.fold((_) => null, (event) {
      emit(
        state.copyWith(
          args: LiveRideRouteArgs(
            eventName: event.name,
            isOwner: event.isOwnedByMe,
            ownerId: event.ownerId,
          ),
        ),
      );
    });
  }

  void _listenToMyPosition() {
    unawaited(_myPositionSubscription?.cancel());
    _myPositionSubscription = _locationService.positionStream().listen(
      (position) => emit(state.copyWith(myPosition: position)),
    );
  }

  @override
  Future<void> close() async {
    await _ridersSubscription?.cancel();
    await _eventFinishedSubscription?.cancel();
    await _myPositionSubscription?.cancel();
    await _stoppedExternallySubscription?.cancel();
    return super.close();
  }
}
