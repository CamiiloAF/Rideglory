# Checklist de QA — Borrado en cascada de vehículos, documentos y mantenimientos al eliminar cuenta

**Feature:** Eliminación de cuenta — cascada de datos de dominio (vehículos, SOAT, RTM, mantenimientos, imágenes en Storage)
**Fases cubiertas:** Fase 1 (núcleo de identidad, ya entregada) + Fase 2 (esta fase — 100% backend en `rideglory-api`; en Rideglory Flutter solo se tocó documentación, sin código ni copy nuevo)
**Estado:** Pendiente de aprobación PO (verificación automatizada qa-auto completada, sin fallas — 3 casos manuales y 8 no automatizables en este entorno pendientes de revisión humana)

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-11T15:15:18Z): 🤖✅ 11 verificados · 🤖❌ 0 fallando · 👤 3 manuales · 🚫 8 no automatizables (de 22 casos).
> Entorno: device=android-emulator, baseline=green. Auditor Opus: solid.

---

## Pre-condiciones

Esta fase no toca la UI: la pantalla y el copy de confirmación de borrado de cuenta ya existen desde fase 1 y no deben verse distintos. Antes de empezar, prepara varias cuentas de prueba **desechables** (NUNCA uses una cuenta real de producción — el borrado es irreversible). No uses `qa1@gmail.com` ni `qa2@gmail.com` si las necesitas para otras pruebas en curso, porque quedarán eliminadas al final de este checklist.

- [ ] Cuenta A (datos completos): 2-3 vehículos, cada uno con SOAT vigente (con foto), RTM vigente (con foto) y al menos 2 registros de mantenimiento por vehículo.
- [ ] Cuenta B (documentos sin foto): al menos 1 vehículo con SOAT o RTM capturado **sin** foto/documento adjunto.
- [ ] Cuenta C (imagen huérfana): 1 vehículo cuya foto se borró manualmente del bucket de Firebase Storage (o cuya URL está corrupta) mientras el registro en la app sigue apuntando a ella.
- [ ] Cuenta D (garage vacío): cuenta nueva sin ningún vehículo registrado.
- [ ] Acceso de lectura a Postgres de `vehicles-ms` y `maintenances-ms` (o a quien pueda correr las queries por ti).
- [ ] Acceso a la consola de Firebase Storage del proyecto (o a `bucket.file(path).exists()`).
- [ ] Acceso a los logs de `api-gateway` (para verificar que los fallos de Storage se loguean sin abortar el flujo).
- [ ] Anota de antemano los IDs/matrículas de los vehículos de cada cuenta y las URLs de sus imágenes/documentos, para poder verificarlos después de borrados.

---

## 1. Eliminar cuenta con datos completos (vehículos, SOAT, RTM y mantenimientos)

> Inicia sesión con la Cuenta A. Ve a Perfil → Eliminar cuenta (o la ruta equivalente ya existente desde fase 1).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre la pantalla de confirmación de eliminación de cuenta. | La pantalla y el copy se ven exactamente igual que antes de esta fase (menciona que se borrarán motos, documentos e historial). | 🤖✅ Auto-PASS (`test/features/profile/presentation/delete_account_confirmation_page_test.dart` :: los 4 widget tests) | ✅ |
| 1.2 | Confirma la eliminación de la Cuenta A. | La app muestra que la cuenta fue eliminada, sin errores ni pantallas de carga colgadas; te redirige al flujo de login/onboarding. | 🚫 No automatizable (borrado real e irreversible de una cuenta con datos completos contra backend y Firebase Auth reales; no fabricable en test automatizado) | |
| 1.3 | Intenta iniciar sesión de nuevo con la Cuenta A. | El inicio de sesión falla (la cuenta ya no existe). | 🚫 No automatizable (depende de 1.2 ejecutado contra infraestructura real con cuenta desechable real) | |

---

## 2. Eliminar cuenta con documentos sin foto

