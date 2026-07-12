# Checklist de QA — Eliminación de cuenta: manejo de fallas y estados

**Feature:** Eliminación de cuenta — idempotencia del borrado y reconciliación de sesión tras cierre de app
**Fases cubiertas:** Fase 4 (endurecimiento de fallas/idempotencia sobre el flujo de borrado de Fase 1 y Fase 3)
**Estado:** Automatizacion qa-auto completada (pass) — pendiente de pruebas manuales restantes y aprobacion PO

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-12T03:17:33Z): 🤖✅ 10 verificados · 🤖❌ 0 fallando · 👤 12 manuales · 🚫 4 no automatizables (de 26 casos).
> Entorno: device=android-emulator, baseline=green. Auditor Opus: solid.

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Usuario rider de prueba `qa1@gmail.com` / `Test123.` con al menos un vehículo en el garaje, y con SOAT/tecnomecánica cargados (para confirmar que el borrado real no se dispara accidentalmente en pruebas de "cancelar a mitad de camino").
- [ ] Usuario `qa2@gmail.com` / `Test123.`, organizador activo de "Mi Evento" (evento con fecha futura y registros abiertos) — se usa solo para el caso de borde de la sección de regresión, NO para las pruebas de borrado real.
- [ ] Acceso a un entorno de staging (no producción) donde se pueda ejecutar el borrado real de `qa1@gmail.com` sin afectar datos reales.
- [ ] Acceso al equipo de desarrollo para: (a) forzar cortes de conexión/matar la app a mitad de una petición, (b) consultar la base de datos de staging, y (c) revisar logs del backend.
- [ ] Dos dispositivos o dos clientes HTTP (por ejemplo Postman + la app) con el mismo token de `qa1@gmail.com` autenticado, para simular llamadas superpuestas.
- [ ] Modo avión disponible en el dispositivo de prueba (para el caso de borde de error de red transitorio).

---

## 1. Cerrar la app antes de confirmar el borrado (AC1)

> Abre la app, inicia sesión con `qa1@gmail.com` y entra a Perfil → Eliminar cuenta.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre la pantalla de confirmación de eliminación de cuenta pero NO toques el botón de confirmar. | La pantalla de confirmación se ve igual que siempre (sin cambios de esta fase). | 👤 Manual (verificación visual de que una pantalla no cambió; no hay lógica nueva que testear, requiere ojo humano en el dispositivo) | |
| 1.2 | Con la pantalla de confirmación abierta y SIN haber tocado "Eliminar", cierra la app por completo (deslizar para cerrarla desde el multitarea) o activa modo avión antes de confirmar. | La app se cierra sin enviar ninguna petición al backend. | 👤 Manual (requiere matar la app o activar modo avión en un dispositivo físico/simulador real; no es simulable de forma determinista en unit/widget/Patrol) | |
| 1.3 | Reabre la app (o desactiva modo avión y vuelve a abrir). | Sigues autenticado como `qa1@gmail.com`, ves tu perfil y datos intactos (vehículos, garaje) tal como estaban antes. | 👤 Manual (depende del ciclo de vida real de la app (kill+reopen) y de datos reales de staging; no automatizable en este entorno) | |
| 1.4 | Repite el flujo de eliminación de cuenta desde cero (Perfil → Eliminar cuenta → confirmar). | El flujo arranca normalmente, sin mensajes de error ni estados raros por el intento anterior cancelado. | 👤 Manual (continuación del escenario manual anterior sobre dispositivo real; no hay código nuevo de esta fase que cubra este camino — AuthCubit.checkAuthState ya existente, sin cambios) | |

---

## 2. Cerrar la app durante el borrado en curso (AC2)

