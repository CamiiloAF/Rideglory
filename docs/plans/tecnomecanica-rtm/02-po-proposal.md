# 02 — Propuesta del PO — Tecnomecánica (RTM)

**Slug:** `tecnomecanica-rtm`
**Generado:** 2026-06-04T13:04:26Z
**Rol:** Product Owner
**Insumos:** `00-intake.md`, `01-scan.md`

> Sesión de planeación. No se modifica código. Las fases describen **comportamiento de usuario móvil** y dejan la app funcional al cierre de cada una. El orden está forzado por el scan: primero la abstracción + refactor SOAT (regresión cero), luego el espejo RTM. Esto habilita el split de PRs (corte refactor-SOAT independiente del corte-RTM).

---

## Fases propuestas

| # | Título | Goal (valor) | Resumen |
|---|--------|--------------|---------|
| 1 | Abstracción de documentos del vehículo + refactor SOAT (regresión cero) | El conductor sigue viendo y gestionando su SOAT exactamente igual que hoy, pero ahora sobre una base reutilizable lista para más documentos. | Se extrae `lib/features/vehicle_documents/`: `VehicleDocumentModel` (interfaz/base), enums `VehicleDocumentStatus` (sin / vigente / por vencer / vencido) y `VehicleDocumentKind`, la lógica de estado y `daysUntilExpiry` (umbral 30d) como mixin/helper compartido, cubit genérico parametrizado por `kind`, y se promueven los widgets candidatos (`validity card`, `status badge`, `detail row`, `section header`, `empty state`) a genéricos. `SoatModel` pasa a implementar la abstracción y SOAT consume los widgets/cubit genéricos. Se aísla/limpia el `SoatModel`/`SoatDto` duplicado en `vehicles/` para evitar colisión de nombres. **Criterio duro: todos los tests SOAT existentes pasan sin cambiar su acceptance; sin nuevos warnings de `dart analyze`.** Sin cambio visible para el usuario. Corte commit-able #1. |
| 2 | Backend: persistencia y consulta de tecnomecánica | El sistema puede guardar, leer y borrar la RTM de un vehículo vía API, con las mismas garantías de seguridad y validación que el SOAT. | En `rideglory-api`: tabla Prisma separada `Tecnomecanica` (`certificateNumber`, `cdaName`, `cdaCode?` + fechas) con migración (local → validación humana → remoto); `TecnomecanicaService` (espejo de `SoatService`: upsert con validación de propiedad y `expiry > start`, find por vehicle, delete 404, `findTecnomecanicasExpiringIn`); patterns RPC en `vehicles-ms`; rutas REST `POST/GET/DELETE /api/vehicles/:vehicleId/tecnomecanica` en api-gateway con Firebase Auth guard; `create-tecnomecanica.dto.ts`; `tecnomecanica.service.spec.ts`. Sin recordatorios todavía. El usuario aún no ve nada; habilita el frontend de la fase 3. |
| 3 | Registrar y ver la tecnomecánica desde la app | El conductor puede capturar manualmente los datos de su RTM, guardarlos y ver su estado y vencimiento dentro de la app. | `lib/features/tecnomecanica/` como espejo fino sobre los widgets/cubit genéricos: páginas Upload (selección de documento), ManualCapture (campos `certificateNumber`, `cdaName` texto libre, `cdaCode?`, fechas), Confirmation y Status. `SoatModel`-equivalente `TecnomecanicaModel implements VehicleDocumentModel`; `TecnomecanicaService` Retrofit (GET/POST/DELETE `/tecnomecanica`, servicio separado, 404→`Right(null)`→`empty`). Nota informativa **no bloqueante** de exención por antigüedad cuando la moto tiene <2 años desde `purchaseDate`. Strings `tecnomecanica_*` / `document_*` en `app_es.arb` (copy en español). Eventos analytics `tecnomecanica_*`. Al cierre el usuario ya registra y consulta su RTM por su propio flujo. |
| 4 | Doble badge de documentos en el detalle del vehículo | En el detalle de su moto el conductor ve de un vistazo el estado de SOAT **y** de RTM, y puede tocar cada uno para entrar a su flujo. | Se introduce el patrón de badge genérico parametrizado por `kind` (vía cubit/usecase genérico, eliminando el anti-patrón `getIt<…>()` directo del widget actual) para que `vehicles/` muestre N badges sin acoplarse a features concretos. El detalle del vehículo pasa a mostrar **dos badges** (SOAT + RTM), cada uno con sus 4 estados y tap-able hacia su flujo correspondiente. SOAT mantiene su comportamiento; RTM gana su entrada visible. |
| 5 | Recordatorios push y centro de notificaciones para RTM | El conductor recibe avisos automáticos a 30, 7 y 0 días del vencimiento de su RTM y, al tocarlos, llega al detalle de su moto. | En `rideglory-api`: refactor de `sendSoatReminders` → helper genérico `sendDocumentExpiryReminders(kind, days, notificationType)` (copy parametrizado por `kind`); 3 crons RTM (30d/7d/0d, `0 9 * * *` `America/Bogota`); 3 nuevos `NotificationType` (`TECNOMECANICA_30D/7D/DAY_OF`) en **ambos** paquetes (gateway + ms); `route` válido en el payload para deep-link. Tests de crons con fixtures de fechas; `notifications.service.spec.ts` actualizado. Las notificaciones aparecen en el centro de notificaciones existente y el tap usa el deep-link ya funcional. Corte commit-able #2 (RTM completo de punta a punta). |
| 6 | Calidad, regresión y documentación | El equipo cierra con la garantía de que SOAT no se rompió, RTM funciona en sus 4 estados y la abstracción queda documentada para el próximo documento. | Tests unit de la lógica de estado (4 estados) a nivel de `VehicleDocumentModel` con casos SOAT **y** RTM; test parametrizado del cubit genérico por `kind`; widgets compartidos probados una sola vez; `flutter test` al 100% y `dart analyze` sin nuevos warnings. Docs: nuevo `docs/features/tecnomecanica.md`, actualización de `docs/features/soat.md` por el refactor, registro de `tecnomecanica` y la abstracción `vehicle_documents/` en `CLAUDE.md`, y documentación del endpoint nuevo en `rideglory-api/docs/features/` si aplica. |

