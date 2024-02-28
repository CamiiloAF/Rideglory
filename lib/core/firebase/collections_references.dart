import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/users/domain/entities/user_model.dart';

abstract class CollectionsReferences {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<UserModel> get usersRef =>
      _firestore.collection('users').withConverter(
        fromFirestore: (final snapshots, final _) {
          return UserModel.fromJson(snapshots.data()!);
        },
        toFirestore: (final user, final _) {
          return user.toJson();
        },
      );
}
