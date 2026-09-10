import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/sos_alert.dart';
import 'sos_send_state.dart';

part 'sos_state.freezed.dart';

/// Pantallas LV3/LV4 (SOS propio) y LV5 (SOS de otros riders). `mine` y
/// `others` son independientes: un rider puede ver el SOS de un compañero
/// sin tener uno propio activo, o al revés.
@freezed
abstract class SosState with _$SosState {
  const factory SosState({
    @Default(SosSendState.idle()) SosSendState mine,
    @Default(ResultState<List<SosAlert>>.initial())
    ResultState<List<SosAlert>> others,
  }) = _SosState;
}
