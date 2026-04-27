import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';

import '../exceptions/domain_exception.dart';
import '../http/rest_client_functions.dart';

@injectable
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;
  UserModel? _currentApiUser;

  AuthService(this._firebaseAuth, this._googleSignIn, this._userRepository);

  /// Get the current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;
  UserModel? get currentApiUser => _currentApiUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign up with email and password
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

        final apiUser = await _registerApiUser(
          fullName: fullName,
          email: email,
        );
        _currentApiUser = apiUser;

        return AuthenticatedUser(
          firebaseUser: _firebaseAuth.currentUser ?? firebaseUser,
          apiUser: apiUser,
          isNewUser: true,
        );
      },
    );
  }

  /// Sign in with email and password
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
        return userCredential.user;
      },
    );
  }

  /// Sign in with Google
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
        UserModel? apiUser;
        if (isNewUser) {
          final email = firebaseUser.email;
          if (email == null || email.isEmpty) {
            throw const DomainException(
              message: 'No pudimos obtener el correo de tu cuenta.',
            );
          }

          apiUser = await _registerApiUser(
            fullName: _resolveFullName(firebaseUser),
            email: email,
          );
          _currentApiUser = apiUser;
        }

        return AuthenticatedUser(
          firebaseUser: firebaseUser,
          apiUser: apiUser,
          isNewUser: isNewUser,
        );
      },
    );
  }

  /// Sign in with Apple
  Future<Either<DomainException, User?>> signInWithApple() async {
    // TODO: Implement Apple sign-in when sign_in_with_apple is enabled
    return const Left(
      DomainException(message: 'Apple sign-in is not yet implemented'),
    );
    // return executeService<User?>(
    //   function: () async {
    //     final credential = await SignInWithApple.getAppleIDCredential(
    //       scopes: const [],
    //     );
    //
    //     final oauthCredential = OAuthProvider('apple.com').credential(
    //       idToken: credential.identityToken,
    //       accessToken: credential.authorizationCode,
    //     );
    //
    //     final userCredential = await _firebaseAuth.signInWithCredential(
    //       oauthCredential,
    //     );
    //     return userCredential.user;
    //   },
    // );
  }

  /// Sign out
  Future<Either<DomainException, Unit>> signOut() async {
    return executeService<Unit>(
      function: () async {
        await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
        _currentApiUser = null;
        return unit;
      },
    );
  }

  /// Send password reset email
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

  /// Update user email
  Future<Either<DomainException, Unit>> updateEmail(String newEmail) async {
    return executeService<Unit>(
      function: () async {
        await currentUser?.verifyBeforeUpdateEmail(newEmail);
        return unit;
      },
    );
  }

  /// Update user password
  Future<Either<DomainException, Unit>> updatePassword(
    String newPassword,
  ) async {
    return executeService<Unit>(
      function: () async {
        await currentUser?.updatePassword(newPassword);
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

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.firebaseUser,
    required this.isNewUser,
    this.apiUser,
  });

  final User firebaseUser;
  final UserModel? apiUser;
  final bool isNewUser;
}
