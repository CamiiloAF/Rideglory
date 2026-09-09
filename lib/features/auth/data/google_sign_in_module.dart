import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

/// Registra el cliente de `google_sign_in` que consume [AuthRepositoryImpl].
@module
abstract class GoogleSignInModule {
  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn(scopes: ['email']);
}
