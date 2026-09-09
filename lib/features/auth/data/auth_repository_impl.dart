import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/exceptions/domain_exception.dart';
import '../domain/auth_error_code.dart';
import '../domain/auth_repository.dart';
import 'auth_error_mapper.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._supabaseClient, this._googleSignIn);

  final supabase.SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  @override
  Future<Either<DomainException, void>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return const Right(null);
    } catch (error) {
      return Left(mapAuthError(error));
    }
  }

  @override
  Future<Either<DomainException, void>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return const Right(null);
    } catch (error) {
      return Left(mapAuthError(error));
    }
  }

  @override
  Future<Either<DomainException, void>> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return const Left(
          DomainException(message: AuthErrorCode.providerCancelled),
        );
      }
      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return const Left(DomainException(message: AuthErrorCode.unknown));
      }
      await _supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      return const Right(null);
    } catch (error) {
      return Left(mapAuthError(error));
    }
  }

  @override
  Future<Either<DomainException, void>> signInWithApple() async {
    try {
      final rawNonce = _generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        return const Left(DomainException(message: AuthErrorCode.unknown));
      }
      await _supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return const Right(null);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const Left(
          DomainException(message: AuthErrorCode.providerCancelled),
        );
      }
      return const Left(DomainException(message: AuthErrorCode.unknown));
    } catch (error) {
      return Left(mapAuthError(error));
    }
  }

  @override
  Future<Either<DomainException, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
      return const Right(null);
    } catch (error) {
      return Left(mapAuthError(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Nonce aleatorio para el flujo de Apple (`signInWithIdToken` compara su
  /// hash contra el `nonce` embebido en el `identityToken`).
  String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
