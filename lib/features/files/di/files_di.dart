import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/di/dependency_injector.dart';
import '../../../../core/di/di_manager.dart';
import '../data/repositories/files_repository.dart';
import '../domain/repositories/files_repository_contract.dart';

class FilesDI implements DependencyInjector {
  @override
  void initializeDependencies() {
    DIManager.getIt.registerFactory<FilesRepositoryContract>(
      () => FilesRepository(
        storage: FirebaseStorage.instance,
      ),
    );
  }
}
