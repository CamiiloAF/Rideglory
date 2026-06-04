# Plan: analytics-crashlytics-cobertura-total

> Estado: BORRADOR — revision humana pendiente. Generado: 2026-06-04T01:23:24Z

## Overview

Plan final consolidado de observabilidad end-to-end (Firebase Analytics GA4 + Crashlytics + capa abstracta en `core/`) para Rideglory, en 11 fases con única numeración 1..11. Las fases 1-9 son cero-UI/sin regresión; la única UI nueva es el opt-out (fase 11). Orden: fundaciones+gating+regla de capa (1) -> taxonomía+mapa de rutas+límites GA4 (2) -> dos palancas baratas: screen_view automático (3) y no-fatales de red en `handlerExceptionHttp` (4) -> embudos por dominio (5-9) -> auditoría no-PII+doc QA (10) y opt-out (11).

Aplica dos splits pedidos en review: legacy F6 (núcleo de eventos) se parte en lectura (6) y escritura/aprobación (7); legacy F10 se separa en auditoría/doc QA (10) y UI opt-out (11).

El documento `docs/plans/analytics-crashlytics-cobertura-total/05-sintesis.md` incluye: tabla CROSSWALK FX-legacy->ID, prosa de Cambios aplicados/Estado de captura/Riesgos normalizada a IDs 1..11 (corregido el item de opt-out para citar fase 11 y no confundir con la fase 10 de auditoría), touchpoints concretos de código por fase (`app_router.dart` L141 `StatefulShellRoute.indexedStack` + `GoRouter.observers`; `rest_client_functions.dart` `handlerExceptionHttp` L15-70), 2-5 criterios de aceptación observables y testeables por fase (DebugView + test con mock), alcance mínimo verificable por feature para la fase 9, y el chequeo explícito de dedupe de screen_view para el `StatefulShellRoute.indexedStack` (deduplicar al cambiar de tab, no solo en `pushReplacement`).

Touchpoints verificados en código: `app_router.dart` L141 (`StatefulShellRoute.indexedStack`, `GoRouter` sin observers en L63) y `rest_client_functions.dart` `handlerExceptionHttp` L15-70 con catch por tipo (Dio L21, FirebaseAuth L33, Platform L45, Domain L57, genérico L59).

## Fases

- Fase 1: [Fase 1 — Fundaciones de observabilidad, captura de crashes y regla de capa](phases/phase-01-fundaciones-de-observabilidad-captura-de-crashes.md)
- Fase 2: [Fase 2 — Taxonomía centralizada, mapa de rutas, límites GA4 y migración soat](phases/phase-02-taxonomia-centralizada-mapa-de-rutas-limites-ga4.md)
- Fase 3: [Fase 3 — Recorrido de pantallas automático (screen_view)](phases/phase-03-recorrido-de-pantallas-automatico-screen-view.md)
- Fase 4: [Fase 4 — Captura de errores y no-fatales de red](phases/phase-04-captura-de-errores-y-no-fatales-de-red.md)
- Fase 5: [Fase 5 — Embudos de adquisición: autenticación y onboarding](phases/phase-05-embudos-de-adquisicion-autenticacion-y-onboardin.md)
- Fase 6: [Fase 6 — Embudo del núcleo de eventos — LECTURA (home + descubrir/ver)](phases/phase-06-embudo-del-nucleo-de-eventos-lectura-home-descub.md)
- Fase 7: [Fase 7 — Embudo del núcleo de eventos — ESCRITURA y aprobación](phases/phase-07-embudo-del-nucleo-de-eventos-escritura-y-aprobac.md)
- Fase 8: [Fase 8 — Embudos de tracking en vivo y SOS (solo hitos)](phases/phase-08-embudos-de-tracking-en-vivo-y-sos-solo-hitos.md)
- Fase 9: [Fase 9 — Garaje, mantenimientos, SOAT, perfil, descubrimiento y notificaciones](phases/phase-09-garaje-mantenimientos-soat-perfil-descubrimiento.md)
- Fase 10: [Fase 10 — Auditoría no-PII transversal y documento de QA de analítica](phases/phase-10-auditoria-no-pii-transversal-y-documento-de-qa-d.md)
- Fase 11: [Fase 11 — Privacidad: opt-out en perfil y alineación de la política](phases/phase-11-privacidad-opt-out-en-perfil-y-alineacion-de-la-.md)

