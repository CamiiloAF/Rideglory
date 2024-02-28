import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../generated/l10n.dart';

enum LookingForOption {
  @JsonValue(1)
  adventure,
  @JsonValue(2)
  shortTrip,
  @JsonValue(3)
  longTrip,
  @JsonValue(4)
  couple,
  @JsonValue(5)
  extreme;

  String getText() {
    switch (this) {
      case LookingForOption.adventure:
        return AppStrings.current.adventure;
      case LookingForOption.shortTrip:
        return AppStrings.current.shortTrip;
      case LookingForOption.longTrip:
        return AppStrings.current.longTrip;
      case LookingForOption.couple:
        return AppStrings.current.couple;
      case LookingForOption.extreme:
        return AppStrings.current.extreme;
    }
  }
}
