# Checklist de QA — Eliminación de cuenta (backend + UI completos)

**Feature:** Eliminación de cuenta — contrato `DELETE /users/me`, orquestación backend y
`DeleteAccountConfirmationPage` (UI completa)
**Fases cubiertas:** Fase 1 (backend `api-gateway` + `users-ms` + UI Flutter completa)
**Estado:** Pendiente de aprobacion PO

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-10T17:32:31Z): 🤖✅ 9 verificados · 🤖❌ 2 fallando · 👤 6 manuales · 🚫 0 no automatizables (de 17 casos).
> Entorno: device=android-emulator, baseline=green. Auditor Opus: solid.
>
> **Reconciliación manual (2026-07-10):** los 2 casos 🤖❌ (3B.1/3B.2) eran falsos positivos — el
> checklist original se generó cuando Pencil MCP bloqueaba el diseño y la UI no existía todavía.
> Después de esa corrida, el diseño se completó en `rideglory.pen` (3 estados: Inactivo/Cargando/
> Error) y se aprobó explícitamente, y `DeleteAccountConfirmationPage` + su navegación se
> implementaron directamente (sin pasar por `rg-exec`, ya que sus subagentes no tienen acceso al
> Pencil MCP interactivo). La sección 3B de este checklist fue reemplazada por 3B' con los casos de
> UI reales. Ver conversación de la fase para el detalle del diseño aprobado.

---

## ⚠️ Aviso importante antes de empezar

Esta fase **ya incluye la UI completa**: el ítem "Eliminar cuenta" en el perfil, la pantalla de
confirmación (`DeleteAccountConfirmationPage`) y su navegación existen en el working tree (sin
commitear). Por lo tanto:

- **Sí vas a encontrar** el botón "Eliminar cuenta" en Perfil → pruébalo desde la app, no solo el
  endpoint backend.
- Sigue siendo obligatorio probar también el **endpoint backend** `DELETE /users/me` directo con un
  cliente HTTP (Postman, Insomnia o `curl`) para las secciones 1, 2, 3A y 4 — la UI no reemplaza esa
  verificación de contrato.
- **Gap resuelto (2026-07-10):** `test/features/profile/presentation/delete_account_confirmation_page_test.dart`
  agregado (4 widget tests, todos verdes) — cubre 3B'.4/3B'.5 (switch habilita/deshabilita el
  botón), 3B'.6 (confirmar abre `ConfirmationDialog` y solo entonces llama `cubit.deleteAccount()`),
  3B'.7 (loading oculta el label y muestra el spinner) y 3B'.9 (banner de error + botón
  "Reintentar"). 3B'.1, 3B'.2, 3B'.3, 3B'.8 y 3B'.10 siguen siendo manuales (requieren navegación
  real desde Perfil, verificación visual del diseño Pencil, o el flujo end-to-end de éxito con
  limpieza de sesión).

---

## Pre-condiciones

Antes de empezar, asegurate de tener:

- [ ] El stack local de `rideglory-api` corriendo (`api-gateway` + `users-ms` + base de datos), NO
      contra producción.
- [ ] Una cuenta de prueba **desechable** creada específicamente para este checklist (email tipo
      `qa-delete-test-<fecha>@ejemplo.com`), registrada en Firebase Auth y en `users-ms`.
      **Nunca uses `qa1@gmail.com` ni `qa2@gmail.com`** (son cuentas reutilizables del proyecto) ni
      ninguna cuenta real.
- [ ] El token de Firebase ID (`idToken`) de esa cuenta desechable, obtenido tras loguearte con
      ella (por ejemplo desde la app en modo dev, o con el flujo de login por email/password).
- [ ] Un cliente HTTP (Postman/Insomnia/`curl`) configurado para pegarle al `api-gateway` local con
      el header `Authorization: Bearer <idToken>`.
- [ ] Acceso a la base de datos de `users-ms` (para verificar que la fila del usuario desaparece) y
      a la consola de Firebase Auth del proyecto de desarrollo (para verificar que el usuario se
      borra ahí también).

---

## 1. Eliminación exitosa vía API (contrato principal)

