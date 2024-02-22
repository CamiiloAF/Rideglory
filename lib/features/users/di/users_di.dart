import 'package:firebase_auth/firebase_auth.dart';
import 'package:rideglory/core/firebase/collections_references.dart';
import 'package:rideglory/features/users/data/repositories/users_repository.dart';
import 'package:rideglory/features/users/domain/repositories/users_repository_contract.dart';

import '../../../../core/di/dependency_injector.dart';
import '../../../../core/di/di_manager.dart';

class UsersDI implements DependencyInjector {
  @override
  void initializeDependencies() {
    DIManager.getIt.registerFactory<UsersRepositoryContract>(
      () => UsersRepository(
        userCollectionReference: CollectionsReferences.usersRef,
        auth: FirebaseAuth.instance,
      ),
    );
  }
}
