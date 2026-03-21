part of 'live_tracking_cubit.dart';

@freezed
abstract class LiveTrackingState with _$LiveTrackingState {
  const factory LiveTrackingState({
    required ResultState<List<RiderTrackingModel>> ridersResult,
    @Default(false) bool isTracking,
    @Default(0.0) double totalDistanceMeters,
    /// Device GPS used to compute distance to each rider (when tracking).
    double? currentUserLatitude,
    double? currentUserLongitude,
  }) = _LiveTrackingState;
}
