# Auditoría — agente "design" — flutter-permanent-delete-vehicle

_Auditor: Opus_
_Fecha: 2026-06-17T17:15:14Z_
_Resultado: APROBADO (score 88)_

## Alcance auditado

El agente "design" en esta fase entregó:
1. Actualización del frame `EM0D6` en `rideglory.pen` (añadir fila "Eliminar permanentemente").
2. Handoff `docs/exec-runs/flutter-permanent-delete-vehicle/handoffs/design.md` con flujos UX, estados, copy y specs visuales.
3. Screenshots de referencia en `analysis/design/` (EM0D6, SqWs1, x7j5iJ, HpUYE, fOIJD, gnCZx) — todos presentes.

La fase es mayormente cleanup de código; el handoff de diseño cubre correctamente todos los estados UX (idle/loading/success/error de cada pantalla).

## Verificaciones

- AC#1 visibilidad contextual: menú archivado muestra Restaurar + Eliminar permanentemente; form sin botón eliminar. OK.
- AC#2 diálogo destructivo: `confirmType: DialogActionType.danger`, título/mensaje/CTA via l10n. OK.
- AC#3 confirmación/cancelar: TC-perm-C verde. OK.
- AC#4 guard anti doble-tap: `if (state is _Loading) return;` + TC-perm-B verde (use case 1 vez). OK.
- AC#5 re-fetch: `await _vehicleCubit.fetchMyVehicles()` en éxito. OK.
- AC#6/#7 snackbars success/error: branch `permanentDeleteSuccess` con AppColors.success; error con AppColors.error. OK.
- AC#8 contrato Retrofit: `@DELETE('${ApiRoutes.myVehicles}/{id}')`; cero refs a `hard-delete`. OK.
- AC#9 renombrado: cero refs a `deleteVehicle`/`DeleteVehicleUseCase` en código compilable (solo claves l10n huérfanas generadas, documentadas en PRD §3 como "no entra"). `dart analyze` sin errores (2 infos pre-existentes en test). OK.
- AC#11 strings l10n: todas via context.l10n. OK.
- AC#12 form limpio: sin BlocProvider<VehicleActionCubit>, sin onDelete. OK.
- Clean Architecture: dominio sin Flutter; data sin BuildContext; presentación sin HTTP/DTO. OK.
- Design system: GarageOptionRow con iconColor AppColors.error; AppButton en form; texto blanco sobre rojo error (correcto, no es el acento naranja). OK.

## Hallazgos menores (no bloqueantes)

1. **Drift de copy handoff vs implementación.** La tabla de copy del handoff dice título "Eliminar permanentemente" y mensaje "...todo su historial de mantenimientos...". El `app_es.arb` final usa título "Eliminar vehículo permanentemente" y mensaje "¿Estás seguro...«{vehicleName}»...\n\nEsta acción no se puede deshacer." Ambas versiones son español válido y consistente; los tests asertan las strings reales. Recomendado alinear el handoff con el arb en una pasada futura.

2. **Test pre-existente roto (fuera de alcance de esta fase).** `test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` TC-bs-1/TC-bs-2 fallan porque buscan `find.byType(ListTile)` + `Icons.archive`, pero `GarageOptionsBottomSheet` ya usaba `GarageOptionRow` + `LucideIcons.archive` desde HEAD (confirmado con `git show HEAD`). El cuerpo del test no se tocó en esta fase (solo el rename del Mock). Es deuda de la Fase 3, no regresión de design. Debe arreglarse por el agente frontend, no afecta la aprobación de design.

3. **Desviación vs recomendación del handoff del Architect.** El handoff sugería eliminar `VehicleDeleteCubit` entero; el implementador lo migró a `permanentlyDeleteVehicle` en lugar de borrarlo. `VehicleDeleteCubit` sigue registrado en DI sin consumidores UI. No rompe nada; es código sin callers que podría limpiarse después.

## Conclusión

El handoff de design es sólido y fiel a la implementación. Los 3 widget tests nuevos (TC-perm-A/B/C) pasan en verde y fallarían sin el cambio (verifican guard, diálogo con nombre y cancelar). Aprobado.
