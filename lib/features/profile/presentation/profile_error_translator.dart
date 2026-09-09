import 'package:flutter/widgets.dart';

import '../../../core/exceptions/domain_exception.dart';
import '../../../l10n/l10n_extensions.dart';
import '../domain/profile_error_code.dart';

String profileErrorMessage(BuildContext context, DomainException error) {
  return switch (error.message) {
    ProfileErrorCode.offline => context.l10n.common_offline_body,
    _ => context.l10n.profile_load_error_body,
  };
}
