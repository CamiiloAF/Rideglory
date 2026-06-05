# Frontend → QA: doble-badge-documentos-detalle

**Fecha:** 2026-06-04T21:12:08Z

---

## Baseline

- `flutter test` antes de cambios: **472 passing, 3 failing** (3 fallos pre-existentes en `test/features/tecnomecanica/` por `startDate` faltante en fixtures — no relacionados con este cambio).
- `dart analyze lib/`: sin problemas.

---

## Archivos cambiados

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `lib/l10n/app_es.arb` | modificado | Añadidas 3 claves RTM badge: `vehicle_doc_rtm_status_valid`, `vehicle_doc_rtm_status_expiring_soon`, `vehicle_doc_rtm_status_expired` |
| `lib/l10n/app_localizations.dart` | regenerado | `flutter gen-l10n` — nuevas claves RTM incluidas |
| `lib/l10n/app_localizations_es.dart` | regenerado | `flutter gen-l10n` — traducciones ES para las 3 claves RTM |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` | modificado | `_RtmDocumentCardBody` completado: `BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>` con 4 estados (loading skeleton, empty, data con color/label según `documentStatus`, error fallback). Añadidos imports `TecnomecanicaModel` y `VehicleDocumentStatus`. |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | modificado | Eliminado import `TecnomecanicaEntryFlow` (gate A11). Reemplazado `OutlinedButton.icon` placeholder por `VehicleDocumentCard(kind: VehicleDocumentKind.rtm, vehicle: vehicle)`. |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart` | eliminado | Widget huérfano `VehicleSoatSection` sin consumidores en `lib/` (confirmado con grep). Importaba `features/soat/` sin necesidad. |
| `test/features/vehicles/presentation/vehicle_documents_badges_test.dart` | creado | 17 widget tests nuevos (ver sección Pruebas nuevas). |

---

## Pruebas nuevas

Archivo: `test/features/vehicles/presentation/vehicle_documents_badges_test.dart`

**Estrategia:** Los cubits se registran en `GetIt` como mocks en `setUp` para que el `BlocProvider.create` interno de `VehicleDocumentCard` resuelva al mock. Se desregistran en `tearDown`. Sin DI real ni Firebase.

| # | Grupo | Caso |
|---|-------|------|
| 1 | Criterio 3 — ambos badges renderizan | SOAT card y RTM card se muestran sin excepción fatal |
| 2 | Criterio 4 — carga independiente | SOAT en loading → skeleton; RTM con datos → label visible simultáneamente |
| 3 | Criterio 4 — carga independiente | RTM en loading → skeleton; SOAT con datos → label visible simultáneamente |
| 4 | Criterio 5 — SOAT 4 estados | loading → `CircularProgressIndicator` |
| 5 | Criterio 5 — SOAT 4 estados | empty → label sin-registro |
| 6 | Criterio 5 — SOAT 4 estados | data valid → "Vigente" |
| 7 | Criterio 5 — SOAT 4 estados | data expiringSoon → "Por vencer" |
| 8 | Criterio 5 — SOAT 4 estados | data expired → "vencido" |
| 9 | RTM 4 estados | loading → `CircularProgressIndicator` |
| 10 | RTM 4 estados | empty → "Sin RTM registrada" |
| 11 | RTM 4 estados | data valid → "Vigente" |
| 12 | RTM 4 estados | data expiringSoon → "Por vencer" |
| 13 | RTM 4 estados | data expired → "Vencida" |
| 14 | RTM 4 estados | error → "Sin RTM registrada" (fallback igual que empty) |
| 15 | Criterio 6 — tap por kind | SOAT card con datos tiene `InkWell` |
| 16 | Criterio 6 — tap por kind | RTM card con datos tiene `InkWell` |
| 17 | Criterio 6 — tap por kind | SOAT empty tiene `InkWell` (permite navegar a añadir) |

---

## Resultado final

- `flutter test test/features/vehicles/presentation/vehicle_documents_badges_test.dart`: **17/17 passing**
- `flutter test` (suite completa): **673 passing, 3 failing** (los mismos 3 pre-existentes de tecnomecanica DTO/model/cubit)
- `dart analyze lib/`: **No issues found!**
- Gate A11: `grep -n "features/soat\|features/tecnomecanica" vehicle_detail_view.dart vehicle_detail_page.dart` → **cero matches** ✓

---

## Verificación manual

Para verificar en el simulador/dispositivo:

1. Abrir garaje → tocar cualquier vehículo → ver detalle.
2. Verificar que aparecen DOS tarjetas: "DOCUMENTOS" (SOAT) y "TÉCNICO-MECÁNICA" (RTM).
3. **Sin RTM registrada:** badge gris con texto "Sin RTM registrada".
4. **Con RTM vigente:** badge verde con "Vigente" + fecha de vencimiento.
5. **Con RTM por vencer (≤30 días):** badge naranja con "Por vencer" + fecha.
6. **Con RTM vencida:** badge rojo con "Vencida" + fecha.
7. Tocar la tarjeta RTM → navega a `tecnomecanicaStatus`. Al volver, el cubit recarga.
8. El SOAT y RTM cargan de forma independiente: cada uno muestra su propio skeleton.

---

## Notas para QA

- El `OutlinedButton.icon 'Tecnomecánica [TEST]'` ya no existe — cualquier build que lo muestre es antiguo.
- `VehicleSoatSection` fue eliminado — no debería aparecer en ningún árbol de widgets.
- Las 3 claves l10n nuevas (`vehicle_doc_rtm_status_*`) solo se usan en el badge compacto; las claves `tecnomecanica_valid_title` etc. siguen usándose en la página de estado full.
- El estado `error` del RTM renderiza el mismo texto que `empty` ("Sin RTM registrada") — es intencional como fallback defensivo.
- Los 3 fallos pre-existentes en `test/features/tecnomecanica/` (falta `startDate` en fixtures) son deuda anterior, no introducida por este cambio.
