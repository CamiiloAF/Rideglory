# REVIEW CHECKLIST — obs-fundaciones-crashlytics

**Generated:** 2026-06-04T03:45:21Z

Pasos que el humano corre antes de commitear.

---

## Automatizables (correr ahora)

- [ ] `dart analyze lib/` → debe retornar `No issues found`
- [ ] `flutter test` → debe retornar 210 passed, 0 failed
- [ ] `flutter test test/core/services/crash/crash_reporter_test.dart` → 9 passed
- [ ] `flutter test test/core/services/crash/crash_handler_setup_test.dart` → 5 passed
- [ ] `flutter test test/core/services/analytics/firebase_analytics_service_test.dart` → 5 passed
- [ ] G0 crashlytics: `grep -r "package:firebase_crashlytics" lib/ | grep -v "lib/core/services/crash/firebase_crash_reporter.dart" | grep -v "lib/core/di/firebase_module.dart" | grep -v "lib/core/di/injection.config.dart"` → 0 líneas
- [ ] G0 analytics: `grep -r "package:firebase_analytics" lib/ | grep -v "lib/core/services/analytics/firebase_analytics_service.dart" | grep -v "lib/core/di/firebase_module.dart" | grep -v "lib/core/di/injection.config.dart"` → 0 líneas
- [ ] Abstracciones puras: `grep "package:flutter" lib/core/services/crash/crash_reporter.dart` → 0; `grep "package:firebase" lib/core/services/crash/crash_reporter.dart` → 0

---

## Manuales (requieren device/build real)

- [ ] **PM-1:** Build release Android con keystore → `flutter build apk --release` → instalar APK → llamar `FirebaseCrashlytics.instance.crash()` → esperar ~5 min → crash simbolizado (stack legible) en Firebase Console > Crashlytics
- [ ] **PM-2:** Mismo en iOS (build release con firma) → crash simbolizado en consola Crashlytics iOS
- [ ] **PM-3:** `flutter run` (debug mode) → forzar excepción no capturada → NO debe aparecer reporte en Firebase console; logs no deben mostrar envío Crashlytics
- [ ] **PM-4:** Xcode > Runner > Build Phases → confirmar que "Firebase Crashlytics dSYM Upload" está presente y script = `"${PODS_ROOT}/FirebaseCrashlytics/run"`
- [ ] **PM-5:** Navegar todos los flujos de autenticación (email, Google, Apple) → sin cambio de comportamiento
- [ ] **PM-6:** Navegar shell completa (home, eventos, vehículos, perfil, mantenimiento) → árbol de navegación idéntico, sin regresiones

---

## Notas

- Los 2 lints en `lib/core/http/api_base_url_resolver.dart` (`shouldUseLocalApi=true`) son preexistentes — ignorar.
- Si `build_runner` falla en CI fresco: usar `dart run build_runner build --force-jit --delete-conflicting-outputs`.
- `injection.config.dart` ya regenerado — no editar a mano.
