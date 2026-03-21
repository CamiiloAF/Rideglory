import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/start_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/stop_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_location_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/watch_active_riders_use_case.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';

@injectable
class LiveTrackingCubitFactory {
  LiveTrackingCubitFactory(
    this._watchActiveRidersUseCase,
    this._startTrackingUseCase,
    this._updateLocationUseCase,
    this._stopTrackingUseCase,
    this._getRiderProfileUseCase,
    this._authService,
  );

  final WatchActiveRidersUseCase _watchActiveRidersUseCase;
  final StartTrackingUseCase _startTrackingUseCase;
  final UpdateLocationUseCase _updateLocationUseCase;
  final StopTrackingUseCase _stopTrackingUseCase;
  final GetRiderProfileUseCase _getRiderProfileUseCase;
  final AuthService _authService;

  LiveTrackingCubit create({
    required String eventId,
    required String eventOwnerId,
  }) {
    return LiveTrackingCubit(
      eventId: eventId,
      eventOwnerId: eventOwnerId,
      watchActiveRidersUseCase: _watchActiveRidersUseCase,
      startTrackingUseCase: _startTrackingUseCase,
      updateLocationUseCase: _updateLocationUseCase,
      stopTrackingUseCase: _stopTrackingUseCase,
      getRiderProfileUseCase: _getRiderProfileUseCase,
      authService: _authService,
    );
  }
}
