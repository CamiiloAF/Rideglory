import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/domain_exception.dart';

part 'delete_account_state.freezed.dart';

/// Estado del borrado de cuenta. No es un `ResultState<T>` genérico porque
/// tiene una salida propia de este flujo que no es ni éxito ni error
/// genérico: `blocked`, cuando el rider organiza una rodada activa
/// (Pencil: XryZO) y la Edge Function lo rechaza a propósito.
@freezed
sealed class DeleteAccountState with _$DeleteAccountState {
  const factory DeleteAccountState.initial() = DeleteAccountInitial;

  const factory DeleteAccountState.inProgress() = DeleteAccountInProgress;

  const factory DeleteAccountState.done() = DeleteAccountDone;

  const factory DeleteAccountState.blocked() = DeleteAccountBlocked;

  const factory DeleteAccountState.error({required DomainException error}) =
      DeleteAccountError;
}
