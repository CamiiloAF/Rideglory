import 'package:rideglory/core/firebase/collections_references.dart';

import '../../../../core/di/dependency_injector.dart';
import '../../../../core/di/di_manager.dart';
import '../data/repositories/sign_up_repository.dart';
import '../domain/repositories/sign_up_repository_contract.dart';

class SignUpDI implements DependencyInjector {
  @override
  void initializeDependencies() {
    DIManager.getIt.registerFactory<SignUpRepositoryContract>(
      () => SignUpRepository(
        userCollectionReference: CollectionsReferences.usersRef,
      ),
    );
  }
}