> Con `qa1@gmail.com`, en Perfil → Eliminar cuenta, esta vez SÍ vas a confirmar el borrado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Toca "Eliminar cuenta" y confirma en el diálogo. Apenas aparezca el loading/spinner, cierra la app inmediatamente (deslizar para cerrarla) o activa modo avión a mitad del spinner. | La app se cierra o pierde conexión mientras la petición seguía en curso. | 👤 Manual (requiere interacción física con el dispositivo — kill de app a mitad de spinner — en tiempo real; no reproducible en un test automatizado) | |
| 2.2 | Espera unos 60 segundos (dale tiempo al backend a terminar la orquestación completa) y luego pide al equipo de desarrollo verificar en la base de datos de staging que la cuenta de `qa1@gmail.com` quedó completamente eliminada (usuario, vehículos, documentos, registros anonimizados). | El backend completó TODOS los pasos del borrado aunque el cliente se haya desconectado a mitad de camino — no hay un estado "a medias" (por ejemplo, vehículos borrados pero usuario aún activo). | 🚫 No automatizable (requiere infraestructura de test de integración con socket real cortado a mitad de request contra BD de staging; el propio handoff de backend documenta esto fuera de alcance, solo verificado por lectura de código) | |
| 2.3 | Reabre la app (o desactiva modo avión) e intenta usar cualquier pantalla que requiera sesión (por ejemplo, abrir Perfil o el feed de eventos). | Ver sección 3 — el comportamiento esperado es el logout forzado, no que la app se quede colgada o muestre datos viejos como si la sesión siguiera activa. | 👤 Manual (depende de encadenar el escenario manual 2.1/2.2 sobre staging real; se resuelve/verifica en detalle en la sección 3) | |

---

## 3. Sesión terminada tras borrado completo (AC3)

> Continuación del caso 2, o alternativamente: pide al equipo de desarrollo que elimine/deshabilite la cuenta de un usuario de prueba directamente en Firebase Auth Console mientras tenés la sesión abierta en el dispositivo (no cierres la app antes de esto).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Con la sesión "vieja" todavía abierta en el dispositivo (no reiniciaste la app), navega a cualquier pantalla que dispare una petición autenticada (por ejemplo, abre la lista de eventos o tu perfil). | La app detecta que la sesión ya no es válida sin que tengas que hacer nada manualmente. | 🤖✅ Auto-PASS (`test/core/http/firebase_auth_interceptor_test.dart` — `FirebaseAuthInterceptor.onError`: 401 con refresh fallido por `user-not-found`/`user-disabled`/`user-token-expired` → signOut + snackbar, error propagado) | ✅ |
| 3.2 | Observa la pantalla y cualquier mensaje que aparezca. | Aparece un mensaje (snackbar) que dice exactamente **"Tu sesión terminó, inicia sesión de nuevo."** — el mensaje NO menciona en ningún momento que la cuenta fue eliminada ni da detalles de qué pasó. | 🤖✅ Auto-PASS (`test/core/http/firebase_auth_interceptor_test.dart` — mismos 3 casos, assert del SnackBar mostrado vía `AppRouter.scaffoldMessengerKey`) | ✅ |
| 3.3 | Observa a dónde te lleva la app después del mensaje. | Sos redirigido automáticamente a la pantalla de login, sin necesidad de cerrar y reabrir la app ni de tocar nada más. | 🚫 No automatizable (requiere un 401 real contra un usuario efectivamente borrado en Firebase Auth + backend real, más navegación multi-pantalla vía `GoRouterRefreshStream`; no hay fixture de "usuario ya borrado en Firebase" ni infraestructura Patrol/mock que reproduzca ese 401 exacto sin backend real, sin inventar un falso-verde; coincide con lo documentado en handoffs/qa.md como pendiente de staging) | |
| 3.4 | Intenta iniciar sesión de nuevo con las mismas credenciales (`qa1@gmail.com`). | El login falla porque la cuenta ya no existe (mensaje de error de login normal, no relacionado con este flujo) — confirma que el borrado fue real y definitivo. | 👤 Manual (depende de un borrado real de cuenta en staging — Firebase Auth — y de credenciales reales de qa1@gmail.com; no fabricable en un test unitario/widget sin backend real) | |

---

## 4. Reintentar el borrado sin duplicar datos (AC4, AC5)

