# 02 — Propuesta del PO: Analíticas + Crashlytics (cobertura total)

- Slug: `analytics-crashlytics-cobertura-total`
- Fecha (UTC): 2026-06-04T00:51:09Z
- Insumos: `00-intake.md`, `01-scan.md`
- Sesión: PLANEACIÓN (no se modifica código de la app)

## Marco de la propuesta

El objetivo es dotar a Rideglory de **observabilidad de producto end-to-end** (cómo
se recorren los flujos, qué se usa, dónde se abandona, qué errores/crashes ocurren)
con el stack ya decidido (Firebase Analytics GA4 + Crashlytics) y una capa propia
abstracta inyectada por DI. La entrega es **incremental**: cada fase deja la app
funcional, sin regresiones de comportamiento de usuario, y aporta datos accionables
verificables (GA4 DebugView / consola Crashlytics) desde su cierre.

Las fases se ordenan para que las **dos palancas más baratas y de mayor cobertura**
(screen_view automático en las ~37 rutas, y no-fatales centralizados en la capa HTTP)
lleguen temprano, y la instrumentación de embudo por feature ocurra sobre una
**taxonomía ya centralizada y documentada**, evitando strings mágicos y reprocesos.

El valor se expresa siempre como **comportamiento observable del usuario móvil y del
analista de producto** (qué podrá ver/medir), no como tareas técnicas sueltas.

## Fases propuestas