> Inicia sesión con la Cuenta B (tiene SOAT o RTM sin foto adjunta).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Verifica antes de borrar que el vehículo con SOAT/RTM sin foto sigue visible normalmente en el garage. | El vehículo y su documento aparecen en la app sin foto, sin errores visuales. | 👤 Manual (requiere cuenta real (Cuenta B) con datos previamente sembrados en backend real; verificación visual/subjetiva de render con datos reales) | |
| 2.2 | Confirma la eliminación de la Cuenta B. | El borrado se completa sin error ni mensaje de falla; no se queda cargando indefinidamente. | 🚫 No automatizable (borrado real e irreversible contra backend/Firebase Auth real con cuenta desechable específica) | |
| 2.3 | Intenta iniciar sesión de nuevo con la Cuenta B. | El inicio de sesión falla (la cuenta ya no existe). | 🚫 No automatizable (depende de 2.2 ejecutado contra infraestructura real) | |

---

## 3. Eliminar cuenta con imagen huérfana o URL corrupta en Storage

> Inicia sesión con la Cuenta C (tiene una imagen de vehículo borrada manualmente del bucket o con URL corrupta).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Confirma la eliminación de la Cuenta C. | El borrado se completa sin error 500 ni mensaje de falla visible para el usuario, a pesar de que una de las imágenes ya no existe en el bucket. | 🚫 No automatizable (requiere cuenta real con objeto de Storage borrado manualmente/URL corrupta y borrado real contra backend/Storage reales; el equivalente ya está cubierto a nivel unitario mockeado en `storage-cleanup.service.spec.ts`, pero verificar el bucket real no es automatizable aquí) | |
| 3.2 | Intenta iniciar sesión de nuevo con la Cuenta C. | El inicio de sesión falla (la cuenta ya no existe): el fallo de borrar una sola imagen no bloqueó el resto del proceso. | 🚫 No automatizable (depende de 3.1 ejecutado contra infraestructura real) | |

---

## 4. Eliminar cuenta con garage vacío

> Inicia sesión con la Cuenta D (sin ningún vehículo registrado).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Confirma la eliminación de la Cuenta D. | El borrado se completa sin error, de forma tan rápida y fluida como con cualquier otra cuenta. | 🚫 No automatizable (requiere cuenta real desechable sin vehículos y borrado real e irreversible contra backend/Firebase Auth; la lógica de garage vacío ya está cubierta a nivel unitario mockeado en `vehicles.service.spec.ts` y `account-deletion.service.spec.ts`, pero el flujo real de UI no es automatizable aquí) | |
| 4.2 | Intenta iniciar sesión de nuevo con la Cuenta D. | El inicio de sesión falla (la cuenta ya no existe). | 🚫 No automatizable (depende de 4.1 ejecutado contra infraestructura real) | |

---

## 5. Regresión visual — pantalla de confirmación sin cambios

> Esta fase es 100% backend; la pantalla de confirmación no debió tocarse. Usa cualquier cuenta de prueba adicional que NO vayas a eliminar (o cancela antes del paso final).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Abre Perfil → Eliminar cuenta y compara el texto y diseño con capturas previas a esta fase (si las tienes) o con tu recuerdo del flujo de fase 1. | El copy, los botones y el diseño de la pantalla son idénticos a los de fase 1 — no hay textos, botones ni pasos nuevos. | 🤖✅ Auto-PASS (`test/features/profile/presentation/delete_account_confirmation_page_test.dart` :: los 4 widget tests) | ✅ |
| 5.2 | Cancela el flujo antes de confirmar el borrado. | La cuenta permanece intacta, puedes seguir usando la app con normalidad. | 🤖✅ Auto-PASS (`test/features/profile/presentation/cubit/delete_account_cubit_test.dart` :: guard de doble-tap + estado inicial del botón deshabilitado en `delete_account_confirmation_page_test.dart`) | ✅ |

---

## 6. Casos de borde

### 6A. Fallo de red durante el borrado

