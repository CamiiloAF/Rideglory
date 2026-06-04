# 05 — Síntesis final del PO — Tecnomecánica (RTM)

**Slug:** `tecnomecanica-rtm`
**Generado:** 2026-06-04T13:13:01Z
**Rol:** Product Owner (consolidación final)
**Insumos:** `02-po-proposal.md`, `03-architect-review.md`, `04-plan-review.md` + ajustes del Architect, del Plan Reviewer y del Auditor Opus.

> Sesión de planeación. No se modifica código de la app. Este artefacto es la **fuente de verdad ejecutable** del plan: integra todas las decisiones (ADR-A..F), resuelve las preguntas abiertas pendientes (R7/A5 sobre el route del deep-link) y baja a cada fase los criterios de aceptación observables que antes vivían dispersos en 03 (Criterio de cierre) y 04 (Gates). El plan se ejecuta con `rg-exec`, una fase por corrida.

---

## Overview

Rideglory ya soporta el SOAT de un vehículo (captura manual, estado en 4 niveles, vencimiento, badge en el detalle de la moto, recordatorios push a 30/7/0 días). Esta iteración añade la **Revisión Técnico-Mecánica (RTM / tecnomecánica)** con **paridad funcional total** respecto al SOAT, pero sin OCR (captura 100% manual).

El trabajo no es "copiar SOAT": el scan reveló que SOAT tiene deuda estructural (modelo no-freezed con payload `Map` a mano, badge con `getIt` dentro del widget + `bool _isLoading` + strings hardcodeados, un `SoatModel` **duplicado** en `vehicles/` que colisiona de nombre). Por eso el plan **primero extrae una abstracción reutilizable** `vehicle_documents/` y migra SOAT a ella con **regresión cero**, y **luego** monta RTM como espejo fino sobre esa base. Esto habilita el reuso real (un tercer documento futuro sería capa fina) y un **split de PRs** limpio: Fase 1 (refactor SOAT en Flutter), Fase 2 (backend en `rideglory-api`), Fases 3–5 (RTM front + notifs).

Resultado al cierre: el conductor **registra, ve, edita y borra** su RTM; ve **dos badges** (SOAT + RTM) en el detalle de la moto; recibe **recordatorios push** a 30/7/0 días; y ve una **nota informativa no bloqueante** de exención por antigüedad (<2 años).

---

## Cambios aplicados

Sobre la propuesta original (02) se aplicaron todos los ajustes de Architect (03), Plan Reviewer (04) y Auditor Opus:

**Arquitectura (ADRs fijados antes de codificar):**
- **ADR-A** — Abstracción vía `mixin VehicleDocumentExpiry` + `abstract class VehicleDocumentModel` (NO freezed). Preserva Pattern B (`SoatDto extends SoatModel`) y la firma pública de `SoatModel`. `VehicleDocumentStatus { none, valid, expiringSoon, expired }` reemplaza 1:1 a `SoatStatus` sin tocar analytics.
- **ADR-B** — NO migrar el `toRequestJson()` manual de SOAT a DTO en esta iteración (deuda documentada). RTM nace con `CreateTecnomecanicaRequestDto` + `.toJson()`, cumpliendo "write payloads via DTO toJson" en lo nuevo sin reabrir SOAT.
- **ADR-C** — Base abstracta `VehicleDocumentCubit<T extends VehicleDocumentModel>`. `SoatCubit extends VehicleDocumentCubit<SoatModel>` conservando `ResultState<SoatModel>` → ningún `BlocBuilder`/test SOAT cambia.
- **ADR-D** — Solo se promueven widgets **genéricos puros** (`validity_card`, `detail_row`, `section_header`, `empty_state`, `status_view`, `data_view`); los OCR-específicos se quedan en `soat/`. Copy compartido se **inyecta por parámetro**, no por clave ARB común.
- **ADR-E** — Renombrar el `SoatModel` **duplicado** de `vehicles/` a `VehicleSoatFormData` como **primer paso** de la Fase 1 (elimina la colisión de nombre). NO implementa `VehicleDocumentModel`.
- **ADR-F** — Reescribir `vehicle_soat_card` como `VehicleDocumentCard` genérico parametrizado por `kind`, con cubit + `ResultState` (no `getIt`, no `bool`), strings en ARB. El contrato del genérico **soporta N badges desde el inicio** (A3) para que la Fase 4 sea capa fina.