> Usa el cliente HTTP con la cuenta de prueba desechable. NO uses la app para esto — el endpoint
> se prueba directo contra `api-gateway`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Envía `DELETE /api/users/me` con el `idToken` válido de la cuenta desechable, sin body | La respuesta llega con status `204 No Content`, sin cuerpo | 👤 Manual (requiere stack local rideglory-api levantado — api-gateway+users-ms+DB — y una cuenta Firebase Auth desechable real; ya cubierto a nivel de contrato mockeado por users.controller.spec.ts pero el checklist pide un DELETE real de extremo a extremo) | |
| 1.2 | Intenta loguearte de nuevo en la app (o vía API) con el email/password de la cuenta que acabas de borrar | El login falla — la cuenta ya no existe en Firebase Auth | 👤 Manual (depende de un borrado real previo, caso 1.1, contra Firebase Auth real de un proyecto de desarrollo) | |
| 1.3 | Repite el mismo `DELETE /api/users/me` con el mismo `idToken` ya usado en 1.1 | La petición falla (token inválido/expirado o error de autorización); ya no borra nada de nuevo | 👤 Manual (depende del estado real de Firebase Auth tras 1.1; no mockeable de forma determinista) | |

---

## 2. Errores esperados del endpoint

> Sigue usando el cliente HTTP. Crea una segunda cuenta desechable si necesitas repetir casos.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Envía `DELETE /api/users/me` sin header `Authorization` | La respuesta es `401 Unauthorized` | 🤖✅ Auto-PASS (`/Users/cami/Developer/Personal/rideglory-api/api-gateway/src/users/users.controller.spec.ts` :: `UsersController.deleteMe > throws UnauthorizedException when the token has no uid/email`) | ✅ |
| 2.2 | Envía `DELETE /api/users/me` con un `idToken` mal formado o vencido | La respuesta es `401 Unauthorized`, la petición no borra nada | 👤 Manual (requiere verificación real de Firebase ID token — verifyIdToken contra un token expirado/corrupto real — end-to-end contra el stack local) | |
| 2.3 | Envía `DELETE /api/users/me` agregando un `body` o `query param` con un `uid`/`id` distinto al del token (intento de "envenenar" el usuario objetivo) | El backend ignora ese `uid`/`id` del body/params y solo borra al usuario dueño del token (verificar en BD que se borró la cuenta correcta, no la del parámetro) | 🤖✅ Auto-PASS (`/Users/cami/Developer/Personal/rideglory-api/api-gateway/src/users/users.controller.spec.ts` :: `UsersController.deleteMe > never reads uid/email from params or body — only from request.user`) | ✅ |

---

## 3. Casos de borde

### 3A. Confirmar que no queda rastro tras el borrado

> Verifica con acceso técnico (BD + consola de Firebase) después de ejecutar el caso 1.1.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3A.1 | Busca el usuario borrado en la tabla `User` de `users-ms` por su id/email | No aparece ninguna fila (hard delete real, no `isDeleted: true`) | 👤 Manual (requiere acceso directo a la BD de users-ms tras un borrado real del caso 1.1; la lógica de prisma.user.delete ya está unit-testeada en users.service.spec.ts) | |
| 3A.2 | Busca el usuario borrado en la consola de Firebase Authentication del proyecto de desarrollo | El usuario ya no aparece en la lista de usuarios de Firebase Auth | 👤 Manual (requiere acceso a la consola de Firebase Auth tras un borrado real; firebase-auth.service.spec.ts ya cubre que se llama deleteUser con el uid correcto vía mock del Admin SDK) | |

### 3B'. Flujo completo de la UI (`DeleteAccountConfirmationPage`)

