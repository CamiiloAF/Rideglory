import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Config global de tests: Flutter la carga automáticamente para todo
/// `test/`.
///
/// Nota (trampa conocida, ver CLAUDE.md): los golden tests con
/// `google_fonts` deben desactivar `GoogleFonts.config.allowRuntimeFetching`
/// y empaquetar la fuente Outfit como asset de test — si no, se generan con
/// la fuente de fallback y la fidelidad visual queda invalidada sin que
/// ningún test falle. Eso lo resuelve el helper compartido
/// `test/support/golden_helpers.dart` cuando aparezcan los primeros
/// goldens (F5+); aquí solo se garantiza el binding para tests no-golden.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await testMain();
}
