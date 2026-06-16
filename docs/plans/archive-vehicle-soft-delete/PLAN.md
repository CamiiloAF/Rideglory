# Plan: archive-vehicle-soft-delete

> Estado: BORRADOR — revisión humana pendiente. Generado: 2026-06-16T16:44:32Z

## Overview

Implementar soft-delete de vehículos con ciclo de vida completo: el usuario puede archivar, restaurar, eliminar permanentemente un vehículo y marcar otro como principal — sin perder historial de inscripciones ni mantenimientos. "Marcar como principal" se diseña en Fase 2 (Frame 4) y se implementa en Fase 3 (Paso 6). La pantalla de inicio refleja siempre el vehículo principal vigente. El plan comprende 5 fases secuenciales con dos posibles paralelismos (Fases 1+2, y Fases 3+5 si hay capacidad). Secuencia recomendada para un solo desarrollador: Fase 1 (Backend) → Fase 2 (Diseño) → Fase 5 (Home coherente) → Fase 3 (Archivar/restaurar) → Fase 4 (Eliminación permanente). Correcciones del Auditor Opus integradas: HomeLoaded es sealed class manual (no freezed, sin build_runner), claves l10n reconciliadas con las existentes en app_es.arb, tie-break determinista para createdAt null en promoción de main, ConfirmationDialog ya soporta DialogActionType.danger, wiring de VehicleCard aclarado, tests mínimos verificables añadidos a los CA de Fases 3/4/5.

## Fases

- Fase 1 [FULL]: [Fase 1 — Backend: soft-delete e integridad de datos](phases/phase-01-backend-soft-delete-e-integridad-de-datos.md)
- Fase 2 [LITE]: [Fase 2 — Diseño Pencil: garaje con sección de archivados](phases/phase-02-diseno-pencil-garaje-con-seccion-de-archivados.md)
- Fase 3 [NORMAL]: [Fase 3 — Flutter: archivar y restaurar vehículos](phases/phase-03-flutter-archivar-y-restaurar-vehiculos.md) (auditoría con observaciones)
- Fase 4 [NORMAL]: [Fase 4 — Flutter: eliminación permanente desde archivados (v2 con correcciones Auditor Opus)](phases/phase-04-flutter-eliminacion-permanente-desde-archivados.md)
- Fase 5 [LITE]: [Fase 5 — Flutter: vehículo principal siempre coherente](phases/phase-05-flutter-vehiculo-principal-siempre-coherente.md)

## Supuestos

1. `PATCH /api/vehicles/:id` con `{ isArchived: true/false }` funciona correctamente en el backend y no requiere cambios en Fase 1.
2. `isDeleted` no viaja al cliente Flutter — los vehículos eliminados simplemente dejan de aparecer en `GET /api/vehicles/my`.
3. `maintenances-ms` ya tiene `softDeleteAllByVehicleId`; el api-gateway lo encadena al nuevo endpoint de soft-delete.
4. La Fase 2 (diseño) es bloqueante para la Fase 3 (implementación Flutter de archivado).
5. La Fase 1 (endpoint) es bloqueante para la Fase 4 (eliminación permanente Flutter).
6. Las Fases 3 y 5 son independientes entre sí — pueden ejecutarse en cualquier orden tras la Fase 2.
7. La promoción automática de main al archivar usa el mismo criterio en backend (`createdAt desc`) y en Flutter (`createdAt desc`, nulls al final, tie-break por `id` asc). Ambas implementaciones deben ser consistentes.
8. No se necesitan nuevas dependencias de pub para las fases Flutter.
9. `ConfirmationDialog` ya soporta `DialogActionType.danger` — confirmado. No se necesita un nuevo variant del shared widget para el diálogo destructivo.
10. `HomeLoaded` es `sealed class` manual (no freezed) — confirmado en `home_state.dart`. Eliminar `mainVehicle` no requiere `build_runner`.

