# Objetivo: Analíticas + Crashlytics (observabilidad de producto, cobertura total)

## Qué queremos lograr
Instrumentar **toda** la app Rideglory para recolectar cómo los usuarios recorren los flujos, qué
elementos usan y cuáles no, dónde abandonan, qué errores y fallas ocurren — y capturar crashes — para
poder mejorar el producto con datos.

## Stack decidido (no reabrir)
- **Firebase Analytics** (Google Analytics 4) para eventos de producto. Ya usamos firebase_core/auth/firestore/storage/remote_config.
- **Firebase Crashlytics** para crashes, errores no fatales y diagnósticos.
- **Capa propia `AnalyticsService`** que abstrae el SDK (interfaz en core, impl Firebase). La presentación
  NUNCA llama al SDK directo; loguea vía la abstracción. Permite test doubles y cambiar de proveedor.
- Habilitar **BigQuery export** / GA4 funnels para análisis de flujos.

## Qué información hay que recolectar
1. **Flujos que recorre el usuario y cómo**: `screen_view` automático (NavigatorObserver de go_router) +
   eventos de paso clave por flujo (inicio, avance, éxito, abandono).
2. **Qué elementos usan / cuáles no**: eventos de interacción en elementos relevantes (botones, tabs,
   filtros, switches, bottom sheets, CTAs) con una taxonomía consistente.
3. **Dónde y por qué abandonan**: embudos por flujo (auth, crear evento, registrarse a evento,
   tracking en vivo/SOS, garage/vehículos, mantenimientos, perfil/usuarios) con eventos de drop-off.
4. **Errores y fallas**: errores de red/HTTP (DomainException), validaciones fallidas, estados Error de
   `ResultState`, y **crashes** + no-fatales vía Crashlytics con contexto (user id hasheado, pantalla, acción).
5. **Rendimiento percibido**: tiempos de carga clave donde aporte (opcional por fase).

## Alcance
**Cobertura total**: todas las features de `lib/features/` y cada elemento interactivo relevante, planeado
por fases entregables (no big-bang). Cada fase deja la app funcional y aporta datos accionables.

## Constraints
- Clean Architecture: `AnalyticsService`/`CrashReporter` en core/domain; impl en data; presentación usa la abstracción.
- **Privacidad**: nada de PII en eventos ni en claves de Crashlytics (no emails, no nombres, no placas en claro;
  user id hasheado/anónimo). Respetar la política de privacidad ya publicada.
- Taxonomía de eventos **documentada y centralizada** (constantes, sin strings mágicos dispersos).
- Strings de UI en `app_es.arb` (si se agrega UI de consentimiento/opt-out).
- Considerar **consentimiento/opt-out** de analítica si aplica para Play Store/App Store.
- Debe poder desactivarse en debug/desarrollo y en tests.

## Criterios de éxito (alto nivel)
- Existe una capa `AnalyticsService` + `CrashReporter` con impl Firebase, inyectada por DI, testeable.
- `screen_view` automático cubre todas las rutas de go_router.
- Cada flujo crítico tiene su embudo definido con eventos de inicio→avance→éxito/abandono.
- Crashlytics captura fatales y no-fatales con contexto suficiente para diagnosticar.
- Taxonomía de eventos centralizada y documentada; sin PII.
- Se puede verificar en GA4 DebugView / consola de Crashlytics.