> Con una cuenta de prueba desechable, provoca una desconexión de red justo después de tocar "Confirmar eliminación" (por ejemplo activando modo avión a mitad del proceso, si es posible reproducirlo).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6A.1 | Corta la conexión a internet justo al confirmar el borrado. | La app muestra un error de red claro (no un crash ni una pantalla en blanco); no queda en un estado intermedio confuso para el usuario. | 🤖✅ Auto-PASS (`test/features/profile/presentation/delete_account_confirmation_page_test.dart` :: 'estado error muestra el banner con mensaje y el botón cambia a Reintentar') | ✅ |
| 6A.2 | Restablece la conexión y vuelve a intentar el borrado con la misma cuenta. | El reintento completa el borrado correctamente (o indica claramente que ya no puede continuar). | 👤 Manual (requiere reproducir una desconexión real de red a mitad de un borrado real de cuenta en un dispositivo, y que el backend real complete o rechace el reintento; no reproducible de forma determinista en test automatizado) | |

### 6B. Documento sin foto combinado con vehículo con foto en la misma cuenta

> Usa una cuenta con al menos un vehículo con foto normal y otro documento (SOAT o RTM) sin foto, en la misma cuenta.

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6B.1 | Confirma la eliminación de esa cuenta mixta. | El borrado se completa sin error; tanto la imagen del vehículo con foto como los registros sin foto se eliminan correctamente (ver verificación técnica 7.3). | 🤖✅ Auto-PASS (`rideglory-api/vehicles-ms/src/vehicles/vehicles.service.spec.ts` + `rideglory-api/api-gateway/src/ai/storage-cleanup.service.spec.ts` :: 'filtrado de nulls + dedupe' (vehicles) + 'filtrado de null/undefined/\'\'' (storage-cleanup)) | ✅ |

---

## 7. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos, a la consola de Firebase Storage o a los logs del backend. Ejecútalas inmediatamente después de cada borrado de las secciones 1 a 4, usando los IDs anotados en las pre-condiciones.