## Supuestos

- Stack cerrado (Firebase Analytics GA4 + Crashlytics + capa propia); no se reabre.
- Analítica **100% client-side**; `rideglory-api` **sin cambios** (uid hasheado en cliente, sin tocar `GET /me`).
- Regla de capa (fase 1) aplica a fases 2–9: abstracción `core` Dart-puro consumible por domain+presentación; SDK Firebase solo en `core/services/.../firebase_*`.
- Gating único (fase 1): no-op impl + `setEnabled(false)` + handlers no-report en `kDebugMode`, reutilizado por todas las fases.
- Verificación = DebugView/Crashlytics **+ test unitario con mock** en cada fase que añade call sites. La no-op impl la provee la fase 1.
- "Cobertura total" = los 11 features con embudo o interacciones clave instrumentadas; no implica loguear cada botón.
- Default de privacidad: **opt-in** (analítica anónima activa por defecto), opt-out explícito en perfil (fase 11). Performance/rendimiento percibido queda **fuera de alcance**.

## Riesgos

1. **Setup nativo de Crashlytics (fase 1).** Gradle Android + dSYM iOS frágiles; mal setup = crashes sin símbolos. *Mitigación*: criterio de aceptación = crash de prueba **simbolizado** en staging Android+iOS antes de cerrar la fase 1; documentar en handoff DevOps.
2. **Enganche equivocado en fase 4.** Si va en `executeService` se pierde categoría y stackTrace. *Mitigación*: la fase 4 fija `handlerExceptionHttp` (L15–70) como sitio único.
3. **Ruido / doble-conteo de no-fatales (fase 4).** *Mitigación*: política de severidad + matriz "categoría→único punto que reporta"; cubits no re-reportan errores de red.
4. **PII y alta cardinalidad.** Ids de evento/registro/rider, placa, VIN, aseguradora, coordenadas, email/nombre. *Mitigación*: taxonomía revisada (fase 2), uid hasheado (fase 5), auditoría transversal (fase 10); "ids canónicos de pantalla, nunca el valor dinámico".
5. **Volumen del tracking en vivo (fase 8).** *Mitigación*: solo hitos (start/stop/snapshot/SOS); cero pings ni mensajes WS.
6. **Gating insuficiente en tests/CI.** *Mitigación*: no-op + `setEnabled(false)` + handlers no-report en debug, verificado en fase 1 y reutilizado.
7. **Propagación de la anomalía de capa.** *Mitigación*: regla única de fase 1 (G0) verificada por el revisor de arquitectura antes de instrumentar features.
8. **Doble screen_view en el shell (fase 3).** El router usa `StatefulShellRoute.indexedStack` (`app_router.dart` L141): cambiar de tab puede emitir múltiples `screen_view`. *Mitigación*: el observer deduplica por activación de tab **y** en `pushReplacement`; nombres estables sin id desde el mapa de la fase 2.
9. **Fase 6 sobredimensionada (núcleo de eventos).** *Mitigación*: partida en lectura (fase 6) y escritura/aprobación (fase 7).
10. **Fase 9 que no cierra (muchos features).** *Mitigación*: alcance mínimo obligatorio vs nice-to-have fijado por feature en los criterios de aceptación.
11. **Fase 10/11 mezclando auditoría + UI + doc.** *Mitigación*: separadas — la auditoría no-PII y el doc QA (fase 10) no bloquean el opt-out (fase 11); hallazgos quedan como tareas.
12. **Opt-out con widget equivocado (fase 11).** `AppSwitchTile` exige `FormBuilder` y `ProfileActionsList` no es form. *Mitigación*: usar `AppSwitch` en fila/clase/archivo propios; knob "on" oscuro; estado de error revierte el switch.
13. **Versión `firebase_crashlytics` vs `firebase_core 4.x`.** *Mitigación*: resolver vía `pub` (no fijar a ciegas) + `flutter pub get` + `build_runner` en la fase 1.

## Como ejecutar una fase

> Cada fase se implementa con el workflow rg-exec apuntando a su archivo, por ejemplo:
> Workflow({ name: 'rg-exec', args: 'docs/plans/analytics-crashlytics-cobertura-total/phases/phase-01-fundaciones-de-observabilidad-captura-de-crashes.md' })
