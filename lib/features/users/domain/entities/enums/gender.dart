import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../generated/l10n.dart';


enum Gender {
  @JsonValue(1)
  male,
  @JsonValue(2)
  female,
  @JsonValue(3)
  preferDoNotSay;

  String getText() {
    switch (this) {
      case Gender.male:
        return AppStrings.current.male;
      case Gender.female:
        return AppStrings.current.female;
      case Gender.preferDoNotSay:
        return AppStrings.current.preferDoNotSay;
    }
  }
}
