import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    String? id,
    required String fullName,
    required String email,
    required String? gender,
    required DateTime dob,
    required int phoneNumberInput,
  }) = _UserModel;

  factory UserModel.fromJson(final Map<String, Object?> json) =>
      _$UserModelFromJson(json);
}
