import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/users/data/dto/user_dto.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

@injectable
class UserStorageService {
  const UserStorageService(this._storage);

  static const _keyPrefix = 'api_user_';

  final FlutterSecureStorage _storage;

  Future<void> saveUser({
    required String firebaseUid,
    required UserModel user,
  }) {
    return _storage.write(
      key: _key(firebaseUid),
      value: jsonEncode(_toJson(user)),
    );
  }

  Future<UserModel?> getUser(String firebaseUid) async {
    final rawUser = await _storage.read(key: _key(firebaseUid));
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    final json = jsonDecode(rawUser);
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return UserDto.fromJson(json);
  }

  String _key(String firebaseUid) => '$_keyPrefix$firebaseUid';

  Map<String, dynamic> _toJson(UserModel user) {
    return {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'identificationNumber': user.identificationNumber,
      'birthDate': user.birthDate?.toApiIso8601String(),
      'phone': user.phone,
      'residenceCity': user.residenceCity,
      'eps': user.eps,
      'medicalInsurance': user.medicalInsurance,
      'bloodType': user.bloodType,
      'emergencyContactName': user.emergencyContactName,
      'emergencyContactPhone': user.emergencyContactPhone,
      'isDeleted': user.isDeleted,
      'createdAt': user.createdAt?.toApiIso8601String(),
      'updatedAt': user.updatedAt?.toApiIso8601String(),
    };
  }
}
