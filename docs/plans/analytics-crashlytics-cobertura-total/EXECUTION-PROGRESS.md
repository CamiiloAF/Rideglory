# Progreso de ejecución — Analytics + Crashlytics

> Rama: `feat/analytics-crashlytics`
> Ancla de reanudación: si el PC se apaga, lee este archivo + `git log` para saber qué está hecho y qué sigue.
> Última actualización: 2026-06-04 (fases 1–7 commiteadas; fase 8 en curso). Nota: agentes Sonnet a veces se cortan a mitad; verifico (analyze+test) y completo antes de cada commit.

## Cómo reanudar
1. `git checkout feat/analytics-crashlytics`
2. Lee la tabla de abajo: la primera fila con estado distinto de `commiteada` es donde retomar.
3. Para fases `lite`: spawnear un agente Sonnet directo con el archivo de la fase en `phases/`.
   Para `normal`: igual, con revisión más cuidadosa (yo corro `dart analyze` + `flutter test` antes de commitear).
4. Tras verificar (compila + tests verdes), commitear esa fase y actualizar esta tabla.
5. Dependencias: todas las fases de instrumentación dependen de la taxonomía (fase 2) y de la fase 1.

## Estado por fase

| # | Fase | Nivel | Estado | Commit | Notas |
|---|------|-------|--------|--------|-------|
| 1 | Fundaciones (AnalyticsService/CrashReporter + init) | full | ✅ commiteada | 56b5801 | QA green, Tech Lead READY. CA-1 (crash simbolizado en release) = verificación manual. |
| 2 | Taxonomía centralizada + mapa rutas + límites GA4 | lite | ✅ commiteada | be98a8e | analytics_events/params/screen_names.dart; scan_soat alineado. |
| 3 | screen_view automático (NavigatorObserver) | lite | ✅ commiteada | be98a8e | Observer + ShellScreenViewTracker; dedupe por tab; 13 tests. |
| 4 | Captura de errores de red (no-fatales) | lite | ✅ commiteada | be98a8e | network_error_classifier + handlerExceptionHttp; 52 tests; G5 anti-doble-conteo ok. |
| 5 | Embudo adquisición: auth + onboarding | lite | ✅ commiteada | fb08e0e | 6 eventos + uid hasheado; 277 tests. |
| 6 | Embudo eventos — LECTURA (home/descubrir) | lite | ✅ commiteada | e92e5bf | 3 eventos + 20 tests; 297 total. |
| 7 | Embudo eventos — ESCRITURA y aprobación | lite | ✅ commiteada | 6bbce3f | 5 cubits, +19 eventos; 332 tests. |
| 8 | Tracking en vivo + SOS (solo hitos) | normal | 🟠 en curso | — | SOS safety-critical; revisión real. Solo hitos, cero pings WS. |
| 9 | Garaje, mantenimientos, SOAT, perfil, descubrimiento | lite | ⬜ pendiente | — | Amplio pero mecánico; se puede partir. |
| 10 | Auditoría no-PII transversal + doc QA | normal | ⬜ pendiente | — | Verificación de privacidad cross-cutting. |
| 11 | Privacidad: opt-out en perfil + política | normal | ⬜ pendiente | — | UI nueva + setEnabled debe desactivar bien analítica/crashlytics. |

Leyenda: ⬜ pendiente · 🟠 en curso · 🟡 hecha sin commitear · ✅ commiteada

## Decisiones fijas
- Stack cerrado: Firebase Analytics (GA4) + Crashlytics + capa propia en `core/`. Client-side; `rideglory-api` sin cambios.
- Modelos: implementación en Sonnet; auditoría/control de calidad en Opus.
- Sin PII en eventos ni claves de Crashlytics (uid hasheado; nunca email/nombre/placa/VIN/coords/ids crudos).
- Commit por fase en `feat/analytics-crashlytics`. No push ni PR sin pedirlo.
- No commitear `android/build/`, ni generados gitignored (`*.config.dart`, `pubspec.lock` — CI los regenera).