> Usa una cuenta de prueba nueva o restaurada para esta sección (coordina con desarrollo para tener un `qa1`-equivalente fresco, ya que la anterior quedó eliminada en la sección 3).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Inicia el flujo de eliminación de cuenta y confírmalo hasta que termine exitosamente (espera a que la app te saque a login). | El borrado se completa normalmente, sin diferencia visible respecto al comportamiento ya conocido de la Fase 1. | 👤 Manual (flujo end-to-end completo contra backend real de staging con borrado irreversible de cuenta; requiere coordinación con datos reales, no automatizable en este entorno de agente) | |
| 4.2 | Pide a desarrollo repetir manualmente la llamada `DELETE /users/me` para el mismo usuario ya eliminado (por ejemplo desde Postman con el token guardado antes del borrado). | La respuesta es `204` (éxito), nunca un error 500 ni un error 404 "crudo" no documentado. | 🤖✅ Auto-PASS (`api-gateway/src/users/account-deletion.service.spec.ts`, `api-gateway/src/auth/firebase-auth.service.spec.ts`, `users-ms/src/users/users.service.spec.ts` — retry-after-full-completion: `findUserByEmail` 404 (objeto plano y RpcException) resuelve idempotente; `hardDelete` no-op P2025; Firebase `deleteUser` no-op `auth/user-not-found`) | ✅ |
| 4.3 | Pide a desarrollo disparar dos llamadas `DELETE /users/me` casi al mismo tiempo (dentro del mismo segundo) para el mismo usuario, usando dos clientes distintos con el mismo token. | Ambas llamadas responden `204`, ninguna cae en error. | 🤖✅ Auto-PASS (`api-gateway/src/users/account-deletion.service.spec.ts` — concurrent race: dos llamadas `deleteAccount()` superpuestas / la segunda llega después de que la primera completó totalmente) | ✅ |
| 4.4 | Pide a desarrollo verificar en la base de datos de staging el estado final tras las llamadas 4.2 y 4.3. | El estado en base de datos es idéntico al de un borrado ejecutado una sola vez: no hay filas duplicadas, huérfanas ni registros parcialmente anonimizados. | 👤 Manual (requiere consultar directamente la base de datos de staging tras ejecutar llamadas reales; no hay entorno de BD real disponible para el agente, es verificación humana explícita) | |

---

## 5. Casos de borde

### 5A. Error de red transitorio no debe cerrar la sesión

> Con cualquier usuario de prueba con sesión activa y cuenta intacta (NO uses una cuenta ya eliminada).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5A.1 | Activa modo avión y navega dentro de la app intentando cargar datos (por ejemplo, refrescar el feed de eventos o tu perfil). | Aparece el manejo de error de red normal (mensaje de "sin conexión" o similar ya existente), pero NO aparece el snackbar de "Tu sesión terminó, inicia sesión de nuevo." | 🤖✅ Auto-PASS (`test/core/http/firebase_auth_interceptor_test.dart` — `FirebaseAuthInterceptor.onError`: 401 con refresh fallido por `network-request-failed` → nunca logout) | ✅ |
| 5A.2 | Desactiva modo avión y reintenta la misma acción. | La app se recupera normalmente y sigues autenticado, sin haber sido deslogueado por el corte de red. | 👤 Manual (requiere manipular la conectividad real del dispositivo — activar/desactivar modo avión — y observar la recuperación de la app en vivo; no reproducible de forma determinista en unit/widget) | |
| 5A.3 | Repite el punto 5A.1 pero simulando el backend caído (si es posible en staging) en vez de modo avión. | Mismo resultado: error de red genérico, nunca el logout forzado ni el snackbar de sesión terminada. | 👤 Manual (requiere simular el backend caído en staging, infraestructura fuera del alcance de un test automatizado en este entorno) | |

### 5B. Doble notificación de sesión terminada no debe romper la navegación

> Requiere coordinación con desarrollo para forzar dos respuestas `401` casi simultáneas contra el mismo cliente con una cuenta ya eliminada.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5B.1 | Con una cuenta ya eliminada del lado del backend, dispara dos peticiones autenticadas casi al mismo tiempo desde la app (por ejemplo, navega rápido entre dos pantallas que cada una hace su propia llamada). | Puede aparecer el snackbar de sesión terminada más de una vez (esto es aceptado, no es un bug), pero la app termina en todos los casos en la pantalla de login, sin pantalla en blanco ni estado inconsistente. | 🚫 No automatizable (requiere forzar dos respuestas 401 casi simultáneas contra una cuenta ya eliminada en staging real y observar el comportamiento de navegación resultante; no hay infraestructura de backend/BD real disponible en este entorno de agente para producir ese escenario de forma determinista) | |

