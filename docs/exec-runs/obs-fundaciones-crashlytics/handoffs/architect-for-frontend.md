> Slim handoff — lee esto antes de docs/exec-runs/obs-fundaciones-crashlytics/handoffs/architect.md

# Architect → Frontend (obs-fundaciones-crashlytics)

**No hay UI nueva. No hay widgets. No hay pantallas.** Esta fase es 100% infraestructura.

---

## Archivos a crear

### `lib/core/services/crash/crash_reporter.dart`
Interfaz Dart puro (sin imports Flutter/Firebase):
```dart
abstract class CrashReporter {
  Future<void> recordError(Object exception, StackTrace? stack, {String? reason, bool fatal = false});
  Future<void> setEnabled(bool enabled);
}
```

### `lib/core/services/crash/firebase_crash_reporter.dart`
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';
import 'crash_reporter.dart';

@Injectable(as: CrashReporter)
class FirebaseCrashReporter implements CrashReporter { ... }
```
ÚNICO archivo que importa `package:firebase_crashlytics`. Invariante G0.

### `lib/core/services/crash/no_op_crash_reporter.dart`
```dart
@Injectable(as: CrashReporter, env: [Environment.test])
class NoOpCrashReporter implements CrashReporter { ... }
```
Todos los métodos con body vacío `async {}`.

---

## Archivos a modificar

### `pubspec.yaml`
Añadir bajo `# Firebase`:
```yaml
firebase_crashlytics: ^4.3.0  # verificar versión compatible con firebase_core ^4.2.1
```
Ejecutar: `flutter pub add firebase_crashlytics`

### `lib/core/services/analytics/analytics_service.dart`
Añadir métodos con default body vacío (non-breaking — no rompe `ScanSoatUseCase`):
```dart
Future<void> logScreenView(String screenName) async {}
Future<void> setUserId(String hashedId) async {}
Future<void> setUserProperty(String name, String value) async {}
Future<void> setEnabled(bool enabled) async {}
```

### `lib/core/services/analytics/firebase_analytics_service.dart`
Implementar las 4 firmas nuevas delegando al SDK de `FirebaseAnalytics`.

### `lib/core/di/firebase_module.dart`
Añadir:
```dart
@lazySingleton
FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance;
```

### `lib/main.dart`
Orden obligatorio (no alterar):
1. Firebase.initializeApp + FCM + RemoteConfig + DateFormatting + Mapbox (sin cambio)
2. `configureDependencies()` — DI se inicializa aquí; `getIt<CrashReporter>()` disponible a partir de este punto
3. Init defensivo: `try { await getIt<CrashReporter>().setEnabled(!kDebugMode); } catch (_) {}`
4. Registrar `FlutterError.onError` y `PlatformDispatcher.instance.onError` con gating `if (!kDebugMode)` — los closures pueden usar `getIt<CrashReporter>()` porque DI ya está lista
5. `runZonedGuarded(() => runApp(const MyApp()), handler)` — handler reporta `fatal: false` si `!kDebugMode`

**NUNCA** llamar `getIt<CrashReporter>()` antes de `configureDependencies()`. Ver snippet completo en architect.md §Contratos.

---

## Después de crear los nuevos archivos

```bash
dart run build_runner build --delete-conflicting-outputs
# (usar --force-jit si falla en worktree fresco)
dart analyze
flutter test
```

`injection.config.dart` se regenera automáticamente — NO lo edites a mano.

---

## Verificaciones G0 (deben pasar con 0 coincidencias fuera de los archivos legítimos)

```bash
# firebase_module.dart e injection.config.dart son legítimos (DI infra + código generado)
grep -r "package:firebase_crashlytics" lib/ \
  | grep -v "lib/core/services/crash/firebase_crash_reporter.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"

grep -r "package:firebase_analytics" lib/ \
  | grep -v "lib/core/services/analytics/firebase_analytics_service.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"
```

---

## Nativo Android (Frontend no toca — ver architect.md §Android)

`android/settings.gradle.kts` y `android/app/build.gradle.kts` los modifica el mismo agente si tiene acceso a Gradle, o se documentan para el humano.

## Sin localization keys

No hay strings visibles para el usuario en esta fase.

> Full detail: docs/exec-runs/obs-fundaciones-crashlytics/handoffs/architect.md