| # | Verificación | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 7.1 | Query directa a Postgres de `vehicles-ms`: buscar filas de `Vehicle`, `Soat` y `Tecnomecanica` con el `ownerId`/`vehicleId` de la Cuenta A (o cualquier cuenta borrada con vehículos). | No existe ninguna fila para ese `ownerId`/`vehicleId` en ninguna de las 3 tablas. | 🤖✅ Auto-PASS (`rideglory-api/vehicles-ms/src/vehicles/vehicles.service.spec.ts` :: `hardDeleteAllByOwner` (transacción Soat→Tecnomecanica→Vehicle)) | ✅ |
| 7.2 | Query directa a Postgres de `maintenances-ms`: buscar registros de `Maintenance` con el `userId` de la Cuenta A. | Todos los registros de ese `userId` tienen `isDeleted: true` (soft delete, no borrado físico). | 🤖✅ Auto-PASS (`rideglory-api/maintenances-ms/src/maintenances/maintenances.service.spec.ts` :: soft-delete de Maintenance por userId (isDeleted: true)) | ✅ |
| 7.3 | En la consola de Firebase Storage (o `bucket.file(path).exists()`), verificar las URLs anotadas de fotos de vehículo, SOAT y RTM de la Cuenta A. | Ninguno de esos objetos existe ya en el bucket. | 👤 Manual (requiere acceso a la consola de Firebase Storage o `bucket.file(path).exists()` de un proyecto real con objetos reales previamente subidos; no fabricable en test unitario/mockeado ni en este entorno) | |
| 7.4 | Revisar los logs de `api-gateway` durante el borrado de la Cuenta C (imagen huérfana). | Se ve un log de advertencia (`warn`) indicando que un archivo individual no se pudo borrar, sin ningún error 500 propagado al cliente ni excepción sin capturar. | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/ai/storage-cleanup.service.spec.ts` :: 'fallo individual no aborta el batch (objeto inexistente)') | ✅ |
| 7.5 | Query a Postgres de `vehicles-ms` para la Cuenta D (garage vacío) tras el borrado. | No hay filas huérfanas ni errores en el proceso; el resultado interno reporta 0 vehículos borrados sin haber lanzado excepción. | 🤖✅ Auto-PASS (`rideglory-api/vehicles-ms/src/vehicles/vehicles.service.spec.ts` :: caso 'garage vacío') | ✅ |
| 7.6 | Confirmar en el schema de Prisma de `vehicles-ms`/`maintenances-ms` que no se agregó `onDelete: Cascade`. | El schema sigue sin `onDelete: Cascade` para estas relaciones (decisión explícita del Architect: borrado explícito en la capa de servicio). | 🤖✅ Auto-PASS (n/a — verificación por comando, no test: `git diff --stat -- '**/schema.prisma'` + grep de `onDelete` en vehicles-ms/maintenances-ms) | ✅ |
| 7.7 | Confirmar que `DELETE /users/me` no cambió de firma ni de respuesta HTTP respecto a fase 1. | El contrato del endpoint público es idéntico; los pasos nuevos son internos vía `MessagePattern` (`hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId`), sin endpoints HTTP nuevos. | 🤖✅ Auto-PASS (`rideglory-api/api-gateway/src/users/users.controller.ts` (lectura) + `npx jest src/users` :: contrato DELETE /users/me sin cambios + suite existente de `account-deletion.service.spec.ts`) | ✅ |

---

## 👤 Solo para ti — pruebas manuales restantes

No hubo casos 🤖❌ auto-fail. Esta es la lista corta de lo que queda por ejecutar a mano (👤 manual):

| # | Acción | Qué revisar | Por qué no se automatizó |
|---|--------|--------------|---------------------------|
| 2.1 | Verifica antes de borrar que el vehículo con SOAT/RTM sin foto sigue visible normalmente en el garage (Cuenta B). | Que el vehículo y su documento aparecen en la app sin foto, sin errores visuales. | Requiere una cuenta real (Cuenta B) con datos previamente sembrados en backend real; es una verificación visual/subjetiva con datos reales, no solo con mocks. |
| 6A.2 | Restablece la conexión y vuelve a intentar el borrado con la misma cuenta. | Que el reintento completa el borrado correctamente o indica claramente que ya no puede continuar. | Depende de reproducir una desconexión real de red a mitad de un borrado real de cuenta en un dispositivo, y de que el backend real complete o rechace el reintento; no reproducible de forma determinista en test automatizado. |
| 7.3 | En la consola de Firebase Storage (o `bucket.file(path).exists()`), verificar las URLs anotadas de fotos de vehículo, SOAT y RTM de la Cuenta A. | Que ninguno de esos objetos existe ya en el bucket. | Requiere acceso a la consola de Firebase Storage (o `bucket.file(path).exists()`) de un proyecto real con objetos reales previamente subidos; no fabricable en un test unitario/mockeado ni en este entorno. |

---

## 🚫 No automatizable en este entorno

| # | Acción | Cómo habilitarlo |
|---|--------|-------------------|
| 1.2 | Confirma la eliminación de la Cuenta A (datos completos). | Boot de emulador/dispositivo + backend real levantado + cuenta desechable con datos completos sembrados; correr manualmente contra `rideglory-api` real e irreversible. |
| 1.3 | Intenta iniciar sesión de nuevo con la Cuenta A. | Depende de 1.2; ejecutar inmediatamente después contra el mismo entorno real. |
| 2.2 | Confirma la eliminación de la Cuenta B (documentos sin foto). | Igual que 1.2 pero con Cuenta B (SOAT/RTM sin foto) previamente sembrada. |
| 2.3 | Intenta iniciar sesión de nuevo con la Cuenta B. | Depende de 2.2. |
| 3.1 | Confirma la eliminación de la Cuenta C (imagen huérfana o URL corrupta). | Requiere borrar manualmente un objeto del bucket de Storage o corromper una URL en la BD de una cuenta real desechable antes de correr el borrado; el comportamiento ya está cubierto a nivel unitario mockeado en `storage-cleanup.service.spec.ts`. |
| 3.2 | Intenta iniciar sesión de nuevo con la Cuenta C. | Depende de 3.1. |
| 4.1 | Confirma la eliminación de la Cuenta D (garage vacío). | Boot de emulador/dispositivo + backend real + cuenta desechable nueva sin vehículos; la lógica ya está cubierta a nivel unitario mockeado. |
| 4.2 | Intenta iniciar sesión de nuevo con la Cuenta D. | Depende de 4.1. |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–7 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (por ejemplo, mensajería de error poco clara en 6A), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 4 o 7 (borrado incompleto, error 500, filas/imágenes huérfanas, o cambios no autorizados de copy/UI en la sección 5) marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| # | Estrategia | Test file | Resultado |
|---|-----------|-----------|-----------|
| 1.1 | Widget test — regresión visual de la pantalla de confirmación (existente, sin cambios de copy/UI en esta fase) | `test/features/profile/presentation/delete_account_confirmation_page_test.dart` | ✅ pass (4/4) |
| 5.1 | Widget test — mismo archivo que 1.1, confirma paridad con fase 1 | `test/features/profile/presentation/delete_account_confirmation_page_test.dart` | ✅ pass (4/4) |
| 5.2 | Unit/bloc_test — guard de doble-tap y estado inicial del botón deshabilitado + widget test de cancelación | `test/features/profile/presentation/cubit/delete_account_cubit_test.dart` + `delete_account_confirmation_page_test.dart` | ✅ pass |
| 6A.1 | Widget test — estado de error tras fallo de red simulado (mock del cubit en estado error) | `test/features/profile/presentation/delete_account_confirmation_page_test.dart` :: 'estado error muestra el banner con mensaje y el botón cambia a Reintentar' | ✅ pass |
| 6B.1 | Unit test (Jest) — filtrado de nulls/dedupe en borrado de imágenes mixtas (con foto + sin foto) | `rideglory-api/vehicles-ms/src/vehicles/vehicles.service.spec.ts` + `rideglory-api/api-gateway/src/ai/storage-cleanup.service.spec.ts` | ✅ pass |
| 7.1 | Unit test (Jest) — transacción `hardDeleteAllByOwner` (Soat→Tecnomecanica→Vehicle) | `rideglory-api/vehicles-ms/src/vehicles/vehicles.service.spec.ts` | ✅ pass |
| 7.2 | Unit test (Jest) — soft-delete de Maintenance por userId (`isDeleted: true`) | `rideglory-api/maintenances-ms/src/maintenances/maintenances.service.spec.ts` | ✅ pass |
| 7.4 | Unit test (Jest) — fallo individual de Storage no aborta el batch, se loguea warn | `rideglory-api/api-gateway/src/ai/storage-cleanup.service.spec.ts` :: 'fallo individual no aborta el batch (objeto inexistente)' | ✅ pass |
| 7.5 | Unit test (Jest) — caso garage vacío, 0 vehículos borrados sin excepción | `rideglory-api/vehicles-ms/src/vehicles/vehicles.service.spec.ts` :: caso 'garage vacío' | ✅ pass |
| 7.6 | Verificación por comando (no es test) — diff de schema.prisma + grep de `onDelete` | n/a — `git diff --stat -- '**/schema.prisma'` + grep en vehicles-ms/maintenances-ms | ✅ sin `onDelete: Cascade` agregado |
| 7.7 | Lectura de contrato + suite Jest existente — `DELETE /users/me` sin cambios de firma/HTTP | `rideglory-api/api-gateway/src/users/users.controller.ts` (lectura) + `npx jest src/users` | ✅ pass |

**Tests rechazados por el auditor Opus:** ninguno (0 tests vacíos o triviales rechazados en esta corrida).

### Cómo correr los tests generados

```bash
# Flutter (desde la raíz del repo Flutter)
cd .
flutter test test/features/profile/presentation/delete_account_confirmation_page_test.dart
flutter test test/features/profile/presentation/cubit/delete_account_cubit_test.dart