## Riesgos

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|------------|
| R-1 | **Migración `isDeleted` en producción:** `prisma migrate dev` con filas existentes | Baja | Alto | Ejecutar localmente, revisar SQL, esperar verificación humana antes de desplegar (regla del proyecto). `DEFAULT false` es seguro. |
| R-2 | **Despliegue descoordinado backend/Flutter:** Fase 4 necesita endpoint de Fase 1 en producción | Media | Alto | Gate de entrada explícito en Fase 4. Alias `hard-delete/:id` temporal hasta confirmar Fase 4 en producción. |
| R-3 | **Promoción de main local no sincronizada con backend:** Flutter elige un sucesor distinto al backend cuando `createdAt` es null | Media | Medio | Tie-break determinista documentado: nulls al final, desempate por `id` asc. Implementación testeable con fixture de vehículos con `createdAt: null`. |
| R-4 | **`VehicleCard.onArchive`/`onUnarchive` mal wired:** lógica de negocio en el card en lugar del bottom-sheet | Baja | Medio | Los callbacks ya existen en `VehicleCard` (vehicle_card.dart:258-262). El cambio es solo pasarlos desde el parent. Regla: wiring solo en `GarageOptionsBottomSheet`/`GarageVehiclesContent`. |
| R-5 | **`findByIdOrNull` recibe filtro `isDeleted` por error:** rompe snapshots históricos de events-ms | Baja | Alto | Documentado en Fase 1: `findByIdOrNull` NO filtra `isDeleted`. Solo `findByOwnerId` y `findMainVehicleByOwnerId` filtran. |
| R-6 | **MCP Pencil caído bloquea Fase 2 y por tanto Fase 3** | Media | Medio | Regla del proyecto: no iniciar Fase 3 sin aprobación de diseño. Planificar Fase 2 al inicio del sprint. |
| R-7 | **`HomeLoaded.mainVehicle` con consumidores ocultos:** consumidores conocidos son home_cubit.dart:32,37,52,63 y home_scaffold.dart:54 | Baja | Medio | Pre-flight en Fase 5: `grep -rn 'mainVehicle\|HomeLoaded' lib/` para confirmar que no hay otros consumidores antes de modificar. |
| R-8 | **`VehicleActionCubit` scope incorrecto:** si se instancia como singleton en lugar de scoped al bottom-sheet, el estado de loading persiste entre sesiones | Baja | Bajo | `@injectable` (no `@singleton`); provisionar en el árbol de widgets del bottom-sheet, no en `main.dart`. |
| R-9 | **Clave `vehicle_unarchiveVehicle` actualizada rompe otros usos:** si la clave ya se usa en otro contexto con el label "Desarchivar", cambiarla a "Restaurar" introduce regresión | Baja | Bajo | Pre-flight en Fase 3: `grep -rn 'vehicle_unarchiveVehicle' lib/` para mapear todos los puntos de uso antes de cambiar el valor en el ARB. |

## Como ejecutar una fase

> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del título y la sección "Ejecución recomendada" de cada fase):

```
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/archive-vehicle-soft-delete/phases/phase-01-backend-soft-delete-e-integridad-de-datos.md', mode: 'full' } })
```

Reemplaza la ruta y el modo según la fase a ejecutar:

| Fase | Archivo | Modo |
|------|---------|------|
| 1 | `phases/phase-01-backend-soft-delete-e-integridad-de-datos.md` | `full` |
| 2 | `phases/phase-02-diseno-pencil-garaje-con-seccion-de-archivados.md` | `lite` |
| 3 | `phases/phase-03-flutter-archivar-y-restaurar-vehiculos.md` | `normal` |
| 4 | `phases/phase-04-flutter-eliminacion-permanente-desde-archivados.md` | `normal` |
| 5 | `phases/phase-05-flutter-vehiculo-principal-siempre-coherente.md` | `lite` |

> `lite` = mecánico/bajo riesgo; `normal` = feature acotada; `full` = complejo/riesgoso (contratos, migraciones, seguridad).