| ID | Título | Goal (valor en una frase) | Resumen |
|----|--------|---------------------------|---------|
| 1 | Fundaciones de observabilidad y captura de crashes | El equipo recibe automáticamente los crashes (fatales y no-fatales) de cualquier usuario sin que la app cambie su comportamiento. | Añadir `firebase_crashlytics` (+setup nativo Android/iOS). Ampliar `AnalyticsService` (logScreenView, setUserId, setUserProperty, setEnabled/gating). Crear abstracción `CrashReporter` + impl Crashlytics (recordError fatal/no-fatal, log, setCustomKey). Proveer ambos por DI en `firebase_module.dart`. Cablear `main.dart` con `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`, con **gating en debug/tests** (no-op / colección desactivada). Fijar la **regla de capa** del `AnalyticsService`/`CrashReporter` (pregunta abierta #1) y dejar no-op impl para tests. App idéntica para el usuario; verificable forzando un crash de prueba en build de staging. |
| 2 | Taxonomía centralizada y migración del call site existente | El analista de producto cuenta con un catálogo único, documentado y sin PII de nombres de eventos/parámetros, base de toda la instrumentación. | Definir convención de naming (snake_case, prefijo por feature) y clases de **constantes centralizadas** para eventos y parámetros (cero strings mágicos). Documentar la **taxonomía** (eventos, parámetros, cuándo se disparan, política no-PII). Migrar los 3 eventos de `soat` (attempt/success/fail) a la taxonomía nueva (resuelve pregunta #7). Sin cambios de UI; verificable en DebugView que los eventos soat siguen llegando con nombres normalizados. |
| 3 | Recorrido de pantallas automático (screen_view) | El analista ve, en GA4, por qué pantallas pasa cada rider y dónde se queda, sin instrumentar pantalla por pantalla. | Registrar un `NavigatorObserver` en `GoRouter.observers` que emita `screen_view` por las ~37 rutas, mapeando nombres de ruta legibles y estables. Respetar gating debug/tests. Punto de enganche único y barato → cobertura total de navegación. Verificable: navegar la app y ver la secuencia de pantallas en DebugView. |
| 4 | Captura de errores y no-fatales de red | El equipo ve en Crashlytics/GA4 los fallos reales que sufren los usuarios (timeouts, 5xx, errores inesperados) categorizados, sin ruido. | Enganchar en `executeService` (un solo sitio) el reporte de **no-fatales** categorizados por tipo (Dio/red, Firebase, Platform, inesperado) con **política de severidad** definida (qué se reporta vs ruido, pregunta #6). Política para `ResultState.error`/`DomainException` evitando doble-conteo (pregunta abierta sobre cubits vs executeService). Sin cambios visibles para el usuario; verificable provocando un error de red y viéndolo clasificado en consola. |
| 5 | Embudos de adquisición: autenticación y onboarding | El analista mide cuántos riders inician sesión/registro, por qué método, y dónde abandonan el alta. | Instrumentar embudos de `splash` → `authentication` (login, signup, forgot-password, social Google/Apple): inicio de flujo, método elegido, éxito/fallo/abandono, primera entrada a home. Definir e implementar `setUserId` **hasheado/anónimo** (pregunta #3) y user properties básicas no-PII al autenticar. Todo sobre la taxonomía de F2. Verificable: completar login/signup y ver el embudo en DebugView. |
| 6 | Embudos del núcleo de eventos: crear, descubrir, registrarse y aprobar | El analista entiende el flujo central (organizar y unirse a rodadas) y dónde se cae la conversión. | Instrumentar `home` (entrada/uso de secciones), `events` (listar, ver detalle, crear/publicar evento, borradores) y `event_registration` (registrarse, workflow de aprobación: solicitar/aprobar/rechazar/cancelar, "mis registros"). Embudos inicio→avance→éxito/abandono por flujo, con parámetros no-PII. Verificable: crear un evento y registrarse, viendo ambos embudos completos. |
| 7 | Embudos de tracking en vivo y SOS | El equipo mide adopción y abandono del tracking en vivo y la frecuencia/contexto de activaciones de SOS. | Instrumentar el flujo de tracking en vivo (`live_tracking_cubit`, mapa, participantes): inicio/fin de sesión, snapshot, y eventos de **SOS** (activación, confirmación, cierre) sin PII de ubicación. Atención a alto volumen → política de muestreo/agregación si aplica. Verificable: iniciar una sesión de tracking y disparar un SOS de prueba, viendo los eventos en DebugView. |
| 8 | Instrumentación de garaje, mantenimientos y SOAT | El analista ve qué tanto los riders usan el garaje, registran mantenimientos y escanean SOAT, y dónde fallan. | Instrumentar `vehicles` (alta/edición/borrado/archivar, set principal), `maintenance` (alta/edición/borrado, ver historial) y completar `soat` (estado, captura manual, además del scan ya migrado). Embudos por flujo sobre la taxonomía. Verificable: agregar un vehículo y un mantenimiento, viendo los eventos correspondientes. |
| 9 | Instrumentación de perfil, descubrimiento de usuarios y notificaciones | El analista entiende el uso del perfil propio, el descubrimiento de otros riders y el engagement con notificaciones. | Instrumentar `profile` (ver/editar perfil), `users` (descubrimiento, ver perfil de rider) y `notifications` (recibir/abrir, marcar leídas, registro de FCM token como señal de salud). Cierra la cobertura de los 11 features. Verificable: abrir una notificación y editar el perfil, viendo los eventos. |
| 10 | Privacidad, opt-out y verificación end-to-end | El rider controla su privacidad (opt-out) con datos anónimos sin PII, y el equipo tiene un procedimiento documentado para validar toda la analítica. | Asegurar uid hasheado/anónimo y ausencia de PII en eventos y claves de Crashlytics (auditoría transversal). Añadir **opt-out** en ajustes (`AppSwitchTile`, strings en `app_es.arb`, default a confirmar pregunta #4) que active/desactive colección. Revisar/actualizar `docs/privacy-policy.html` si menciona analítica. Documento de **QA de analítica** (cómo validar en DebugView/Crashlytics) y checklist de cobertura por feature. Verificable: alternar opt-out y confirmar que la colección se detiene/reanuda. |

## Supuestos

- El stack está cerrado (Firebase Analytics GA4 + Crashlytics + capa propia); no se
  reabre la decisión técnica.
- La analítica es **100% client-side**; `rideglory-api` no requiere cambios en este
  alcance, salvo que se decida (pregunta #3) que el id anónimo lo provea el backend.
  Por defecto se asume **hashing del uid de Firebase en cliente**.
- La regla de capa para `AnalyticsService`/`CrashReporter` se fija en F1 y aplica a
  todas las fases siguientes (probable: abstracción core consumible por
  domain/presentación, nunca el SDK directo). Esto destraba la anomalía actual del
  usecase de soat.
- El gating en debug/tests se resuelve con un único mecanismo definido en F1
  (flag de `AppEnv`/`--dart-define` o `kDebugMode` + `setAnalyticsCollectionEnabled`
  + no-op impl para tests), reutilizado por todas las fases.
- La verificación principal es manual vía DebugView/Crashlytics, complementada con
  tests unitarios de call sites usando mocks del `AnalyticsService`/`CrashReporter`
  (pregunta #8); el detalle por fase lo fija el plan técnico.
- El diseño está en stand-down: solo se necesita aporte de diseño/UI mínimo en F10
  (opt-out en ajustes), reusando `AppSwitchTile` existente.
- "Cobertura total" significa que los 11 features tienen al menos su embudo o
  interacciones clave instrumentadas; no implica loguear cada botón individual
  (la granularidad fina y un posible wrapper de auto-logging de CTAs —pregunta #2—
  la decide el plan técnico, sin bloquear esta descomposición).
- Performance/rendimiento percibido (punto "opcional" de la fuente, pregunta #9) se
  considera **fuera del alcance** de estas fases; se difiere a una iniciativa posterior.

## Riesgos

- **Ruido de no-fatales (F4):** reportar todo `ResultState.error`/`DomainException`
  inunda Crashlytics y oculta señales reales. Mitigación: política de severidad
  explícita y deduplicación; reportar solo categorías accionables.
- **Doble-conteo de errores:** enganchar a la vez en `executeService` y en cubits
  puede duplicar eventos. Mitigación: un único punto de verdad por categoría,
  definido en F4.
- **PII accidental:** nombres de evento, parámetros, mensajes de error o claves de
  Crashlytics pueden filtrar datos personales (correos, placas, ubicaciones).
  Mitigación: taxonomía revisada (F2), auditoría no-PII transversal (F10), uid hasheado.
- **Setup nativo de Crashlytics (F1):** plugin Gradle Android y subida de dSYM en iOS
  son frágiles; un mal setup deja crashes sin símbolos. Mitigación: verificar con
  crash de prueba en staging antes de avanzar.
- **Volumen del tracking en vivo (F7):** eventos de ubicación de alta frecuencia
  pueden disparar costos/cuotas y diluir embudos. Mitigación: instrumentar hitos del
  flujo (inicio/fin/SOS), no cada ping; muestreo si aplica.
- **Propagación de la anomalía de capa:** si no se fija la regla en F1, instrumentar
  11 features puede replicar la violación de Clean Architecture del usecase de soat.
  Mitigación: regla única en F1, verificada por el revisor de arquitectura.
- **Consentimiento/política de tiendas (F10):** un default opt-in incorrecto o una
  política de privacidad desalineada con la analítica real puede generar rechazos en
  Play/App Store. Mitigación: decidir default y revisar `privacy-policy.html` en F10
  (pregunta #4).
- **Gating insuficiente en tests/CI:** si la colección no se desactiva, los tests
  pueden intentar enviar eventos o fallar de forma no determinista. Mitigación: no-op
  impl + gating verificado en F1 y reusado.
- **Inconsistencia de nombres de ruta (F3):** las ~37 rutas deben mapear a nombres
  legibles y estables; cambios de router romperían continuidad de datos. Mitigación:
  mapa de rutas centralizado junto a la taxonomía.

## Criterios de éxito globales

1. **Cobertura total:** los 11 features (`authentication`, `home`, `vehicles`,
   `events`, `event_registration`, `maintenance`, `notifications`, `profile`, `soat`,
   `users`, `splash`) tienen instrumentado su embudo o interacciones clave, y las
   ~37 rutas emiten `screen_view` automático.
2. **Crashes capturados:** crashes fatales y no-fatales (incluyendo errores de red
   categorizados) aparecen en Crashlytics con símbolos, verificable con un crash de
   prueba en staging.
3. **Taxonomía centralizada y documentada:** cero strings mágicos; todos los eventos
   y parámetros provienen de constantes, con doc de taxonomía y mapa de rutas.
4. **Sin PII:** ningún evento, parámetro o clave de Crashlytics contiene datos
   personales; el user id está hasheado/anónimo; auditoría no-PII superada.
5. **Privacidad respetada:** existe opt-out funcional en ajustes que detiene/reanuda
   la colección; `docs/privacy-policy.html` queda alineada con la analítica real.
6. **Desactivable en debug/tests:** la colección está desactivada (o es no-op) en
   debug y en la suite de tests; `flutter test` y `dart analyze` pasan sin regresión.
7. **Sin regresión de comportamiento:** ninguna fase altera el comportamiento visible
   del usuario móvil salvo la fase de opt-out (F10), que añade un control explícito.
8. **Verificabilidad:** existe un procedimiento documentado para validar la analítica
   en GA4 DebugView y los crashes en la consola de Crashlytics, y cada fase es
   demostrable de forma independiente.
9. **Arquitectura limpia:** presentación/domain consumen siempre la abstracción
   (`AnalyticsService`/`CrashReporter`), nunca el SDK de Firebase directamente; la
   regla de capa fijada en F1 se respeta en todas las fases.