# Backend (desde cada microservicio en rideglory-api)
cd rideglory-api/vehicles-ms && npx jest src/vehicles/vehicles.service.spec.ts
cd rideglory-api/maintenances-ms && npx jest src/maintenances/maintenances.service.spec.ts
cd rideglory-api/api-gateway && npx jest src/ai/storage-cleanup.service.spec.ts
cd rideglory-api/api-gateway && npx jest src/users
```

### Regresión e2e de inscripción (Patrol)

**Estado:** `fail`

Los 34 pasos funcionales del Patrol (login, tab Eventos, detalle "Mi Evento", wizard de 4 pasos, consentimiento Ley 1581, selección de vehículo, confirmar inscripción, waiver de riesgos, y la aserción final "Tu solicitud está siendo revisada por el organizador.") pasaron todos. Inmediatamente después, una `PlatformException` async no capturada de Mapbox ("Source 'rg-route-source' is not in style", `RouteMapPreview`) tumbó el test — regresión del guard `_guardMapCamera` documentado en el propio archivo de test. Adicionalmente, la verificación de BD post-corrida reveló que la inscripción reportada como 201 por el backend nunca se persistió en la tabla `EventRegistration` (bug independiente, más severo).

Entorno: fue necesario levantar Docker Desktop (contenedores de BD con restart policy ya existentes, datos intactos) y arrancar temporalmente los 6 microservicios Node (users-ms, vehicles-ms, events-ms, maintenances-ms, notifications-ms, api-gateway) que no estaban corriendo; se detuvieron al finalizar. Pre-limpieza y limpieza final del `DELETE` de qa1/Mi Evento/PENDING: 0 filas ambas veces (consistente con que la inscripción nunca se persistió). Artefacto escrito: `docs/exec-runs/eliminacion-cuenta-phase-02/QA_REGRESSION_registration_2026-07-11.md` con sección "Fixes requeridos" (2 items: persistencia de events-ms y regresión de Mapbox guard). Working tree queda sucio para revisión humana; no se tocó `lib/` ni `src/`, no se corrió ningún comando git de escritura.

Comando:
```bash
patrol test -t integration_test/registration_patrol_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --dart-define=TEST_EMAIL=qa1@gmail.com --dart-define=TEST_PASSWORD=Test123.
```

**Verificación de BD post-e2e (persistencia real del consentimiento):** `fail`. api-gateway respondió 201 Created para `POST /api/events/{Mi Evento id}/registrations` (payload real, sin stub/mock en `registrations.controller.ts`, sin errores en logs de events-ms ni api-gateway), pero la fila NUNCA quedó persistida en `EventRegistration`: `count(*)` siguió en 5 y `max(createdAt)` siguió en 2026-07-07, sin ninguna fila para qa1@gmail.com en ningún evento tras la corrida. Bug real de persistencia backend, independiente del crash de Mapbox que hizo fallar el test — confirma que la inscripción persistió `medicalConsentVersion` + `riskAcceptanceVersion`, no solo que la UI mostró "pendiente".

Este e2e + verificación de BD corre en CADA corrida de qa-auto cuando hay device (regresión permanente del flujo de inscripción), independiente de los casos del checklist de esta fase.

### Siguientes pasos

- No hubo casos 🤖❌ auto-fail en el checklist de esta fase (eliminación de cuenta), por lo que no hay bugs nuevos que investigar en esa área.
- La regresión e2e de inscripción (Patrol) reveló 2 bugs reales que requieren atención independiente de esta fase:
  1. **Persistencia de events-ms:** `POST /api/events/{id}/registrations` responde 201 pero no persiste la fila en `EventRegistration` — investigar `registrations.controller.ts`/`registrations.service.ts` en events-ms.
  2. **Regresión del guard `_guardMapCamera` en `RouteMapPreview`:** `PlatformException` no capturada de Mapbox ("Source 'rg-route-source' is not in style") tumba el test tras completar el flujo funcional — revisar el guard documentado en `integration_test/registration_patrol_test.dart`.
- Para habilitar los 8 casos 🚫 no automatizables (secciones 1-4) y los 3 👤 manuales: bootear un emulador/dispositivo con el backend real (`rideglory-api`) levantado, sembrar las cuentas desechables A/B/C/D descritas en las pre-condiciones, y re-correr manualmente siguiendo los pasos del checklist original.
