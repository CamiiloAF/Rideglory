# Design handoff — home-garage-vehicle-cubit-coherence

**Date:** 2026-06-17T21:51:33Z
**Status:** done

---

## Clasificación de la fase

Esta fase es un **refactor de coherencia de estado** en la capa de presentación, no una adición de UI. El PRD lo confirma explícitamente: _"Nivel lite: sin diseño en Pencil (no hay nueva UI diseñable)."_ No se crean pantallas nuevas, no se modifican flujos de usuario, y no hay cambios visibles para el rider una vez que `VehicleCubit` haya resuelto su estado `Data`.

No se realiza trabajo en Pencil ni se exportan capturas, conforme a las instrucciones del PRD.

---

## Pantallas

| Pantalla | Story | Tipo | Frame Pencil | Cambio visible |
|----------|-------|------|--------------|----------------|
| Home Dashboard — Sección Garaje | PRD §3 | UPDATE | `dyWWs` (sin cambio en Pencil) | Solo en estados transitorios `Initial`/`Loading`; el estado final `Data` es visualmente idéntico al estado actual |

**No se requiere actualización del frame `dyWWs` en Pencil.** El aspecto visual final de la sección garaje (con o sin vehículo principal) no cambia. El único delta es el placeholder temporal que el rider ve durante ≤ 1–2 s mientras `VehicleCubit` resuelve.

---

## Flujos UX

### Flujo anterior (con bug de coherencia)

```
HomeCubit emite HomeLoaded(upcomingEvents, mainVehicle)
    └─► HomeGarageSection(vehicle: state.mainVehicle)
            ├─ VehicleCubit.Data → muestra vehículo de VehicleCubit
            └─ VehicleCubit.Initial / Loading / Error → fallback a state.mainVehicle (stale)
```

**Problema:** cuando el rider archiva/restaura/cambia el vehículo principal, `HomeCubit` no se entera → la sección muestra datos stale hasta el próximo `loadHomeData()`.

### Flujo corregido (esta fase)

```
HomeCubit emite HomeLoaded(upcomingEvents)   ← mainVehicle eliminado
    └─► const HomeGarageSection()
            ├─ VehicleCubit.Initial  → Placeholder 200 px (SizedBox + darkCard)
            ├─ VehicleCubit.Loading  → Placeholder 200 px (SizedBox + darkCard)
            ├─ VehicleCubit.Data([]) → HomeEmptyGarageCard
            ├─ VehicleCubit.Data([...]) → HomeGarageCard(vehicle: mainVehicle ?? first)
            ├─ VehicleCubit.Empty    → HomeEmptyGarageCard
            └─ VehicleCubit.Error    → HomeEmptyGarageCard  (tratamiento conservador)
```

**Resultado:** cualquier cambio en `VehicleCubit` (archivado, restauración, cambio de principal) se refleja inmediatamente en `HomeGarageSection` sin HTTP adicional.

---

## Componentes

| Componente | Estado | Acción requerida |
|------------|--------|-----------------|
| `HomeGarageSection` | EXISTS — modificar | Eliminar prop `vehicle`; añadir ramas `Initial`/`Loading` |
| `HomeGarageCard` | EXISTS — sin cambio | Se sigue usando en `VehicleCubit.Data` con vehículo |
| `HomeEmptyGarageCard` | EXISTS — sin cambio | Se sigue usando en `Data([])`, `Empty` |
| `HomeSectionHeader` | EXISTS — sin cambio | Intacto |
| Placeholder 200 px | NEW (inline en `HomeGarageSection`) | `Container(height: 200, decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(16)))` — sin widgets nuevos, sin texto |

**No se necesitan componentes nuevos en `lib/shared/widgets/` ni en el design system.** El placeholder es un `Container` estático de una línea dentro de `HomeGarageSection`.

### Altura del placeholder

`HomeGarageCard` tiene estructura:
- `HomeGarageHeroImage`: 180 px fijos
- `HomeGarageVehicleInfo`: ~60–80 px estimados (padding + texto + specs)
- Total aproximado: 240–260 px

El placeholder de **200 px** es conservativo pero suficiente para anclar el scroll y evitar el layout jump hasta que `VehicleCubit` resuelva. No es necesario que sea exacto — el objetivo es que el scroll de `HomeScaffold` no salte.

---

## Copy

No se agrega copy nuevo. El placeholder no lleva texto (decisión del Architect, handoff §Decisión 4). No se requieren cambios en `app_es.arb`.

| Key l10n | Texto | Estado |
|----------|-------|--------|
| `home_sectionGarage` | "Mi garaje" (existente) | Sin cambio |
| `home_viewAllLink` | "Ver todo" (existente) | Sin cambio |

---

## Accesibilidad

| Aspecto | Evaluación |
|---------|-----------|
| Touch targets | `HomeGarageCard` ya cumple ≥ 44 px. El placeholder no es interactivo → sin requisito. |
| Contraste | Placeholder usa `AppColors.darkCard` sobre `AppColors.darkBackground` — relación de contraste ≥ 3:1 (superficie sobre fondo), dentro de los niveles aceptables para elementos decorativos no textuales. |
| Semántica | El placeholder no necesita `Semantics` label porque no transmite información; su ausencia de contenido es el estado correcto. |
| Animación | No hay animaciones nuevas. El salto visual de placeholder → card es instantáneo cuando `VehicleCubit` emite `Data` — conforme al PRD que descarta skeleton animado. |
| Screen readers | Los estados `Initial`/`Loading` serán silenciosos para TalkBack/VoiceOver, lo cual es correcto: no hay contenido que anunciar aún. |

---

## Notas para Frontend

1. **Placeholder exact spec:**
   ```dart
   Container(
     height: 200,
     decoration: BoxDecoration(
       color: AppColors.darkCard,
       borderRadius: BorderRadius.circular(16),
     ),
   )
   ```
   Usar el mismo `borderRadius: BorderRadius.circular(16)` que `HomeGarageCard` para consistencia visual.

2. **Rama `Error` de `VehicleCubit`:** el PRD no especifica explícitamente este estado, pero el comportamiento conservador es mostrar `HomeEmptyGarageCard` (igual que `Empty`). No mostrar un error en esta sección ya que el error se maneja en el flujo del garaje propiamente, no en home.

3. **`const` constructor:** el constructor pasa a `const HomeGarageSection({super.key})`. Esto es posible porque el widget no tiene props y `build()` solo accede a `context` — `const` es válido.

4. **No Pencil exports:** esta fase no produce capturas de diseño. El directorio `docs/exec-runs/home-garage-vehicle-cubit-coherence/analysis/design/` existe pero queda vacío intencionalmente.

5. **Orden de implementación (confirmar con architect.md):**
   1. `home_state.dart` → eliminar campo + import
   2. `home_cubit.dart` → eliminar 3 referencias + import
   3. `home_scaffold.dart` → `const HomeGarageSection()`
   4. `home_garage_section.dart` → eliminar prop; añadir placeholder
   5. `dart analyze lib/features/home/` → verde
   6. Actualizar `home_cubit_test.dart` TC-home-2
   7. Crear `home_garage_section_test.dart` con 6 tests
   8. `flutter test test/features/home/` → verde

---

## Change log

- 2026-06-17T21:51:33Z: Handoff creado. Sin cambios en Pencil (fase lite, refactor puro de estado). Placeholder 200 px especificado. Sin copy nuevo.
