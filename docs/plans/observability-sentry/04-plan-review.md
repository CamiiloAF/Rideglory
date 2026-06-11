# 04 — Plan Review (UX móvil + Calidad / Clean Architecture) — observability-sentry

- **Generado (UTC):** 2026-06-10T22:10:10Z
- **Autor:** Plan Reviewer
- **Insumos:** `00-intake.md`, `01-scan.md`, `02-po-proposal.md` (no hay archivo Architect 03 ni mockups de observabilidad)
- **Veredicto:** `ok_con_ajustes`

## Resumen del veredicto

El plan de 4 fases está bien dimensionado y respeta la única dependencia dura (traceId en Fase 1 → tracing distribuido en Fases 2 y 3). Es una feature **sin UI nueva**: el único punto de contacto visible es el tile de opt-out de analytics que **ya existe** (`profile_analytics_optout_tile.dart`). Por tanto, el grueso de la revisión es de **calidad / Clean Architecture** y de **dimensionamiento/scope**, no de UX de pantallas. Apruebo con ajustes; ninguno es bloqueante, pero varios deben quedar fijados antes de ejecutar para evitar deuda y reproceso (especialmente el shape del traceId TCP y el gating dev/prod).

## UX por fase

Feature de plataforma/observabilidad: la mayoría de fases no tocan pantalla. Reviso los estados (idle/loading/empty/error) solo donde hay superficie de usuario o impacto perceptible.

- **Fase 1 (Backend logs + traceId):** sin UI. Impacto de usuario nulo salvo que el `traceId` empiece a viajar en headers/cuerpo de error. **UX a cuidar:** que el `traceId` que vuelve al cliente **no** se filtre a un mensaje visible al usuario. Los mensajes de error de la app deben seguir saliendo de `rest_client_functions.dart` (español, sin códigos crudos); el `traceId` se adjunta como dato técnico (breadcrumb/tag Sentry en Fase 3), nunca como copy en pantalla.
- **Fase 2 (Backend Sentry):** sin UI. Verificable solo por dashboards Sentry + logs. Sin estados móviles.
- **Fase 3 (Flutter Sentry):** sin pantalla nueva. **Estados a preservar:** el flujo error de red ya mapeado en `network_error_classifier.dart` → `executeService` → `ResultState.error` → UI no debe cambiar de comportamiento visible. El usuario debe ver exactamente los mismos mensajes (idle/loading/empty/error) que hoy; Sentry es transparente. **Gate UX:** ningún 4xx de negocio debe degradar la experiencia ni alterar el copy; Sentry no introduce diálogos, toasts ni overlays.
- **Fase 4 (Insights):** único punto con UI real, y **ya implementada** (tile de opt-out en Profile). **UX a verificar contra 375px y touch targets:**
  - El tile de opt-out debe seguir siendo `AppSwitchTile` (regla switch unificado), knob/acento con texto oscuro sobre primario, target táctil ≥44px. No introducir `Switch`/`SwitchListTile`/`FormBuilderSwitch`.
  - Los nuevos "taps de botones clave" se instrumentan **en los botones existentes** (`AppButton`/`AppTextButton`); no se crean botones nuevos ni se altera el layout. El tracking debe colgar del `onPressed` actual o del Cubit, sin envolver widgets en GestureDetectors extra que roben el área táctil.
  - Si la documentación del catálogo expusiera una pantalla de "consentimiento" o aviso, debe respetar dark theme + español; pero el plan **no** la pide y no debería añadirla (ver Riesgos de scope).

## Gates de calidad

Aplican a cada fase; PASS/FAIL se evalúa en ejecución.

**Flutter (Fases 3 y 4):**
- **Clean Architecture:** `SentryCrashReporter` se registra por `@Injectable(as: CrashReporter)` y vive en `core/services/crash/` (capa data/infra). La interface `CrashReporter` permanece Dart puro y **único punto de acoplamiento**; presentation/domain nunca importan `sentry_flutter`. Igual para analytics: solo la impl concreta conoce el SDK.
- **DI sin singletons artesanales:** la dependencia a `FirebaseCrashlytics` en `firebase_module.dart` (incluyendo `setCustomKey('api_base_url', ...)`) se migra a la abstracción, no a otro `getIt` directo. Cubits siguen `@injectable` + BlocProvider (no tocar ese patrón).
- **Un widget por archivo / sin métodos que retornan widgets:** la Fase 4 no debe introducir helpers `Widget _build...()` al instrumentar taps. Si hace falta envolver, es una clase widget propia o un callback en el Cubit.
- **Sin PII en código:** la denylist (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN) debe estar **centralizada** (una constante/lista, no repetida por callsite) y cubierta por test.
- **Gating dev/prod por flavor:** `SentryFlutter.init` con DSN vacío + `beforeSend→null` en dev; reusar el patrón existente `setEnabled(!kDebugMode)`. **Test:** verificar que en debug/test no se inicializa Sentry (reusar `NoOpCrashReporter`).
- **Sin ventana sin crashes:** Crashlytics solo se retira (pubspec + `firebase_module` + nativo iOS/Android) **después** de validar Sentry. Orden explícito en la fase.
- **Doble reporte:** test/decisión documentada sobre la interacción `SentryFlutter.init` ↔ `crash_handler_setup.dart` ↔ `runZonedGuarded`. Definir quién captura qué (handler vs. integración Sentry) para no duplicar.
- **Lint/test:** `dart analyze` limpio y `flutter test` verde al cierre de cada fase Flutter. Recordatorio memoria: ignorar los 2 lints conocidos de `api_base_url_resolver.dart` (hack local del usuario), no "arreglarlos".

