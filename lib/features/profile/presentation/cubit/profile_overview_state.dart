import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/profile.dart';
import '../../domain/rider_vehicle_preview.dart';

part 'profile_overview_state.freezed.dart';

/// Estado de P2 (ficha del rider): dos resultados independientes —
/// [profile] puede fallar mientras [vehicles] carga bien, o al revés — así
/// que cada uno lleva su propio `ResultState` (regla de estado complejo de
/// `CLAUDE.md`).
@freezed
abstract class ProfileOverviewState with _$ProfileOverviewState {
  const factory ProfileOverviewState({
    required ResultState<Profile> profile,
    required ResultState<List<RiderVehiclePreview>> vehicles,
  }) = _ProfileOverviewState;

  factory ProfileOverviewState.initial() => const ProfileOverviewState(
    profile: ResultState.initial(),
    vehicles: ResultState.initial(),
  );
}
