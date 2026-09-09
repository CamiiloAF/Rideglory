import 'package:flutter/widgets.dart';

import '../../../l10n/l10n_extensions.dart';
import '../domain/blood_type.dart';

String bloodTypeLabel(BuildContext context, BloodType bloodType) {
  return switch (bloodType) {
    BloodType.oPositive => context.l10n.profile_blood_type_o_positive,
    BloodType.oNegative => context.l10n.profile_blood_type_o_negative,
    BloodType.aPositive => context.l10n.profile_blood_type_a_positive,
    BloodType.aNegative => context.l10n.profile_blood_type_a_negative,
    BloodType.bPositive => context.l10n.profile_blood_type_b_positive,
    BloodType.bNegative => context.l10n.profile_blood_type_b_negative,
    BloodType.abPositive => context.l10n.profile_blood_type_ab_positive,
    BloodType.abNegative => context.l10n.profile_blood_type_ab_negative,
  };
}
