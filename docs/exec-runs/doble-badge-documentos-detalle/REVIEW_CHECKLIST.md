# REVIEW CHECKLIST — doble-badge-documentos-detalle

**Fecha:** 2026-06-04T21:42:05Z

Pasos manuales antes de commitear.

---

## Automatizados (ya ejecutados por QA — no repetir salvo duda)

- [ ] `dart analyze lib/` → "No issues found!"
- [ ] `flutter test test/features/vehicles/presentation/` → 23/23 nuevos passing
- [ ] `grep -n "features/soat\|features/tecnomecanica" lib/features/vehicles/presentation/detail/vehicle_detail_page.dart lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` → cero matches
- [ ] `grep -rln "VehicleSoatCard\|VehicleSoatSection" lib/` → vacío

---

## Manuales en simulador/dispositivo

1. **Dos tarjetas visibles.** Garaje → vehículo → detalle: aparecen "DOCUMENTOS" (SOAT) y "TÉCNICO-MECÁNICA" (RTM) con el mismo espaciado de 16 px entre cards.
2. **Estados SOAT sin cambio.** El badge SOAT muestra el estado correcto (`valid`, `expiringSoon`, `expired`, vacío) con los mismos colores y labels que antes de la fase.
3. **RTM sin registro.** Badge gris con texto "Sin RTM registrada" y chevron.
4. **RTM vigente.** Badge verde con "Vigente" + fecha de vencimiento.
5. **RTM por vencer.** Badge naranja con "Por vencer" + fecha.
6. **RTM vencida.** Badge rojo con "Vencida" + fecha.
7. **Tap RTM** → navega a `tecnomecanicaStatus`. Al regresar, el cubit recarga.
8. **Tap SOAT con documento** → navega a `soatStatus`.
9. **Tap SOAT sin documento** → lanza `SoatEntryFlow` (bottom sheet de captura).
10. **Carga independiente.** Al abrir el detalle, cada badge muestra su propio skeleton brevemente antes de resolver. Resolver uno no dispara reflow en el otro.
11. **Odómetro intacto.** Crear un mantenimiento y regresar: el `currentMileage` en el header del detalle se actualiza.
12. **Sin rastro del botón test.** El `OutlinedButton.icon 'Tecnomecánica [TEST]'` ya no aparece en ningún build actualizado.
