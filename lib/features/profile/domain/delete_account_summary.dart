import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_account_summary.freezed.dart';

/// Conteo de lo que se pierde al borrar la cuenta, para la pantalla de
/// explicación del borrado (Pencil: MCSBy).
@freezed
abstract class DeleteAccountSummary with _$DeleteAccountSummary {
  const factory DeleteAccountSummary({
    required int vehicleCount,
    required int maintenanceCount,
    required int documentCount,
  }) = _DeleteAccountSummary;
}
