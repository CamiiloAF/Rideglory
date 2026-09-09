import 'package:flutter/widgets.dart';

import '../../../l10n/l10n_extensions.dart';
import '../domain/consent_entry.dart';

String consentKindLabel(BuildContext context, ConsentKind kind) {
  return switch (kind) {
    ConsentKind.riskAcceptance =>
      context.l10n.profile_consent_kind_risk_acceptance,
    ConsentKind.medicalConsent =>
      context.l10n.profile_consent_kind_medical_consent,
    ConsentKind.terms => context.l10n.profile_consent_kind_terms,
  };
}
