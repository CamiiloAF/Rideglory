import 'package:dartz/dartz.dart';

import '../../../core/exceptions/domain_exception.dart';

/// Autenticación contra Supabase Auth. La sesión resultante la observa
/// `AuthCubit` (en `core/auth`) vía `onAuthStateChange`; este repositorio
/// solo dispara las acciones, nunca expone el `Session`/`User` de Supabase
/// hacia `presentation`.
abstract class AuthRepository {
  Future<Either<DomainException, void>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<DomainException, void>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  });

  Future<Either<DomainException, void>> signInWithGoogle();

  Future<Either<DomainException, void>> signInWithApple();

  Future<Either<DomainException, void>> sendPasswordResetEmail({
    required String email,
  });

  Future<void> signOut();
}
