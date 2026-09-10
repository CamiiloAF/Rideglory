import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/sos_alert.dart';
import '../../domain/sos_outbox_item.dart';

part 'sos_send_state.freezed.dart';

/// Estado del SOS propio (LV3/LV4). **`pending` no es un error**: es un SOS
/// ya persistido localmente que el servidor todavía no confirmó — la UI
/// debe decir "no salió, reintentando", nunca "enviado" (regla de
/// seguridad del rider).
@freezed
sealed class SosSendState with _$SosSendState {
  const factory SosSendState.idle() = SosSendIdle;

  const factory SosSendState.sending() = SosSendSending;

  const factory SosSendState.pending({required SosOutboxItem item}) =
      SosSendPending;

  const factory SosSendState.confirmed({required SosAlert alert}) =
      SosSendConfirmed;

  const factory SosSendState.closing({required SosAlert alert}) =
      SosSendClosing;

  const factory SosSendState.closed({required SosAlert alert}) = SosSendClosed;
}
