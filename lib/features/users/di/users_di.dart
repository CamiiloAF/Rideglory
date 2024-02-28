import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/di/dependency_injector.dart';
import '../../../../core/di/di_manager.dart';
import '../../../core/firebase/collections_references.dart';
import '../data/repositories/users_repository.dart';
import '../domain/repositories/users_repository_contract.dart';

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
