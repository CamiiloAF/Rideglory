import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/exceptions/domain_exception.dart';
import '../domain/auth_error_code.dart';

/// Traduce excepciones de `supabase_flutter`/red a un [DomainException] con
/// un código semántico de [AuthErrorCode] — nunca con el texto crudo del
/// SDK, que suele venir en inglés y no es apto para mostrar al rider.
DomainException mapAuthError(Object error) {
  if (error is supabase.AuthException) {
    final code = error.code;
    if (code == 'invalid_credentials' || code == 'invalid_grant') {
      return const DomainException(message: AuthErrorCode.invalidCredentials);
    }
    if (code == 'user_already_exists' || code == 'email_exists') {
      return const DomainException(
        message: AuthErrorCode.emailAlreadyRegistered,
      );
    }
    if (code == 'weak_password') {
      return const DomainException(message: AuthErrorCode.weakPassword);
    }
    if (code == 'user_not_found') {
      return const DomainException(message: AuthErrorCode.userNotFound);
    }
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return const DomainException(message: AuthErrorCode.invalidCredentials);
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return const DomainException(
        message: AuthErrorCode.emailAlreadyRegistered,
      );
    }
    return const DomainException(message: AuthErrorCode.unknown);
  }
  if (error.toString().toLowerCase().contains('socketexception') ||
      error.toString().toLowerCase().contains('failed host lookup')) {
    return const DomainException(message: AuthErrorCode.offline);
  }
  return const DomainException(message: AuthErrorCode.unknown);
}
