# Plan: tecnomecanica-rtm
> Estado: BORRADOR — revision humana pendiente. Generado: 2026-06-04T13:31:40Z

## Overview

Iteración que añade la Revisión Técnico-Mecánica (RTM/tecnomecánica) a Rideglory con paridad funcional total respecto al SOAT pero sin OCR (captura manual). No es un copy-paste de SOAT: primero se extrae una abstracción reutilizable vehicle_documents/ (mixin VehicleDocumentExpiry + abstract VehicleDocumentModel, base genérica VehicleDocumentCubit<T>, widgets genéricos puros, VehicleDocumentCard parametrizado por kind) y se migra SOAT a ella con regresión cero, cerrando de paso su deuda (getIt en widget, bool _isLoading, strings hardcodeados, SoatModel duplicado en vehicles/, payload Map a mano solo para lo nuevo). Luego se monta RTM como espejo fino. Backend en rideglory-api: tabla Tecnomecanica separada con migración, rutas REST con Firebase guard, helper de cron genérico con 3 crons RTM. Al cierre el conductor registra/ve/edita/borra su RTM, ve dos badges (SOAT+RTM) en el detalle, recibe push a 30/7/0 días (deep-link rideglory://garage, paridad SOAT; detail-by-id fuera de alcance) y ve una nota de exención <2 años no bloqueante. Split de PRs: Fase 1 (Flutter), Fase 2 (rideglory-api), Fases 3-5 (RTM). Artefacto completo en docs/plans/tecnomecanica-rtm/05-sintesis.md.

## Fases

- Fase 1 [FULL]: [Fase 1 — Abstracción vehicle_documents/ + refactor SOAT (regresión cero)](phases/phase-01-abstraccion-vehicle-documents-refactor-soat-regr.md)
- Fase 2 [FULL]: [Fase 2 — Backend: persistencia y consulta de tecnomecánica](phases/phase-02-backend-persistencia-y-consulta-de-tecnomecanica.md)
- Fase 3 [NORMAL]: [Fase 3 — Registrar, ver, editar y borrar la RTM desde la app](phases/phase-03-registrar-ver-editar-y-borrar-la-rtm-desde-la-ap.md)
- Fase 4 [NORMAL]: [Fase 4 — Doble badge de documentos en el detalle del vehículo](phases/phase-04-doble-badge-de-documentos-en-el-detalle-del-vehi.md)
- Fase 5 [FULL]: [Fase 5 — Recordatorios push y centro de notificaciones para RTM](phases/phase-05-recordatorios-push-y-centro-de-notificaciones-pa.md)
- Fase 6 [NORMAL]: [Fase 6 — Calidad, regresión y documentación](phases/phase-06-calidad-regresion-y-documentacion.md)

## Supuestos

1. El feature SOAT (iter-2) está terminado y estable, con suite de tests verde — es la plantilla 1:1 y la línea base de regresión cero.
2. `VehicleModel` expone `purchaseDate` (`DateTime?`) y `year` (`int?`) → la nota de exención <2 años es solo-UI, sin tocar backend.
3. El deep-linking de notificaciones ya funciona (`route` payload → `AppRouter.pushDeepLink`); RTM solo provee un `route` válido (`rideglory://garage`), no es trabajo nuevo.
4. Tablas **separadas** por decisión del PRD: `Tecnomecanica` es tabla propia espejo de `Soat`; servicios Retrofit también separados.
5. `notifications-ms` no requiere cambios de modelo de datos; solo se añaden valores a `NotificationType` en 2 archivos.
6. RTM **no incluye OCR** ni autofill; flujo de captura manual.
7. La migración Prisma corre local → validación humana → remoto; la Fase 2 no cierra sin esa validación.
8. El split de PRs es deseable y el umbral ~40 archivos se respeta.

## Riesgos

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

## Como ejecutar una fase

> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del titulo y la seccion "Ejecucion recomendada" de cada fase):
> Workflow({ name: 'rg-exec', args: { source: 'docs/plans/tecnomecanica-rtm/phases/phase-01-abstraccion-vehicle-documents-refactor-soat-regr.md', mode: '<lite|normal|full>' } })
> lite = mecanico/bajo riesgo; normal = feature acotada; full = complejo/riesgoso (contratos, migraciones, seguridad).
