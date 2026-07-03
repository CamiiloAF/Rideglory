> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend

**Stand-down casi total: el 95% del PRD ya está implementado.** No reimplementes
`isOrganizerView`, `RegistrationContactActions`, ni los 3 call-sites de
navegación organizador (`attendees_list.dart`, `event_detail_participants_section.dart`,
`event_detail_view.dart`) — verifica que existen (ya están) y sigue.

## Único trabajo real: cerrar AC10 (bloodType nullable)

Fase 3 (prerrequisito) NO entregó `bloodTypeRaw` a pesar de que el PRD lo asume.
`registration_detail_page.dart` hoy hace:

```dart
value: registration.bloodType?.label ?? context.l10n.registration_maskedValue,
```

Debe quedar (AC10 exacto):

```dart
value: registration.bloodType?.label ?? registration.bloodTypeRaw ?? context.l10n.notAvailable,
```

### Pasos en orden

1. **`lib/features/event_registration/domain/model/event_registration_model.dart`**
   Agregar `final String? bloodTypeRaw;` — campo opcional, default `null`, en
   constructor y `copyWith`.
2. **`lib/features/event_registration/data/dto/event_registration_dto.dart`**
   `EventRegistrationDto.fromJson` custom: capturar `json['bloodType'] as String?`
   ANTES/DESPUÉS del converter y poblar `bloodTypeRaw` solo cuando
   `_BloodTypeConverter` no logró mapear a un `BloodType` (es decir,
   `dto.bloodType == null` pero el JSON traía un string no vacío). No serializar
   `bloodTypeRaw` de vuelta en `toJson()` (es campo de solo-lectura, derivado de
   la respuesta del backend — nunca viaja en payloads de escritura).
3. `dart run build_runner build --delete-conflicting-outputs` — regenera
   `event_registration_dto.g.dart`. NO editar el `.g.dart` a mano.
4. **`lib/features/event_registration/presentation/registration_detail_page.dart`**
   línea ~127: aplicar el fallback de 2 pasos de arriba.
5. Actualizar `test/features/event_registration/presentation/registration_detail_page_test.dart`:
   agregar caso `bloodType=null` + `bloodTypeRaw` con valor → renderiza el
   string crudo; caso `bloodType=null` + `bloodTypeRaw=null` → renderiza "N/A".

### No tocar

- `RegistrationDetailExtra`, `RegistrationDetailBottomBar`,
  `RegistrationContactActions` — ya correctos, con tests existentes que pasan.
- `my_registrations_data_view.dart` — vista piloto, no pasa `isOrganizerView`, no tocar.
- l10n: no agregar claves nuevas (AC10 lo prohíbe explícitamente). La clave
  `registration_maskedValue` queda sin uso — opcional eliminarla, no obligatorio.
- `dart analyze` limpio en todos los archivos tocados.

> Full detail: handoffs/architect.md
