import 'package:freezed_annotation/freezed_annotation.dart';

part 'connectivity_state.freezed.dart';

/// Estado de conectividad global de la app.
@freezed
class ConnectivityState with _$ConnectivityState {
  const factory ConnectivityState.online() = ConnectivityOnline;

  const factory ConnectivityState.offline() = ConnectivityOffline;
}
