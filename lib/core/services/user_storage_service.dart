import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      value: jsonEncode(UserDto.fromModel(user).toJson()),
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
}