### 5C. Organizador activo sigue bloqueado por la precondición existente (regresión, no de esta fase)

> Usa `qa2@gmail.com`, organizador de "Mi Evento" con evento futuro activo.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5C.1 | Inicia sesión como `qa2@gmail.com` e intenta eliminar la cuenta desde Perfil. | La app sigue bloqueando el borrado con el mensaje de precondición ya existente (organizador con evento activo), igual que antes de esta fase — este comportamiento no debió cambiar. | 🚫 No automatizable (regresión explícita de fase 3 fuera de alcance de esta fase — guardrail de no-cambio; requiere datos reales de qa2@gmail.com con evento futuro activo en staging, no fabricable en este entorno de agente sin backend real) | |

---

## 6. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 6.1 | Revisar en BD de staging que tras el caso 2.2, el usuario, sus vehículos, documentos (SOAT/RTM), mantenimientos y registros de eventos quedaron todos en el estado final correcto (usuario y PII eliminados, registros de eventos anonimizados), sin filas a medio procesar. | Estado 100% consistente, sin residuos de un borrado interrumpido a mitad de camino. | 👤 Manual (requiere acceso directo a la base de datos de staging tras un borrado real interrumpido; no reproducible en tests unitarios sin BD real) | |
| 6.2 | Revisar logs del backend durante el caso 4.2 (reintento tras borrado completo). | El log muestra que el paso `findUserByEmail` (o el paso correspondiente) detectó "no encontrado" y resolvió como éxito idempotente, sin lanzar ni loguear un error 500/404 no controlado. | 🤖✅ Auto-PASS (`api-gateway/src/users/account-deletion.service.spec.ts` — retry-after-full-completion tests) | ✅ |
| 6.3 | Revisar logs del backend durante el caso 4.3 (carrera concurrente). | Ambas llamadas completan su traza de logs sin excepciones no controladas; Firebase Auth `deleteUser` no se invoca dos veces para el mismo `uid` una vez que la primera llamada ya lo eliminó. | 🤖✅ Auto-PASS (`api-gateway/src/users/account-deletion.service.spec.ts` — concurrent race: la segunda llamada llega después de que la primera completó totalmente) | ✅ |
| 6.4 | Confirmar en el código de `lib/core/http/app_dio.dart` que el `receiveTimeout` sigue en 60 segundos (no se subió el timeout global). | `receiveTimeout: Duration(seconds: 60)` sin cambios, y ninguna llamada específica de borrado de cuenta tiene un override de timeout distinto salvo que exista evidencia documentada de staging que lo justifique. | 🤖✅ Auto-PASS (`lib/core/http/app_dio.dart` — revisión textual línea 19) | ✅ |
| 6.5 | Confirmar que la clave `auth_sessionEndedSnackbar` en `lib/l10n/app_es.arb` contiene exactamente el texto "Tu sesión terminó, inicia sesión de nuevo." y que no hay ningún string hardcodeado equivalente en el código. | Copy neutral centralizado en el ARB, sin hardcodeo ni menciones a "cuenta eliminada". | 🤖✅ Auto-PASS (`lib/l10n/app_es.arb` — revisión textual de `auth_sessionEndedSnackbar`) | ✅ |
| 6.6 | Confirmar que el set de códigos que dispara logout forzado en `firebase_auth_interceptor.dart` está acotado exactamente a `{'user-not-found', 'user-disabled', 'user-token-expired'}`. | No incluye `network-request-failed` ni otros códigos de conectividad genéricos. | 🤖✅ Auto-PASS (`lib/core/http/firebase_auth_interceptor.dart`, `test/core/http/firebase_auth_interceptor_test.dart` — revisión textual de `_sessionInvalidatedCodes` + corrida de la suite completa) | ✅ |

---

## 👤 Solo para ti — pruebas manuales restantes

Lista corta de todo lo que quedó como 👤 manual o 🤖❌ auto-fail (aquí no hay auto-fail: 0 casos). Ejecuta estos casos en dispositivo/staging real.