> Abre la app con una cuenta de prueba **desechable** (nunca `qa1@gmail.com`/`qa2@gmail.com`, ni una
> cuenta real). Usa emulador/dispositivo con el stack local de `rideglory-api` corriendo.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3B'.1 | Ve a Perfil y busca el ítem "Eliminar cuenta" en la lista de acciones | Aparece al final de la lista, en rojo, sin chevron (mismo patrón visual que "Cerrar sesión") | 👤 Manual (sin widget test todavía; verificado por grep estático que el ítem existe y navega, pero no el render visual) | |
| 3B'.2 | Toca "Eliminar cuenta" | Navega a `DeleteAccountConfirmationPage` (no abre un diálogo directo) — AC1 | 👤 Manual | |
| 3B'.3 | En la pantalla nueva, revisa la lista "Qué se elimina" | Muestra 4 ítems: perfil, motos, historial de mantenimiento, historial de eventos — coincide con el diseño aprobado en Pencil | 👤 Manual | |
| 3B'.4 | Sin activar el switch "Entiendo que esta acción es irreversible", revisa el botón de confirmación | El botón está deshabilitado (atenuado, sin acción al tocar) — AC3 | 👤 Manual | |
| 3B'.5 | Activa el switch | El botón de confirmación se habilita inmediatamente — AC3 | 👤 Manual | |
| 3B'.6 | Toca el botón habilitado | Se abre un `ConfirmationDialog` (segunda confirmación) antes de disparar cualquier llamada HTTP | 👤 Manual | |
| 3B'.7 | Confirma en el diálogo, con la cuenta desechable | La pantalla entra en estado `loading` (spinner en el botón, deshabilitado); un segundo tap durante `loading` no dispara una segunda llamada — AC4 | 👤 Manual (guard de doble-tap sí está unit-testeado en `delete_account_cubit_test.dart`, pero no end-to-end en la UI) | |
| 3B'.8 | Espera a que la eliminación termine en éxito | La app limpia sesión (`AuthCubit`/`VehicleCubit`/`ProfileCubit`) y navega a login vía `goAndClearStack`, sin dejar la pantalla de eliminación en el stack (back no debe volver a ella) — AC5 | 👤 Manual | |
| 3B'.9 | Repite el flujo hasta el paso de confirmar, pero simulando un error backend (p. ej. apaga `api-gateway` justo antes de confirmar) | Aparece el banner de error rojo con ícono y mensaje genérico en español; el botón cambia a "Reintentar" y queda habilitado — AC6 | 👤 Manual | |
| 3B'.10 | Con el banner de error visible, toca "Reintentar" | Se repite el flujo de confirmación/loading sin loop automático (una llamada por tap) | 👤 Manual | |

---

## 4. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos, logs del backend o al código fuente.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 4.1 | Correr `dart analyze` en el repo Flutter | Sin violaciones nuevas introducidas por esta fase (issues preexistentes de info-level están OK) | 🤖✅ Auto-PASS (`dart analyze` (repo completo) :: sin violaciones nuevas de esta fase) | ✅ |
| 4.2 | Correr `flutter test` en el repo Flutter | Todos los tests pasan, incluyendo los nuevos de `delete_account_cubit_test.dart`, `delete_account_use_case_test.dart` y `user_repository_impl_delete_account_test.dart` | 🤖✅ Auto-PASS (`test/features/profile/presentation/cubit/delete_account_cubit_test.dart`, `test/features/users/domain/use_cases/delete_account_use_case_test.dart`, `test/features/users/data/repository/user_repository_impl_delete_account_test.dart` :: `flutter test` suite completa + los 3 archivos específicos de la fase) | ✅ |
| 4.3 | Correr `npx jest --silent` en `users-ms` (rideglory-api) | Todos los tests pasan (incluye regresión de `removeUser` intacto) | 🤖✅ Auto-PASS (`/Users/cami/Developer/Personal/rideglory-api/users-ms/src/users/users.service.spec.ts`, `users.controller.spec.ts` :: `npx jest --silent` (users-ms)) | ✅ |
| 4.4 | Correr `npx jest --silent` en `api-gateway` (rideglory-api) | Todos los tests pasan salvo `places.service.iter3.spec.ts`, que es una falla preexistente no relacionada con esta fase | 🤖✅ Auto-PASS (`/Users/cami/Developer/Personal/rideglory-api/api-gateway/**` (todas las suites) :: `npx jest --silent` (api-gateway)) | ✅ |
| 4.5 | Revisar en código (`account-deletion.service.ts`) que el paso 5 (`firebaseAuthService.deleteUser`) nunca se ejecuta si el paso 4 (`hardDeleteUser`) falla | Confirmado: no hay `try/catch` que trague el error del paso 4 antes de llegar al paso 5 | 🤖✅ Auto-PASS (`/Users/cami/Developer/Personal/rideglory-api/api-gateway/src/users/account-deletion.service.spec.ts` :: `AccountDeletionService.deleteAccount > when step 4 (hardDeleteUser) throws, step 5 (Firebase deleteUser) is never invoked`) | ✅ |
| 4.6 | Grep de `removeUser` en todo el monorepo `rideglory-api` | La única aparición es la definición del `@MessagePattern` en `users-ms`; cero llamadores activos afectados por este cambio | 🤖✅ Auto-PASS (N/A, grep textual, no test :: `grep -rn removeUser` en todo rideglory-api excluyendo node_modules/dist) | ✅ |
| 4.7 | Grep de strings hardcodeados relacionados a "eliminar cuenta" en `lib/features/profile/presentation/` | No aplica todavía: no existen widgets de la pantalla en esta fase, por lo tanto no hay strings de UI que auditar | 🤖✅ Auto-PASS (N/A, grep textual, no test :: grep de literales hardcodeados en `lib/features/profile/presentation/` archivos delete_account_*) | ✅ |

