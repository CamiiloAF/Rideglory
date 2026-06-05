# REVIEW CHECKLIST — rtm-crud-flutter

**Generado:** 2026-06-04T19:41:01Z (revisión 2 — BUG-01 resuelto)

Pasos manuales a completar **antes de commitear**.

---

## Obligatorio (blocker)

~~FIX-01 — `BlocProvider.value(value: getIt<>())` en `TecnomecanicaManualCapturePage`~~ **RESUELTO** por Frontend. El archivo ya usa `BlocProvider(create: (_) => getIt<TecnomecanicaCubit>())`. Verificar:

```bash
grep -n "BlocProvider.value" lib/features/tecnomecanica/
# Esperado: sin resultados
```

Sin blockers abiertos.

---

## Recomendado (no bloquea)

### FIX-02 — Copy incorrecto en `_RtmDocumentCardBody`

**Archivo:** `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` línea 272.

**Problema:** Usa `context.l10n.vehicle_soat_tap_to_add` ("Sin registrar · Agregar →") en el card RTM. La clave es semánticamente SOAT.

**Fix:** Añadir clave `tecnomecanica_tap_to_add: "Sin RTM · Agregar →"` en `app_es.arb` (y regenerar l10n) y usar esa clave en `_RtmDocumentCardBody`.

O bien usar la clave ya existente `tecnomecanica_status_no_rtm` si el copy es aceptable ("Sin RTM registrada"), aunque es más largo para un card compacto.

---

## Verificación manual (post-fix)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| M-1 | VehicleDetail → tile RTM (sin RTM previa) → StatusPage | EmptyState + ExemptionNotice si <2 años; botón "Registrar RTM" |
| M-2 | EmptyState → "Registrar RTM" → ManualCapturePage | Formulario vacío; campos habilitados |
| M-3 | Completar campos → "Guardar datos" | StatusPage recarga; hero card verde/naranja/rojo según fecha |
| M-4 | StatusPage Data → AppBar "Editar" | ManualCapturePage con campos precargados |
| M-5 | Editar campo → "Guardar datos" | StatusPage muestra valores actualizados |
| M-6 | StatusPage Data → "Eliminar RTM" → ConfirmationDialog → confirmar | SnackBar "RTM eliminada"; StatusPage vuelve a EmptyState |
| M-7 | Vehículo con purchaseDate < 2 años en EmptyState | ExemptionNotice naranja visible; botón "Guardar datos" habilitado |
| M-8 | Error de red en cualquier operación | Estado Error con mensaje y botón "Reintentar" |
| M-9 | Garage → VehicleDocumentCard kind:rtm | Card RTM visible; toca → navega a StatusPage (no SOAT) |

---

## Verificaciones estáticas (post-fix)

```bash
dart analyze lib/
# Esperado: No issues found

flutter test test/features/tecnomecanica/
# Esperado: 30 passed, 0 failed

flutter test
# Esperado: 686+ passed, 0 failed

grep -rn "BlocProvider.value" lib/features/tecnomecanica/
# Esperado: sin resultados (confirma FIX-01 aplicado)
```