- **1.1** — Abrir pantalla de confirmación sin tocar "Eliminar". Revisar: que la pantalla se vea igual que siempre. No se automatizó porque es verificación visual de una pantalla sin lógica nueva.
- **1.2** — Cerrar la app / modo avión antes de confirmar el borrado. Revisar: que no salga ninguna petición al backend. No se automatizó porque requiere matar la app o modo avión en dispositivo real.
- **1.3** — Reabrir la app tras el cierre previo. Revisar: sigue autenticado, datos intactos. No se automatizó porque depende del ciclo de vida real de la app y datos reales de staging.
- **1.4** — Repetir el flujo de eliminación desde cero tras cancelación previa. Revisar: arranca normal, sin mensajes raros. No se automatizó porque es continuación del escenario manual anterior sobre dispositivo real.
- **2.1** — Cerrar la app / modo avión apenas aparece el spinner de borrado. Revisar: la app se cierra o pierde conexión a mitad de la petición. No se automatizó porque requiere interacción física con el dispositivo en tiempo real.
- **2.3** — Reabrir la app tras el caso 2 e intentar usar una pantalla que requiere sesión. Revisar: logout forzado (sección 3), no colgada ni datos viejos. No se automatizó porque depende de encadenar 2.1/2.2 sobre staging real.
- **3.4** — Reintentar login con las mismas credenciales tras el borrado real. Revisar: el login falla porque la cuenta ya no existe. No se automatizó porque depende de un borrado real en staging y credenciales reales.
- **4.1** — Completar el flujo de eliminación exitosamente hasta el logout. Revisar: se completa igual que en Fase 1. No se automatizó porque es un flujo end-to-end contra backend real de staging con borrado irreversible.
- **4.4** — Verificar en BD de staging el estado final tras 4.2 y 4.3. Revisar: estado idéntico a un borrado único, sin filas duplicadas/huérfanas. No se automatizó porque requiere consulta directa a BD de staging.
- **5A.2** — Desactivar modo avión y reintentar tras error de red. Revisar: la app se recupera sin ser deslogueada. No se automatizó porque requiere manipular conectividad real del dispositivo en vivo.
- **5A.3** — Backend caído en vez de modo avión. Revisar: mismo error genérico, nunca logout forzado. No se automatizó porque requiere simular el backend caído en staging.
- **6.1** — Revisar en BD de staging el estado final tras el caso 2.2. Revisar: consistencia 100%, sin residuos de borrado interrumpido. No se automatizó porque requiere acceso directo a BD de staging tras un borrado real interrumpido.

## 🚫 No automatizable en este entorno

- **2.2** — Verificar en BD de staging que el backend completó todos los pasos del borrado pese a la desconexión del cliente. Cómo habilitarlo: montar un entorno de integración con socket real cortado a mitad de request contra la BD de staging (fuera de alcance del agente; ya documentado como pendiente en el handoff de backend).
- **3.3** — Redirección automática a login tras el mensaje de sesión terminada. Cómo habilitarlo: correr contra backend/Firebase Auth reales con un usuario efectivamente borrado, y una suite Patrol que dispare el 401 real y observe la navegación (`GoRouterRefreshStream`) en un dispositivo/simulador con conectividad real.
- **5B.1** — Doble notificación de sesión terminada no rompe la navegación. Cómo habilitarlo: forzar dos respuestas 401 casi simultáneas contra una cuenta ya eliminada en staging real (requiere backend real, no mockeable sin producir un falso-verde).
- **5C.1** — Organizador activo (qa2@gmail.com) sigue bloqueado por precondición existente de fase 3. Cómo habilitarlo: correr contra staging real con datos reales de qa2@gmail.com y un evento futuro activo; es una regresión de fase 3 fuera de alcance de esta fase.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos 1.1–6.6 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad (por ejemplo el doble snackbar del caso 5B.1, ya aceptado como no-bloqueante), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3 o 4 (flujo principal de idempotencia y reconciliación de sesión) marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| ID | Estrategia | Test file | Resultado |
|----|-----------|-----------|-----------|
| 3.1 | Unit — interceptor Dio | `test/core/http/firebase_auth_interceptor_test.dart` | ✅ pass |
| 3.2 | Unit — interceptor Dio | `test/core/http/firebase_auth_interceptor_test.dart` | ✅ pass |
| 4.2 | Unit — backend spec | `api-gateway/src/users/account-deletion.service.spec.ts`, `api-gateway/src/auth/firebase-auth.service.spec.ts`, `users-ms/src/users/users.service.spec.ts` | ✅ pass |
| 4.3 | Unit — backend spec (concurrencia) | `api-gateway/src/users/account-deletion.service.spec.ts` | ✅ pass |
| 5A.1 | Unit — interceptor Dio | `test/core/http/firebase_auth_interceptor_test.dart` | ✅ pass |
| 6.2 | Unit — backend spec (logs de idempotencia) | `api-gateway/src/users/account-deletion.service.spec.ts` | ✅ pass |
| 6.3 | Unit — backend spec (carrera concurrente) | `api-gateway/src/users/account-deletion.service.spec.ts` | ✅ pass |
| 6.4 | Revisión textual | `lib/core/http/app_dio.dart` | ✅ pass |
| 6.5 | Revisión textual | `lib/l10n/app_es.arb` | ✅ pass |
| 6.6 | Revisión textual + suite | `lib/core/http/firebase_auth_interceptor.dart`, `test/core/http/firebase_auth_interceptor_test.dart` | ✅ pass |

