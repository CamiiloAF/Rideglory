import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rideglory/core/models/user_model.dart';

abstract class CollectionsReferences {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<UserModel> get usersRef =>
      _firestore.collection('users').withConverter(
        fromFirestore: (snapshots, _) {
          return UserModel.fromJson(
            snapshots.data()!
              ..addAll(
                {'id': snapshots.id},
              ),
          );
        },
        toFirestore: (dynamic user, _) {
          return user!.toJson();
        },
      );
}