---

## Supuestos

1. **El feature SOAT (iter-2) está terminado y estable**, con su suite de tests verde; es la plantilla 1:1 y la línea base de regresión cero (declarado en el PRD y confirmado por el scan).
2. **`VehicleModel` ya expone `purchaseDate` (y `year`)** → la nota de exención <2 años se implementa solo con UI, sin tocar backend (resuelve pregunta abierta #3 del intake).
3. **El deep-linking de notificaciones ya funciona** (`route` payload + `AppRouter.pushDeepLink`, usado hoy por SOAT con `rideglory://garage`) → las notifs RTM solo necesitan proveer un `route` válido; no es trabajo nuevo (resuelve #5).
4. **Tablas separadas por decisión del PRD**: `Tecnomecanica` es tabla propia espejo de `Soat`, no una tabla genérica con discriminador `type`; los servicios Retrofit también son separados (`SoatService`, `TecnomecanicaService`), sin cliente HTTP unificado.
5. **`notifications-ms` no requiere cambios de modelo de datos**; el patrón ya soporta tipos adicionales (solo se añaden valores a `NotificationType` en 2 archivos).
6. **RTM no incluye OCR** ni autofill; el flujo es captura manual. Las páginas/cubits de OCR de SOAT (`scan`, `parser`, `upload_cubit` OCR) **no** se replican.
7. **La migración Prisma sigue la regla del proyecto**: se corre local primero, espera validación humana, y solo entonces remoto. La fase 2 no se da por cerrada hasta esa validación.
8. **El split de PRs es deseable**: la fase 1 produce un corte refactor-SOAT independiente, y las fases 2–5 producen el corte RTM; el Architect confirmará el umbral (≈40 archivos) y los puntos de corte exactos.

---

## Riesgos

1. **Reconciliar la abstracción con Pattern B (riesgo técnico #1).** `SoatModel` es clase pura no-freezed y su payload de escritura es un `Map` construido a mano, lo que choca con la regla "write payloads vía DTO `.toJson()`". Decidir base abstracta vs. mixin de lógica + interfaz, y si el payload migra a un DTO de request, es la decisión más delicada y bloquea la fase 1. **Mitigación:** resolverlo en Architect antes de codificar; mantener la firma pública de `SoatModel` para no romper consumidores.
2. **Regresión SOAT durante el refactor.** Promover widgets y cubit a genéricos puede romper analytics, navegación o estados de SOAT. **Mitigación:** criterio duro de tests SOAT verdes sin cambiar su acceptance; la fase 1 no se cierra si hay regresión.
3. **Colisión del `SoatModel`/`SoatDto` duplicado en `vehicles/`.** Existe un segundo `SoatModel` (forma distinta, usado por el alta de vehículo) que puede chocar con la abstracción. **Mitigación:** aislarlo/limpiarlo en la fase 1 antes de introducir el genérico; decisión de Architect sobre cuál es la fuente de verdad.
4. **Acoplamiento del badge en `vehicles/` (pregunta abierta #7).** El `vehicle_soat_card` actual está atado a `soat/` y usa `getIt` directo en un widget (anti-patrón). Añadir el 2º badge sin acoplar `vehicles/` a dos features concretos exige el patrón genérico de la fase 4. **Mitigación:** badge parametrizado por `kind` + usecase genérico; no replicar el anti-patrón.
5. **Decisión de copy genérico vs. específico (pregunta abierta #4).** Unificar strings de estado en `document_status_*` podría afectar la regresión SOAT; mantener claves SOAT y añadir RTM en paralelo es más seguro pero duplica. **Mitigación:** decisión explícita en fase 1/3; preferir paralelo para proteger regresión salvo que Architect indique lo contrario.
6. **Fricción operativa de la migración Prisma remota.** La fase 2 depende de validación humana antes del despliegue remoto; un retraso ahí bloquea el frontend de la fase 3 contra entorno real. **Mitigación:** el frontend puede desarrollarse y testearse contra contrato/mock mientras se valida la migración local.
7. **`NotificationType` duplicado en 2 paquetes.** Añadir los 3 tipos RTM en `notifications-ms` y `api-gateway` por separado es propenso a olvido/desincronización. **Mitigación:** checklist en la fase 5 que toque ambos archivos y un test que cubra los nuevos tipos.

---

## Criterios de éxito globales

- El conductor puede **registrar, ver, actualizar y borrar** la tecnomecánica de su moto con paridad funcional total respecto al SOAT (captura manual, estado, vencimiento).
- El detalle del vehículo muestra **dos badges** (SOAT + RTM), cada uno con sus **4 estados** (sin / vigente / por vencer / vencido) y tap-able hacia su flujo.
- El conductor recibe **recordatorios push a 30, 7 y 0 días** del vencimiento de la RTM, visibles en el centro de notificaciones, y el tap lo lleva al detalle de su moto vía deep-link.
- Se muestra una **nota informativa no bloqueante** de exención por antigüedad cuando la moto tiene <2 años.
- **Regresión cero en SOAT:** toda la suite de tests SOAT existente pasa sin cambiar su acceptance.
- **Reutilización real:** SOAT y RTM comparten modelo de estado, lógica de vencimiento, cubit, widgets y patrón de badge vía `vehicle_documents/`; un tercer documento futuro se montaría como espejo fino.
- **Backend:** tabla `Tecnomecanica` separada, rutas REST con Firebase guard, helper de cron genérico y 3 crons RTM en `America/Bogota`; migración aplicada local → validada por humano → remoto.
- **Calidad:** `flutter test` al 100% y `dart analyze` sin nuevos warnings en ambos repos; docs (`tecnomecanica.md`, `soat.md` actualizado, `CLAUDE.md`, endpoint backend) al día.
- **Split de PRs viable:** el refactor SOAT (fase 1) es un corte commit-able independiente del corte RTM (fases 2–5).