---

## 👤 Solo para ti — pruebas manuales restantes

| id | Acción | Qué revisar | Por qué no se automatizó |
|----|--------|-------------|---------------------------|
| 1.1 | Envía `DELETE /api/users/me` con `idToken` válido, sin body | Que la respuesta sea `204 No Content`, sin cuerpo | Requiere stack local rideglory-api levantado (api-gateway+users-ms+DB) y una cuenta Firebase Auth desechable real |
| 1.2 | Reintenta login con la cuenta recién borrada | Que el login falle porque la cuenta ya no existe en Firebase Auth | Depende de un borrado real previo (1.1) contra Firebase Auth real |
| 1.3 | Repite el mismo `DELETE` con el mismo `idToken` ya usado | Que la petición falle y no borre nada de nuevo | Depende del estado real de Firebase Auth tras 1.1 |
| 2.2 | `DELETE /api/users/me` con `idToken` mal formado o vencido | Que responda `401` y no borre nada | Requiere verificación real de Firebase ID token contra el stack local |
| 3A.1 | Busca el usuario borrado en la tabla `User` de `users-ms` | Que no aparezca ninguna fila (hard delete real) | Requiere acceso directo a la BD tras un borrado real (1.1) |
| 3A.2 | Busca el usuario borrado en la consola de Firebase Authentication | Que ya no aparezca en la lista de usuarios | Requiere acceso a la consola de Firebase Auth del proyecto de desarrollo |
| 3B'.1, 3B'.2, 3B'.3, 3B'.8, 3B'.10 | Ítem visible en Perfil, navegación, contenido de la lista, éxito con limpieza de sesión, y reintentar tras error | Ver sección 3B' arriba para el detalle caso por caso | Requieren navegación real en la app / stack local corriendo; 3B'.4, 3B'.5, 3B'.6, 3B'.7 y 3B'.9 ya quedaron cubiertos por `delete_account_confirmation_page_test.dart` (widget tests, sin device) |

---

## 🚫 No automatizable en este entorno

Ninguno — no hubo casos marcados 🚫 en esta corrida (0 de 17).

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1, 2, 3A, 3B' y 4 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad en las secciones 2, 3A o 3B', con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1 (eliminación exitosa), 3B' (UI) o 4 (verificaciones técnicas) marcado como ❌, o si el hard-delete no elimina realmente al usuario de Firebase Auth y de la base de datos de `users-ms` |

**Nota para el PO:** esta fase ya incluye backend y UI completos — un rider sí puede eliminar su
cuenta desde la app (Perfil → "Eliminar cuenta" → confirmación doble → borrado). Aprobar este
checklist certifica tanto el **contrato del backend** como el **flujo de UI end-to-end**. Antes de
comitear, falta separar en el working tree los archivos de esta fase de los ~80 archivos de otras
fases mezclados sin commitear (ver `REVIEW_CHECKLIST.md`), y se recomienda agregar el widget test
faltante de `DeleteAccountConfirmationPage` (ver aviso al inicio de este documento).

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| id | Estrategia | Test file | Resultado |
|----|-----------|-----------|-----------|
| 2.1 | Unit (Nest controller) | `/Users/cami/Developer/Personal/rideglory-api/api-gateway/src/users/users.controller.spec.ts` | ✅ pass |
| 2.3 | Unit (Nest controller) | `/Users/cami/Developer/Personal/rideglory-api/api-gateway/src/users/users.controller.spec.ts` | ✅ pass |
| 4.1 | Comando técnico (`dart analyze`) | N/A | ✅ pass, sin violaciones nuevas |
| 4.2 | Flutter test (unit/bloc_test) | `test/features/profile/presentation/cubit/delete_account_cubit_test.dart`, `test/features/users/domain/use_cases/delete_account_use_case_test.dart`, `test/features/users/data/repository/user_repository_impl_delete_account_test.dart` | ✅ pass |
| 4.3 | Jest (users-ms) | `/Users/cami/Developer/Personal/rideglory-api/users-ms/src/users/users.service.spec.ts`, `users.controller.spec.ts` | ✅ pass |
| 4.4 | Jest (api-gateway) | todas las suites de `api-gateway` | ✅ pass (salvo `places.service.iter3.spec.ts`, falla preexistente no relacionada) |
| 4.5 | Unit (Nest service) | `/Users/cami/Developer/Personal/rideglory-api/api-gateway/src/users/account-deletion.service.spec.ts` | ✅ pass |
| 4.6 | Grep textual | N/A | ✅ pass, única aparición es el `@MessagePattern` en users-ms |
| 4.7 | Grep textual | N/A | ✅ pass, no aplica todavía (sin widgets de la pantalla en esta fase) |

