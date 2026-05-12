import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/models/authenticated_user.dart';
import 'package:rideglory/core/services/user_storage_service.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';

import '../exceptions/domain_exception.dart';
import '../http/rest_client_functions.dart';

/// One shared instance: `currentUser` is in-memory; factories would leave
/// `getIt<AuthService>().currentUser` null outside login/splash graph.
@singleton
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;
  final UserStorageService _userStorageService;
  UserModel? _currentUser;

  AuthService(
    this._firebaseAuth,
    this._googleSignIn,
    this._userRepository,
    this._userStorageService,
  );
  UserModel? get currentUser => _currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<Either<DomainException, AuthenticatedUser>> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return executeService<AuthenticatedUser>(
      function: () async {
        final userCredential = await _firebaseAuth
            .createUserWithEmailAndPassword(email: email, password: password);
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) {
          throw const DomainException(
            message: 'Falló el registro, intenta de nuevo más tarde',
          );
        }

        await firebaseUser.updateDisplayName(fullName);
        await firebaseUser.reload();

        final user = await _registerApiUser(fullName: fullName, email: email);
        await _cacheUser(firebaseUser.uid, user);

        return AuthenticatedUser(
          firebaseUser: _firebaseAuth.currentUser ?? firebaseUser,
          user: user,
          isNewUser: true,
        );
      },
    );
  }

  Future<Either<DomainException, User?>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return executeService<User?>(
      function: () async {
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final firebaseUser = userCredential.user;
        if (firebaseUser != null) {
          await _loadStoredUser(firebaseUser.uid);
        }

        return firebaseUser;
      },
    );
  }

  Future<Either<DomainException, AuthenticatedUser>> signInWithGoogle() async {
    return executeService<AuthenticatedUser>(
      function: () async {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw PlatformException(
            code: 'sign_in_cancelled',
            message: 'Google sign-in was cancelled',
          );
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) {
          throw const DomainException(message: 'Google sign-in failed');
        }

        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        UserModel? user;
        if (isNewUser) {
          final email = firebaseUser.email;
          if (email == null || email.isEmpty) {
            throw const DomainException(
              message: 'No pudimos obtener el correo de tu cuenta.',
            );
          }

          user = await _registerApiUser(
            fullName: _resolveFullName(firebaseUser),
            email: email,
          );
          await _cacheUser(firebaseUser.uid, user);
        } else {
          user = await _loadStoredUser(firebaseUser.uid);
        }

        return AuthenticatedUser(
          firebaseUser: firebaseUser,
          user: user,
          isNewUser: isNewUser,
        );
      },
    );
  }

  Future<Either<DomainException, User?>> signInWithApple() async {
    return const Left(
      DomainException(
        message: 'Apple sign-in no está disponible en esta versión',
      ),
    );
  }

  Future<Either<DomainException, Unit>> signOut() async {
    return executeService<Unit>(
      function: () async {
        await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
        _currentUser = null;
        return unit;
      },
    );
  }

  Future<Either<DomainException, String>> getCurrentUserId() async {
    final cachedUser = _currentUser;
    if (cachedUser != null) {
      return Right(cachedUser.id);
    }

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return const Left(DomainException(message: 'No hay una sesión activa.'));
    }

    final storedUser = await _loadStoredUser(firebaseUser.uid);
    if (storedUser == null) {
      return const Left(
        DomainException(
          message:
              'No encontramos la información local del usuario. Cierra sesión e inicia de nuevo.',
        ),
      );
    }

    return Right(storedUser.id);
  }

  Future<Either<DomainException, UserModel?>> loadCurrentUser() {
    return executeService<UserModel?>(
      function: () async {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser == null) {
          _currentUser = null;
          return null;
        }

        return _loadStoredUser(firebaseUser.uid);
      },
    );
  }

  Future<Either<DomainException, Unit>> sendPasswordResetEmail(
    String email,
  ) async {
    return executeService<Unit>(
      function: () async {
        await _firebaseAuth.sendPasswordResetEmail(email: email);
        return unit;
      },
    );
  }

  Future<Either<DomainException, Unit>> updateEmail(String newEmail) async {
    return executeService<Unit>(
      function: () async {
        await _firebaseAuth.currentUser?.verifyBeforeUpdateEmail(newEmail);
        return unit;
      },
    );
  }

  Future<Either<DomainException, Unit>> updatePassword(
    String newPassword,
  ) async {
    return executeService<Unit>(
      function: () async {
        await _firebaseAuth.currentUser?.updatePassword(newPassword);
        return unit;
      },
    );
  }

  Future<UserModel> _registerApiUser({
    required String fullName,
    required String email,
  }) async {
    final result = await _userRepository.registerUser(
      fullName: fullName,
      email: email,
    );

    return result.fold((failure) => throw failure, (user) => user);
  }

  Future<void> _cacheUser(String firebaseUid, UserModel user) async {
    _currentUser = user;
    await _userStorageService.saveUser(firebaseUid: firebaseUid, user: user);
  }

  Future<UserModel?> _loadStoredUser(String firebaseUid) async {
    final stored = await _userStorageService.getUser(firebaseUid);
    if (stored != null) {
      _currentUser = stored;
      return stored;
    }

    final result = await _userRepository.getCurrentUser();
    final apiUser = result.fold((_) => null, (u) => u);
    if (apiUser != null) {
      await _cacheUser(firebaseUid, apiUser);
    }
    return apiUser;
  }

  String _resolveFullName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Rider';
  }
}
