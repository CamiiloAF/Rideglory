import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../exceptions/domain_exception.dart';
import '../http/rest_client_functions.dart';

@injectable
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService(this._firebaseAuth, this._googleSignIn);

  /// Get the current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign up with email and password
  Future<Either<DomainException, User?>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return executeService<User?>(
      function: () async {
        final userCredential = await _firebaseAuth
            .createUserWithEmailAndPassword(email: email, password: password);
        return userCredential.user;
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
  Future<Either<DomainException, User?>> signInWithGoogle() async {
    return executeService<User?>(
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
        return userCredential.user;
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
}