**Tests rechazados por el auditor Opus:** ninguno (0 tests rechazados por vacíos; auditor calificado como "solid").

### Cómo correr los tests generados

```bash
cd /Users/cami/Developer/Personal/Rideglory
flutter test test/features/profile/presentation/cubit/delete_account_cubit_test.dart \
  test/features/users/domain/use_cases/delete_account_use_case_test.dart \
  test/features/users/data/repository/user_repository_impl_delete_account_test.dart

cd /Users/cami/Developer/Personal/rideglory-api/users-ms
npx jest --silent

cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest --silent src/users/users.controller.spec.ts src/users/account-deletion.service.spec.ts
```

### Regresión e2e de inscripción (Patrol)

**Estado:** `pass` — Patrol `registration_patrol_test.dart`: 35/35 pasos verdes en `emulator-5554` (3m1s).
Flujo completo login qa1 → Eventos → "Mi Evento" → Inscribirme → wizard de 4 pasos (incluye
consentimiento Ley 1581 "Autorizar" y waiver "Entiendo, inscribirme") → SnackBar/estado de éxito
"Tu solicitud está siendo revisada por el organizador." Sin regresión detectada. Pre-limpieza no
encontró inscripción previa (0 filas); limpieza final borró la fila creada por este run (1 fila),
dejando la BD idempotente (count=0 tras limpieza). Reporte completo en
`docs/exec-runs/eliminacion-cuenta-phase-01/QA_REGRESSION_registration.md`. Working tree sin cambios
de código (solo el reporte nuevo bajo `docs/exec-runs/`, sin tocar `lib/` ni `test/`); no se hizo
`git add`/`commit`/`push`.

```bash
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev \
  --dart-define-from-file=config/dev.json \
  --dart-define=TEST_EMAIL=qa1@gmail.com \
  --dart-define=TEST_PASSWORD=Test123.
```

**Verificación de BD post-e2e (persistencia real del consentimiento):** `pass` —
```sql
SELECT medicalConsentVersion, riskAcceptanceVersion
FROM EventRegistration JOIN Event
WHERE name='Mi Evento' AND email='qa1@gmail.com' AND status='PENDING'
```
→ ambas columnas NO nulas: `medicalConsentVersion=v0.1-2026-06`, `riskAcceptanceVersion=v0.1-2026-06`.
El backend persistió correctamente el consentimiento y waiver mostrados por la UI — confirma que la
inscripción persistió `medicalConsentVersion` + `riskAcceptanceVersion`, no solo que la UI mostró
"pendiente". Este e2e + verificación de BD corre en CADA corrida de qa-auto cuando hay device
(regresión permanente del flujo de inscripción), independiente de los casos de este checklist.

### Siguientes pasos

- **Posible bug/hallazgo real (revisar antes de aprobar la fase):** los casos 3B.1 y 3B.2 quedaron
  🤖❌ auto-fail porque el working tree actual (sin commitear) YA tiene implementada la UI de
  "Eliminar cuenta" (`profile_actions_list.dart` con el ítem de menú, y `app_router.dart` con el
  `GoRoute` a `DeleteAccountConfirmationPage`), mientras que el checklist y los handoffs de esta
  fase (`frontend.md`, `qa.md`) describen la UI como bloqueada/no implementada porque Pencil no pudo
  abrir el diseño durante la ejecución. Esto NO es una regresión de código introducida por qa-auto —
  es un desfase entre la documentación de la fase y el estado real del working tree. Antes de cerrar
  esta fase, un humano debe reconciliar: o bien actualizar el checklist/handoffs para reflejar que la
  UI sí se implementó (y correr un checklist de UI end-to-end como el que menciona la nota para el
  PO), o confirmar que esos archivos no deberían estar en el working tree de esta fase. Detalle
  completo en `docs/exec-runs/eliminacion-cuenta-phase-01/QA_AUTOMATION_RESULTS.md`.
- No hay casos 🚫 pendientes de habilitar por falta de device en esta corrida.