**Backend (Fases 1 y 2):**
- **No copy-paste ×6:** `instrument.ts` + `SentryModule` + joi (`NODE_ENV`/`SENTRY_DSN`) deben abstraerse en `rideglory-common-lib` (ya alberga los filtros). Divergencia entre los 6 servicios es FAIL.
- **Contracts:** todo cambio de shape de message pattern para `traceId` pasa por `@rideglory/contracts` con el gotcha de rebuild documentado (`npm run build` + reinstalar en cada MS). Shape envolvente retrocompatible y migración atómica.
- **Redacción PII:** denylist + allowlist verificadas por test antes de habilitar prod. El interceptor de pino no debe loguear cuerpos sin redactar.
- **Gating prod:** Sentry backend solo activo con `NODE_ENV==='production'`; en dev → consola (`pino-pretty`).
- **4xx:** loguear 4xx (hoy solo ≥500) en `RpcCustomExceptionFilter` pero **no** reportarlos a Sentry (sin ruido); 5xx sí. Verificable.
- **Build/tests backend** verdes tras cada fase; cada fase deja ambas apps desplegables.

## Riesgos de scope

- **Fase 1 es la más pesada y la mal-etiquetada como "logs legibles".** El traceId end-to-end por TCP (greenfield, toca `@rideglory/contracts` y los 5 MS) es el verdadero núcleo de esfuerzo/riesgo, no pino. Riesgo de subdimensionar. **Recomendación:** que el Architect fije el shape `{data, meta:{traceId}}` (o alternativa) **antes** de abrir la fase; si el cambio de contracts resulta grande, considerar separar "pino + logging gateway" de "propagación TCP" en dos sub-entregas dentro de la fase.
- **Fase 3 mezcla 3 cosas con riesgos distintos:** init Sentry + `dio.addSentry()`/tracePropagation + retiro de Crashlytics (incl. nativo iOS/Android). El retiro nativo (Podfile, `project.pbxproj`, Gradle) es config/build de alto roce. Está OK en una fase, pero el **orden interno** (integrar y validar Sentry → luego retirar Crashlytics) debe ser explícito para no dejar ventana sin cobertura.
- **Fase 4 puede expandirse sin control.** "Taps clave" + "drop-off por step" + "catálogo documentado" es incremental, pero el riesgo es scope creep hacia PostHog/dashboards/pantallas de consentimiento nuevas. El plan ya marca PostHog fuera de alcance y la fase como incremental: **mantenerlo**. No crear UI nueva; reusar el opt-out existente.
- **Cuota Sentry free (5k/mes):** la decisión proyecto-por-servicio vs. tag `service` (afecta cuota) y el sampling son del Architect; si no se fijan, la Fase 2 podría agotar cuota. Es decisión, no bloqueo, pero debe estar resuelta antes de ejecutar Fase 2.
- **Decisiones arquitectónicas abiertas sin archivo Architect:** no existe `03-architect.md` en el directorio del plan. Cinco decisiones (shape TCP, proyecto-vs-tag Sentry, sampling, gestión DSN por flavor/CI, allowlist/denylist exacta) están delegadas al Architect pero aún sin resolver. **Riesgo de planeación:** ejecutar fases con estas decisiones abiertas genera reproceso. Deben cerrarse antes de `rg-exec` de la fase correspondiente.

## Ajustes

1. **Renombrar/reencuadrar el goal de Fase 1** para reflejar que el traceId distribuido por TCP (no pino) es el núcleo, y exigir que el shape del payload lo fije el Architect **antes** de ejecutar. Considerar sub-entregas si el cambio de contracts es grande.
2. **Fijar orden interno explícito en Fase 3:** (a) añadir deps + `SentryCrashReporter` + `SentryFlutter.init` gated, (b) validar reporte en prod-like, (c) `dio.addSentry()` + tracePropagation, (d) recién entonces retirar Crashlytics (pubspec + `firebase_module` + nativo iOS/Android). Cero ventana sin crashes.
3. **Centralizar la denylist PII** en una sola fuente compartida (no por callsite) tanto en Flutter como en backend, con test que falle si un campo de la denylist aparece sin redactar en un payload de log/evento.
4. **Documentar la decisión de doble reporte** (handlers globales ↔ `runZonedGuarded` ↔ integración Sentry) como entregable de la Fase 3, con test del gating debug/prod (Sentry no inicializa en debug/test; `NoOpCrashReporter` activo).
5. **Abstraer el patrón Sentry backend en `rideglory-common-lib`** (instrument + módulo + joi `NODE_ENV`/`SENTRY_DSN`) como criterio de aceptación de Fase 2, no como "nice to have", para evitar divergencia ×6.
6. **Fase 4: respetar el switch unificado y texto oscuro sobre primario** en el tile de opt-out existente; instrumentar taps en `AppButton`/`AppTextButton`/Cubits sin añadir GestureDetectors ni helpers que retornen widgets, sin pantallas nuevas. Entregar el catálogo de eventos como doc (markdown), no como UI.
7. **Garantizar que el `traceId` que vuelve al cliente nunca aparece como copy visible**; los mensajes de error siguen saliendo en español de `rest_client_functions.dart`. El `traceId` es metadato técnico (tag/breadcrumb Sentry), no texto de pantalla.
8. **Cerrar las 5 decisiones del Architect antes de ejecutar** (shape TCP, proyecto-vs-tag Sentry, sampling, DSN por flavor/CI, allowlist/denylist). Bloquear el inicio de cada fase hasta tener la decisión que le aplica.
