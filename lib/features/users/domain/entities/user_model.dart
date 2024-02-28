import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums/gender.dart';
import 'enums/looking_for_option.dart';

part 'user_model.freezed.dart';

part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required final String fullName, required final String email, required final Gender? gender, required final DateTime dob, required final int phoneNumber, final String? id,
    @Default([]) final List<LookingForOption> lookingFor,
    @Default([]) final List<Gender> gendersLike,
    @Default([]) final List<String> pictures,
  }) = _UserModel;

  factory UserModel.fromJson(final Map<String, Object?> json) =>
      _$UserModelFromJson(json);
}
