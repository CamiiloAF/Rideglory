import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Produce el identificador anónimo de usuario para Firebase Analytics.
///
/// **Política de privacidad:** nunca se envía el uid de Firebase en claro.
/// Se calcula un hash SHA-256 (64 caracteres hex) únicamente en cliente y
/// ese hash — sin correlación con el uid original — se pasa a [setUserId].
///
/// Ref: Fase 5 — Embudos de adquisición (auth / onboarding).
abstract final class AnalyticsUidHasher {
  /// Devuelve el SHA-256 hex del [firebaseUid] (64 chars).
  ///
  /// Garantiza que el uid en claro nunca sale del dispositivo como dato de
  /// telemetría. El hash es determinista dentro de la misma sesión de
  /// Firebase pero no reversible.
  static String hash(String firebaseUid) {
    final bytes = utf8.encode(firebaseUid);
    return sha256.convert(bytes).toString();
  }
}