**Tests rechazados por el auditor Opus:** ninguno. El auditor evaluó la corrida como "solid" — 0 tests rechazados por vacíos.

### Cómo correr los tests generados

```bash
cd /Users/cami/Developer/Personal/Rideglory
flutter test test/core/http/firebase_auth_interceptor_test.dart
```

```bash
cd /Users/cami/Developer/Personal/rideglory-api
npm test -- api-gateway/src/users/account-deletion.service.spec.ts
npm test -- api-gateway/src/auth/firebase-auth.service.spec.ts
npm test -- users-ms/src/users/users.service.spec.ts
```

### Regresión e2e de inscripción (Patrol)

**Estado: pass.** `integration_test/registration_patrol_test.dart` existe y corrió completo contra `emulator-5554`: 34/34 pasos OK (login, wizard de 4 pasos, consentimiento Ley 1581 "Autorizar", selección de vehículo, "Confirmar Inscripción", waiver "Entiendo, inscribirme", SnackBar de éxito). Duración 2m12s. Pre-limpieza dejó a `qa1@gmail.com` sin inscripción previa en "Mi Evento"; limpieza final borró la inscripción PENDING creada por el test (DELETE 1, verificado 0 filas restantes), sin tocar registros de qa2 ni de otros usuarios. No se tocó código de producción ni se hicieron commits. Reporte completo en `docs/exec-runs/eliminacion-cuenta-phase-04/QA_REGRESSION_registration_2026-07-12.md`.

Comando:

```bash
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

**Verificación de BD post-e2e:** `pass`. SELECT sobre `EventRegistration` JOIN `Event` (`name='Mi Evento'`, `email='qa1@gmail.com'`, `status='PENDING'`) mostró `medicalConsentVersion='v0.1-2026-06'` y `riskAcceptanceVersion='v0.1-2026-06'`, ambas NO nulas: el consentimiento médico y la aceptación de riesgo se persistieron realmente en events-ms, no solo en la UI.

Esta regresión (e2e + verificación de BD) corre en CADA corrida de qa-auto cuando hay device conectado, como chequeo permanente del flujo de inscripción, independiente de los casos propios de este checklist.

### Siguientes pasos

- No hay casos 🤖❌ auto-fail en esta corrida; no hay bugs reales que investigar desde la automatización.
- Los 4 casos 🚫 no automatizables requieren backend/staging real o BD real (ver sección "No automatizable en este entorno" arriba) — no dependen de tener un simulador/device conectado, sino de infraestructura de staging fuera del alcance del agente.
- Los 12 casos 👤 manuales quedan para ejecución humana en dispositivo real siguiendo la lista de "Solo para ti" arriba, antes de la aprobación final del PO.
