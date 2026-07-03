> Slim handoff — read this before handoffs/architect.md

# Architect → QA — legal-consentimientos-fase5

## Comandos
- `dart analyze` — comparar contra línea base de pre-flight (Build/Backend debe haberla capturado antes de tocar código); no debe haber errores NUEVOS.
- `flutter test` — debe pasar al 100%, incluyendo los 6 archivos de test listados en la fuente (2 modify + 4 create): `event_form_cubit_test.dart`, `publish_row_test.dart`, `event_organizer_responsibility_page_test.dart` (create), `medical_consent_cubit_test.dart` (create), `medical_consent_page_test.dart` (create), `user_storage_service_test.dart`.
- Tras tocar `UserService` (Retrofit): confirmar que `user_service.g.dart` quedó regenerado e incluye `acceptMedicalConsent` (AC#17).

## Trazabilidad de criterios de aceptación (17 AC, ver §5 del PRD)

**Bloque A (AC#1-7):** verificar especialmente:
- AC#2: modo edición NO cambia — reproducir edición de un evento existente y confirmar que sigue guardando directo sin pasar por `EventOrganizerResponsibilityPage`.
- AC#4: mismo objeto `DateTime` — no basta con que el timestamp "sea similar"; debe ser el MISMO valor capturado una sola vez (`DateTime.now()` en `_onAccept`), no dos capturas independientes en cubit y página.
- AC#5: mecanismo de doble-pop — al aceptar, la pantalla de responsabilidad hace pop, y `EventFormView` (debajo en el stack) hace un segundo pop protegido con `context.canPop()`. Verificar que el stack de navegación NO deja pantallas huérfanas (probar back-button tras publicar).

**Bloque B (AC#8-12):**
- AC#9: al autorizar, confirmar que se hace la llamada real `POST /users/me/medical-consent` (mockeada en tests) y que se persiste en `FlutterSecureStorage`, no `SharedPreferences`.
- AC#11: con caché ya presente (segunda sesión), el wizard NO debe interrumpir con `MedicalConsentPage` — probar guardando `medical_consent_accepted_at` de antemano.
- AC#10: "No autorizar" — verificar que NO se hace ninguna llamada HTTP (contar invocaciones del mock del repositorio en 0).

**Compartido (AC#13-17):**
- AC#13: `MedicalConsentCubit` es `@injectable` (no `@singleton`), y no hay ningún `getIt<MedicalConsentCubit>()` en widgets — debe inyectarse por `BlocProvider`.
- AC#14: un widget por archivo; grep por `Widget _build` o métodos que retornan `Widget` en los archivos nuevos debe dar 0 resultados.
- AC#15: grep de strings hardcodeados (comillas dentro de `Text(...)` sin `context.l10n`) en los 2 archivos de pantalla nuevos debe dar 0 resultados.
- AC#16/17: ya cubierto por comandos arriba.

## Puntos de riesgo específicos a probar manualmente/e2e
- Doble-tap en "Siguiente" del paso Personal mientras `MedicalConsentPage` está cargando — no debe disparar dos navegaciones ni dos POST.
- Interceptor de `_onNext()` NO debe activarse en las transiciones 1→2, 2→3 del wizard (solo 0→1).
- El trabajo en progreso de otra fase en `registration_form_content.dart`/`registration_form_cubit.dart` (validación de edad + waiver) NO debe haberse revertido ni roto — correr también los tests de esa área (`registration_form_cubit_age_validation_test.dart`, `registration_form_cubit_analytics_test.dart`, `registration_form_cubit_preload_test.dart`).
- Verificar que los `GoRoute` nuevos son hermanos del `StatefulShellRoute` (no anidados) — un test de navegación que confirme que el bottom nav sigue funcionando tras visitar `MedicalConsentPage`/`EventOrganizerResponsibilityPage`.

> Full detail: handoffs/architect.md
