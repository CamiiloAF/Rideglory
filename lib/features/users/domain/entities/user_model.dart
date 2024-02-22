import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums/gender.dart';
import 'enums/looking_for_option.dart';

part 'user_model.freezed.dart';

part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    String? id,
    required String fullName,
    required String email,
    required Gender? gender,
    required DateTime dob,
    required int phoneNumber,
    @Default([]) List<LookingForOption> lookingFor,
    @Default([]) List<Gender> gendersLike,
    @Default([]) List<String> pictures,
  }) = _UserModel;

  factory UserModel.fromJson(final Map<String, Object?> json) =>
      _$UserModelFromJson(json);
}