**Producto / UX / Calidad:**
- **Strings en paralelo** (arch #4): claves `tecnomecanica_*` nuevas; claves SOAT intactas. No unificar a `document_status_*`.
- **Editar + borrar RTM** entran explícitamente en la Fase 3 (A4), alineado con el DELETE de la Fase 2 y los criterios globales.
- **GET sin documento → 404** fijado en el contrato de la Fase 2 (A6), preservando `404 → Right(null) → ResultState.empty()`.
- **RTM parte del genérico limpio sin OCR** (A7): sin autofill banner, sin scan overlay `Stack`, sin "no reconocido", sin `ScanSoatUseCase`. Cada pieza de UI en su propio widget.
- **Payload RTM vía `.toJson()` del DTO** (A8), nunca `Map` a mano.
- **Nota de exención <2 años** = info chip no bloqueante (A9), nunca error ni gate de guardado.
- **Copy legal propio de RTM vencida** (A10), no reutilizar el literal del SOAT.
- **Gate de no-acoplamiento** (A11): `vehicles/` no importa `soat/` ni `tecnomecanica/` concretos, solo `vehicle_documents/`. Verificable por grep de imports.
- **Regresión cero también en backend** (A12): los 3 crons SOAT siguen vivos tras el helper genérico; tests SOAT verdes sin tocar acceptance.

**Decisión de route del deep-link (resuelve R7 / A5, antes pregunta abierta):**
- El route de las notificaciones RTM es **`rideglory://garage`**, paridad exacta con SOAT (verificado: SOAT hoy usa ese route y el deep-linking funciona). **No se abre una pantalla nueva de routing en esta iteración.**
- La variante **`detail-by-id`** (abrir el detalle de la moto por `vehicleId` directamente) queda **explícitamente fuera de alcance** de esta iteración. No es una ambigüedad latente: es una decisión tomada.
- **Bloqueo previo a Fase 5:** se requiere una confirmación de una línea del PO humano de que `rideglory://garage` es aceptable como destino (paridad SOAT). Si el PO humano quiere `detail-by-id`, se reabre alcance y se contabiliza el trabajo de routing como ítem nuevo. Mientras no haya respuesta, la Fase 5 no arranca.

**Split de PRs (confirmado):**
- PR #1 = Fase 1 (refactor SOAT, el corte más pesado en Flutter, independiente).
- PR #2 = Fase 2 (`rideglory-api`, repo separado).
- PR #3 = Fases 3–5 (RTM front + notifs). Umbral ~40 archivos respetado.

---

## Lista final de fases

| # | Título | Goal (valor) | dependsOn | Nivel | Por qué (riesgo / blast radius) |
|---|--------|--------------|-----------|-------|----------------------------------|
| 1 | Abstracción `vehicle_documents/` + refactor SOAT (regresión cero) | El conductor ve y gestiona su SOAT exactamente igual que hoy, pero sobre una base reutilizable lista para más documentos. | — | **full** | Refactor estructural cross-cutting de mayor blast radius: toca model+cubit+widgets+badge de SOAT (feature en producción), reconcilia no-freezed con Pattern B, renombra un modelo duplicado, fija el contrato del genérico para N badges. Difícil de revertir, criterio duro de regresión cero. Justifica QA adversarial + 3 rondas + fix loops. |
| 2 | Backend: persistencia y consulta de tecnomecánica | El sistema guarda, lee y borra la RTM de un vehículo vía API con las mismas garantías de seguridad/validación que SOAT. | 1 | **full** | Cambio de contrato `rideglory-api` + **migración Prisma** (tabla nueva) + auth/ownership/PII. Migración local→humano→remoto es irreversible sin cuidado. Aunque el servicio es copia mecánica de SOAT, migración + contrato + seguridad obligan el nivel máximo. |
| 3 | Registrar, ver, editar y borrar la RTM desde la app | El conductor captura manualmente su RTM, la guarda, la consulta, la edita y la borra; ve estado y vencimiento. | 1, 2 | **normal** | Feature de UI acotada (1 área: `tecnomecanica/`), espejo fino sobre los genéricos ya probados de Fase 1. Consume contrato de Fase 2. Riesgo medio (lógica de fechas, estados, payload DTO), sin migraciones ni cambios de contrato propios. Architect+Build+QA+2 rondas+Tech Lead cubren el riesgo sin necesidad de full. |
| 4 | Doble badge de documentos en el detalle del vehículo | En el detalle de su moto el conductor ve de un vistazo SOAT **y** RTM y entra a cada flujo con un tap. | 1, 3 | **normal** | Capa fina sobre el `VehicleDocumentCard` genérico de Fase 1, pero es el **punto de acoplamiento crítico**: el gate de no-importar features concretos en `vehicles/` y la carga independiente por badge tienen riesgo de regresión visual/arquitectónico medio. No hay contrato ni migración. Normal con gate explícito de imports basta. |
| 5 | Recordatorios push y centro de notificaciones para RTM | El conductor recibe avisos automáticos a 30/7/0 días del vencimiento de su RTM y, al tocarlos, llega a su garage. | 1, 2 | **full** | Backend `rideglory-api`: refactor del scheduler de notificaciones (regresión cero en 3 crons SOAT vivos), 3 `NotificationType` nuevos duplicados en **2 paquetes** (desincronización), 3 crons cron-scheduled. Cross-cutting en notificaciones + riesgo de romper crons en producción → la rúbrica lo clasifica como full (contrato + cross-cutting + difícil de revertir si un cron falla en prod). |
| 6 | Calidad, regresión y documentación | El equipo cierra con garantía de que SOAT no se rompió, RTM funciona en sus 4 estados y la abstracción queda documentada. | 1, 2, 3, 4, 5 | **normal** | No introduce comportamiento nuevo: tests unit de la lógica de estado (4 estados, SOAT y RTM), test parametrizado del cubit base, verificación visual de los 2 badges juntos, docs. Bajo riesgo de implementación pero **bloqueante**: cierra el alcance. Normal (no lite) porque la verificación de integración de los dos badges + regresión cruzada requiere QA real, no una sola pasada. |

> **Nota de tier sobre Fase 2 y 5:** ambas son "espejos mecánicos" de SOAT y podrían tentar a `normal`. Se elevan a `full` porque la rúbrica marca explícitamente **migraciones de datos** (Fase 2) y **cambios de contrato cross-cutting con riesgo de romper crons en producción** (Fase 5) como `full`, independientemente de lo mecánica que sea la escritura. Ante la duda se eligió el menor nivel que cubre el riesgo real, y el riesgo real aquí es irreversibilidad/blast-radius en backend de producción.

---

## Criterios de aceptación por fase

Criterios **observables y testeables** que el Tech Lead exige para cerrar cada fase. Bajados de 03 (Criterio de cierre) y 04 (Gates).

**Transversales (toda fase Flutter):**
- `dart analyze` sin **nuevos** warnings.
- Clean Architecture: `domain/` sin Flutter/HTTP; `data/` sin `BuildContext`/widgets; `presentation/` sin HTTP directo ni DTO expuesto.
- Un widget por archivo; cero métodos `Widget _buildX()`.
- Texto/iconos oscuros sobre el primario (naranja); switch unificado si aparece.
- Strings vía `context.l10n.<key>` — cero literales hardcodeados.

**Fase 1 — Abstracción + refactor SOAT:**
- Suite SOAT **verde sin editar su acceptance** (si un test SOAT requiere cambiar su assertion, es regresión, no refactor).
- `dart analyze` **sin nuevos warnings**.
- `dart run build_runner build` **sin conflictos** (los `.g.dart` de DTO no cambian de forma → Pattern B intacto).
- **Cero literales hardcodeados** en el card de badge (`'Vigente'`, `'Por vencer'`, `'Vence {fecha}'` movidos a `app_es.arb`).
- **Cero `getIt<...>()` dentro de un widget**: el card genérico consume un cubit `@injectable` vía `BlocProvider`/`context.read`; sin `bool _isLoading` (usa `ResultState`).
- `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel` sin romper Pattern B; serialización SOAT intacta.
- El `SoatModel` duplicado de `vehicles/` renombrado a `VehicleSoatFormData` (colisión de nombre eliminada).
- El contrato del genérico soporta N badges (cubit/usecase parametrizado por `kind`).

**Fase 2 — Backend persistencia RTM:**
- Firebase Auth guard en las **3 rutas** `/tecnomecanica` (POST/GET/DELETE).
- `validateVehicleOwnership` en **upsert/find/delete** (espejo SOAT).
- Regla `expiry > start` validada **server-side**.
- **GET responde 404 cuando no existe** documento (NO `200 {data:null}`) → preserva `404 → Right(null) → ResultState.empty()` en frontend.
- `CreateTecnomecanicaDto` con required/optional **explícitos**: `certificateNumber` y `cdaName` required; `cdaCode?`, `startDate?`, `documentUrl?` optional; **`expiryDate` required (non-null)**. UI ↔ validador alineados (no replicar el mismatch latente de SOAT donde el server exige `startDate`/`insurer` que el cliente omite).
- Migración Prisma **validada localmente por un humano** antes de remoto (la fase no cierra sin esto).
- `tecnomecanica.service.spec.ts` cubre **upsert / find / delete / expiring**.

**Fase 3 — Registrar/ver/editar/borrar RTM:**
- Payload de escritura vía **`.toJson()` del DTO** (`CreateTecnomecanicaRequestDto`), **no** un `Map` a mano.
- `TecnomecanicaModel implements VehicleDocumentModel` + `TecnomecanicaDto extends TecnomecanicaModel` (Pattern B).
- Cubit RTM extiende `VehicleDocumentCubit<TecnomecanicaModel>`, usa `ResultState<T>`, mapea **404 → `empty`**.
- Eventos analytics `tecnomecanica_*` en **snake_case, ≤40 chars**, claves propias (no reusar SOAT).
- **Nota de exención <2 años** como widget informativo **no bloqueante** (info chip), nunca error ni gate de guardado.
- **Editar y borrar** una RTM ya registrada **funcionando** (no solo registrar/ver).
- Parte del **genérico limpio sin OCR** (sin autofill banner, sin scan overlay, sin "no reconocido"); cada pieza de UI en su propio widget.
- **Copy legal propio de RTM vencida** (no el literal del SOAT).

**Fase 4 — Doble badge:**
- `vehicles/` **no importa** `soat/` ni `tecnomecanica/` concretos, solo `vehicle_documents/` — **verificable por grep de imports** (gate falla si aparece import concreto).
- **Carga independiente por badge** (uno puede estar `loading` mientras el otro tiene `data`; sin bloqueo cruzado, sin parpadeo/reflow).
- **Regresión visual del badge SOAT**: los 4 estados se ven y se comportan idénticos a hoy; loading skeleton por badge preservado.
- Dos badges renderizan juntos (SOAT arriba, RTM debajo), mismo alto/spacing.

**Fase 5 — Recordatorios push RTM:**
- Los **3 `NotificationType`** (`TECNOMECANICA_30D | 7D | DAY_OF`) presentes en **AMBOS** archivos (`api-gateway` + `notifications-ms`).
- Los **3 crons SOAT siguen vivos** tras el refactor a `sendDocumentExpiryReminders(kind, days, type)` (regresión cero backend).
- **Tests de crons con fixtures 30/7/0 días**; `notifications.service.spec.ts` actualizado.
- `route` = **`rideglory://garage`** (paridad SOAT) en el payload de cada notificación.
- Copy RTM propio por notificación (distinto del SOAT).
- **Bloqueo previo:** confirmación de una línea del PO humano sobre `rideglory://garage` antes de arrancar (ver R7/A5 en Cambios aplicados).

**Fase 6 — Calidad, regresión, docs (criterio de cierre formal):**
- Test unit de la lógica de estado (4 estados) a nivel `VehicleDocumentExpiry` con casos **SOAT y RTM**.
- Test **parametrizado del cubit base** por `kind`; widgets compartidos probados una sola vez.
- `flutter test` 100% y `dart analyze` limpio en **ambos repos**.
- Verificación manual de los **dos badges renderizando juntos** (punto de integración más frágil).
- Docs al día: `docs/features/tecnomecanica.md`, `docs/features/soat.md` actualizado, `vehicle_documents/` registrado en `CLAUDE.md`, endpoint backend documentado.
- **Criterio de cierre del alcance (regla formal):** la Fase 6 es de *verificación*, no de *parche*. **Si un test destapa una regresión, el bug vuelve a su fase de origen** (la fase que introdujo el cambio), no se arregla dentro de la Fase 6. La Fase 6 solo cierra cuando todas las fases de origen están verdes; su alcance es por tanto verificable y acotado, no abierto.

---

## Supuestos y riesgos

### Supuestos
1. El feature SOAT (iter-2) está terminado y estable, con suite de tests verde — es la plantilla 1:1 y la línea base de regresión cero.
2. `VehicleModel` expone `purchaseDate` (`DateTime?`) y `year` (`int?`) → la nota de exención <2 años es solo-UI, sin tocar backend.
3. El deep-linking de notificaciones ya funciona (`route` payload → `AppRouter.pushDeepLink`); RTM solo provee un `route` válido (`rideglory://garage`), no es trabajo nuevo.
4. Tablas **separadas** por decisión del PRD: `Tecnomecanica` es tabla propia espejo de `Soat`; servicios Retrofit también separados.
5. `notifications-ms` no requiere cambios de modelo de datos; solo se añaden valores a `NotificationType` en 2 archivos.
6. RTM **no incluye OCR** ni autofill; flujo de captura manual.
7. La migración Prisma corre local → validación humana → remoto; la Fase 2 no cierra sin esa validación.
8. El split de PRs es deseable y el umbral ~40 archivos se respeta.

### Riesgos
| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | Refactor SOAT rompe Pattern B / consumidores al genericar model+cubit+widgets. | Alta | ADR-A (mixin+interfaz, no freezed) + ADR-C (base genérica, `SoatCubit` mantiene `ResultState<SoatModel>`). Criterio duro: suite SOAT verde sin tocar acceptance. Tier **full** en Fase 1. |
| R2 | Colisión de nombre `SoatModel` (soat/ vs vehicles/). | Media | ADR-E: renombrar el de `vehicles/` a `VehicleSoatFormData` como primer paso de Fase 1. |
| R3 | Mismatch de contrato required/optional (latente en SOAT). | Media | Fijar `CreateTecnomecanicaDto` explícito; `expiryDate` required, `startDate` opcional; UI ↔ validador alineados. |
| R4 | Anti-patrón en el badge (`getIt` en widget + `bool _isLoading` + strings hardcodeados). | Media | ADR-F: `VehicleDocumentCard` con cubit + `ResultState` + ARB. Corregirlo es parte del valor de Fase 1/4. |
| R5 | `NotificationType` duplicado en 2 paquetes → desincronización. | Media | Checklist Fase 5 que toque ambos archivos + test que cubra los 3 tipos. |
| R6 | Fricción migración Prisma remota bloquea front contra entorno real. | Baja-Media | Front Fase 3 contra contrato/mock mientras se valida local. |
| R7 | Route del deep-link RTM. | **Resuelto** | Decidido `rideglory://garage` (paridad SOAT); `detail-by-id` fuera de alcance. Bloqueo previo a Fase 5 = confirmación de una línea del PO humano (no ambigüedad). |
| R8 | Deuda payload manual `toRequestJson` no migrada en SOAT. | Baja | ADR-B: aceptada como deuda documentada; RTM nace cumpliendo la regla. No reabrir SOAT. |
| R9 | Fase 1 sub-dimensionada respecto a la deuda real (limpieza de literales, `getIt`, duplicado, no-freezed + Pattern B). | Alta | Tier **full**; ADRs marcan explícitamente qué se generaliza vs. qué se deja como capa fina para que no se infle. |
| R10 | Frontera Fase 3 ↔ acoplamiento del badge (Fase 4). | Media | A3: el contrato del genérico (cubit/usecase por `kind`) nace en Fase 1, no se improvisa en Fase 4. |
