import 'package:flutter/widgets.dart';

import '../../../core/exceptions/domain_exception.dart';
import '../../../l10n/l10n_extensions.dart';
import '../domain/auth_error_code.dart';

/// Traduce el código semántico de un [DomainException] de auth a la cadena
/// en español que se muestra al rider.
String authErrorMessage(BuildContext context, DomainException error) {
  return switch (error.message) {
    AuthErrorCode.invalidCredentials =>
      context.l10n.auth_error_invalid_credentials,
    AuthErrorCode.emailAlreadyRegistered =>
      context.l10n.auth_error_email_already_registered,
    AuthErrorCode.weakPassword => context.l10n.auth_error_weak_password,
    AuthErrorCode.userNotFound => context.l10n.auth_error_user_not_found,
    AuthErrorCode.providerCancelled =>
      context.l10n.auth_error_provider_cancelled,
    AuthErrorCode.offline => context.l10n.auth_error_offline,
    _ => context.l10n.auth_error_unknown,
  };
}
