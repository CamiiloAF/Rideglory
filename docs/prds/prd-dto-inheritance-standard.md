# PRD — Estandarizar el patrón DTO: herencia del modelo de dominio

**Tipo:** Refactor técnico (cero cambios de comportamiento)  
**Prioridad:** Media (deuda técnica)  
**Estimado:** 1 iteración de desarrollo  
**Fecha de creación:** 2026-05-26  

---

## 1. Problema

El codebase tiene dos patrones coexistentes para los DTOs, lo que genera confusión sobre cuál usar al crear nuevos features.

### Patrón A — Clase separada (patrón antiguo, inconsistente)

```dart
// ❌ Patrón A — DtoDto es una clase independiente del modelo
class MaintenanceDto {
  final String? id;
  final MaintenanceType type;  // campo duplicado del modelo
  // ... todos los campos duplicados ...

  MaintenanceModel toModel() => MaintenanceModel(id: id, type: type, ...);
  factory MaintenanceDto.fromModel(MaintenanceModel m) => MaintenanceDto(id: m.id, ...);
  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);
}
```

**Problemas:**
- **Todos los campos del modelo se declaran dos veces** (en el modelo y en el DTO).
- `toModel()` y `fromModel()` son boilerplate que hay que mantener en sync con el modelo.
- En el repositorio se debe castear: `dto.toModel()` — capa extra de conversión.
- Un campo nuevo en el modelo requiere cambios en 3 lugares: modelo, DTO, `toModel()`.

### Patrón B — Herencia del modelo (patrón nuevo, canónico)

```dart
// ✅ Patrón B — Dto hereda del modelo; el DTO IS el modelo
class EventDto extends EventModel {
  const EventDto({required super.id, required super.name, ...});

  factory EventDto.fromJson(Map<String, dynamic> json) => _$EventDtoFromJson(json);
  Map<String, dynamic> toJson() { /* generado + ajustes de fechas */ }
}

// Extension para serializar cualquier instancia del modelo sin castear
extension EventModelExtension on EventModel {
  Map<String, dynamic> toJson() => EventDto(id: id, name: name, ...).toJson();
}
```

**Ventajas:**
- **Cero duplicación de campos** — el DTO reutiliza los del modelo via `super`.
- **No hay `toModel()`** — el DTO ya es un `EventModel`, se usa directamente.
- En el repositorio, el resultado del `fromJson` se puede devolver como `EventModel` sin conversión.
- Un campo nuevo en el modelo se refleja automáticamente en el DTO (solo hay que añadirlo al constructor del DTO).
- `HomeDto` ya consume `EventDto` directamente como `List<EventModel>` gracias a la herencia.

---

## 2. Objetivo

**Adoptar el Patrón B como el único patrón válido** para todos los DTOs que tienen un modelo de dominio 1:1 correspondiente. Eliminar `toModel()`, `fromModel()`, y extensiones `toDto()` como consecuencia.

El resultado debe ser que cualquier desarrollador nuevo, al crear un DTO, tenga un único patrón a seguir sin ambigüedad.

---

## 3. Reglas del estándar (no negociables)

### Regla 1 — El DTO hereda del modelo

```dart
// lib/features/<feature>/data/dto/<name>_dto.dart
@JsonSerializable(explicitToJson: true, converters: [...])
class XDto extends XModel {
  const XDto({
    required super.fieldA,
    @JsonKey(name: 'api_name') super.fieldB,
    ...
  });

  factory XDto.fromJson(Map<String, dynamic> json) => _$XDtoFromJson(json);

  // Solo sobreescribir toJson() si hay ajuste de fechas u otra lógica de serialización
  Map<String, dynamic> toJson() => _$XDtoToJson(this);
}
```

### Regla 2 — Extension `toJson()` en el modelo

```dart
extension XModelExtension on XModel {
  Map<String, dynamic> toJson() => XDto(
    fieldA: fieldA,
    fieldB: fieldB,
    ...
  ).toJson();
}
```

Esta extension permite que el repositorio escriba `model.toJson()` sin saber que existe el DTO.

### Regla 3 — No `toModel()`, no `fromModel()`, no `toDto()`

Estos métodos son redundantes cuando el DTO hereda del modelo:

```dart
// ❌ Prohibido
EventDto dto = ...;
EventModel model = dto.toModel(); // innecesario — dto ya ES un EventModel

// ✅ Correcto
EventDto dto = ...;
EventModel model = dto; // cast implícito por herencia
```

### Regla 4 — Los repositorios retornan `List<XModel>` / `XModel` directamente

```dart
// ❌ Patrón viejo
return executeService(() async {
  final dtos = await _service.getItems();
  return dtos.map((dto) => dto.toModel()).toList(); // conversión innecesaria
});

// ✅ Patrón nuevo
return executeService(() async {
  return _service.getItems(); // List<XDto> es assignable a List<XModel>
});
```

### Regla 5 — `@JsonKey` para diferencias de nombre entre API y modelo

```dart
class XDto extends XModel {
  const XDto({
    @JsonKey(name: 'createdAt') super.createdDate,   // API manda "createdAt", modelo tiene "createdDate"
    @JsonKey(name: 'updatedAt') super.updatedDate,
  });
}
```

---

## 4. Cuándo NO aplicar este patrón

El Patrón B aplica **solo** cuando hay una relación 1:1 entre un DTO y un modelo de dominio.  
Los siguientes casos quedan **excluidos del estándar** y deben mantenerse como clases independientes:

| Caso | Ejemplo | Razón |
|---|---|---|
| DTO de respuesta compuesta | `HomeDto`, `CreateMaintenanceResponseDto`, `VehicleMaintenancesListResponseDto` | Agregan múltiples modelos; no tienen un modelo de dominio único |
| DTO de request sin modelo dominio | `CreateUserDto` | Solo envía datos al servidor, no representa un modelo de la app |
| Sub-DTO auxiliar embebido | `MaintenanceListSummaryDto` | Nunca circula solo como modelo de dominio |
| DTO con lógica de negocio en `toModel()` | `NotificationDto` | `toModel()` parsea el tipo de notificación y construye título/body — esta lógica no pertenece al DTO bajo el nuevo patrón |
| DTO de API externa / servicio | `GeocodeResultDto`, `PlaceSuggestionDto` | No tienen modelo de dominio en la app; mapean directamente a `AddressLocation` |

> **Nota sobre `NotificationDto`:** cuando se migre este feature, la lógica de `toModel()` debe extraerse a un mapper o método en el propio `NotificationModel`. El DTO seguirá siendo clase separada.

---

## 5. Inventario de cambios

### 5.1 DTOs que ya aplican el patrón correctamente ✅

Estos archivos son la referencia. **No tocar.**

| DTO | Modelo | Notas |
|---|---|---|
| `EventDto extends EventModel` | `event_model.dart` | Patrón canónico de referencia |
| `RiderTrackingDto extends RiderTrackingModel` | `rider_tracking_model.dart` | Incluye `_normalizeTrackingJson()` para sanitizar campos nulos del WS |
| `RiderProfileDto extends RiderProfileModel` | `rider_profile_model.dart` | |

---

### 5.2 DTOs que aplican herencia pero tienen ruido extra — limpieza menor

#### `VehicleDto` (`lib/features/vehicles/data/dto/vehicle_dto.dart`)

**Problema actual:** tiene `toModel()` manual aunque ya hereda de `VehicleModel` (el método es redundante y potencialmente confuso).

**Cambio:** eliminar `toModel()`.

```dart
// ❌ Eliminar
VehicleModel toModel() {
  return VehicleModel(id: id, name: name, ...); // innecesario
}

// ✅ Repositorios que llamaban toModel() pasan a usar el dto directamente
```

Verificar usos en:
- `lib/features/vehicles/data/repository/vehicle_repository_impl.dart`
- `lib/features/home/data/dto/home_dto.dart` → `mainVehicle?.toModel()` → `mainVehicle` (ya es `VehicleModel`)

---

#### `UserDto` (`lib/features/users/data/dto/user_dto.dart`)

**Problema actual:** tiene `factory UserDto.fromModel(UserModel model)` en vez de una extension `toJson()`. Esto expone el DTO en capa de presentación (quienes necesitan serializar un `UserModel` deben saber que existe `UserDto`).

**Cambio:** eliminar `fromModel()` y agregar extension.

```dart
// ❌ Eliminar
factory UserDto.fromModel(UserModel model) => UserDto(
  id: model.id, fullName: model.fullName, ...
);

// ✅ Agregar al final del archivo
extension UserModelExtension on UserModel {
  Map<String, dynamic> toJson() => UserDto(
    id: id, fullName: fullName, email: email, ...
  ).toJson();
}
```

Verificar usos de `UserDto.fromModel()` en:
- `lib/features/users/data/repository/user_repository_impl.dart`

---

### 5.3 DTOs a migrar completamente — refactor mayor

#### `MaintenanceDto` (`lib/features/maintenance/data/dto/maintenance_dto.dart`)

**Estado actual:** clase separada con `fromModel()` factory y `toModel()`. Los campos de modelo se declaran dos veces. El repositorio hace `.map((dto) => dto.toModel()).toList()`.

**Modelo de dominio:** `MaintenanceModel` (`lib/features/maintenance/domain/model/maintenance_model.dart`)

> Verificar antes: `MaintenanceModel` debe ser clase Dart pura (no freezed) para soportar herencia. Si es freezed, ver §6.

**Diferencias API → modelo a mapear con `@JsonKey`:**

| Campo en API | Campo en modelo |
|---|---|
| `createdAt` | `createdDate` |
| `updatedAt` | `updatedDate` |

**Resultado esperado:**

```dart
@JsonSerializable(converters: apiJsonDateTimeConverters, includeIfNull: false)
class MaintenanceDto extends MaintenanceModel {
  const MaintenanceDto({
    super.id,
    super.userId,
    super.vehicleId,
    required super.type,
    required super.mode,
    super.serviceDate,
    super.odometerAtService,
    super.workshop,
    super.notes,
    super.nextDate,
    super.nextOdometer,
    super.cost,
    @JsonKey(name: 'createdAt') super.createdDate,
    @JsonKey(name: 'updatedAt') super.updatedDate,
  });

  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceDtoToJson(this);
}

extension MaintenanceModelExtension on MaintenanceModel {
  Map<String, dynamic> toJson() => MaintenanceDto(
    id: id, userId: userId, vehicleId: vehicleId,
    type: type, mode: mode,
    serviceDate: serviceDate, odometerAtService: odometerAtService,
    workshop: workshop, notes: notes,
    nextDate: nextDate, nextOdometer: nextOdometer, cost: cost,
    createdDate: createdDate, updatedDate: updatedDate,
  ).toJson();
}
```

**Archivos afectados:**
- `lib/features/maintenance/data/repository/maintenance_repository_impl.dart` — quitar `.map((dto) => dto.toModel()).toList()`
- `lib/features/maintenance/data/dto/create_maintenance_response_dto.dart` — `toModels()` pasa a cast directo: `List<MaintenanceModel>.from(created)`
- `lib/features/maintenance/data/dto/vehicle_maintenances_list_response_dto.dart` — si usa `MaintenanceDto` como campo, sin cambios en el DTO wrapper

---

#### `EventRegistrationDto` (`lib/features/event_registration/data/dto/event_registration_dto.dart`)

**Estado actual:** clase separada con `toModel()` y extension `EventRegistrationModelToDto.toDto()`. El repositorio hace `.toModel()` al deserializar y `.toDto().toJson()` al serializar.

**Modelo de dominio:** `EventRegistrationModel`

**Particularidad:** `toJson()` sobreescribe `birthDate` con `apiEncodeRequiredDateTime` — este override debe mantenerse.

**Sub-DTO embebido:** `VehicleSummaryDto` se usa como campo. Ver su propio ítem abajo.

**Diferencias API → modelo:**

| Campo en API | Campo en modelo |
|---|---|
| `createdAt` | `createdAt` (mismo) |
| `updatedAt` | `updatedAt` (mismo) |
| _(ninguna diferencia de nombre)_ | |

**Resultado esperado:**

```dart
@JsonSerializable(converters: apiJsonDateTimeConverters)
class EventRegistrationDto extends EventRegistrationModel {
  const EventRegistrationDto({
    super.id,
    required super.eventId,
    @JsonKey(defaultValue: '') super.eventName = '',
    required super.userId,
    super.status = RegistrationStatus.pending,
    required super.fullName,
    required super.identificationNumber,
    required super.birthDate,
    required super.phone,
    required super.email,
    required super.residenceCity,
    required super.eps,
    super.medicalInsurance,
    required super.bloodType,
    required super.emergencyContactName,
    required super.emergencyContactPhone,
    super.vehicleId,
    super.vehicleSummary,   // tipo VehicleSummaryModel; ver §5.3 VehicleSummaryDto
    super.createdAt,
    super.updatedAt,
  });

  factory EventRegistrationDto.fromJson(Map<String, dynamic> json) =>
      _$EventRegistrationDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final json = _$EventRegistrationDtoToJson(this);
    json['birthDate'] = apiEncodeRequiredDateTime(birthDate); // override obligatorio
    return json;
  }
}

extension EventRegistrationModelExtension on EventRegistrationModel {
  Map<String, dynamic> toJson() => EventRegistrationDto(
    id: id, eventId: eventId, eventName: eventName,
    userId: userId, status: status,
    fullName: fullName, identificationNumber: identificationNumber,
    birthDate: birthDate, phone: phone, email: email,
    residenceCity: residenceCity, eps: eps,
    medicalInsurance: medicalInsurance, bloodType: bloodType,
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
    vehicleId: vehicleId, vehicleSummary: vehicleSummary,
    createdAt: createdAt, updatedAt: updatedAt,
  ).toJson();
}
```

**Archivos afectados:**
- `lib/features/event_registration/data/repository/event_registration_repository_impl.dart`
- Eliminar `EventRegistrationModelToDto` extension completa

> **Nota sobre `vehicleSummary`:** el campo es `VehicleSummaryModel?` en el modelo. Para la deserialización JSON, `json_serializable` necesita saber cómo construir `VehicleSummaryModel` desde JSON. Hay dos opciones: (a) hacer que `VehicleSummaryDto extends VehicleSummaryModel` y usarlo como tipo en el campo del DTO con un `@JsonKey(fromJson: ...)`, o (b) usar `VehicleSummaryModel` directamente con un converter. Ver ítem de `VehicleSummaryDto` abajo.

---

#### `VehicleSummaryDto` (`lib/features/event_registration/data/dto/vehicle_summary_dto.dart`)

**Estado actual:** clase separada muy simple con `toModel()`.

**Resultado esperado:**

```dart
@JsonSerializable()
class VehicleSummaryDto extends VehicleSummaryModel {
  const VehicleSummaryDto({
    required super.id,
    super.brand,
    super.model,
    super.licensePlate,
    super.vin,
  });

  factory VehicleSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleSummaryDtoToJson(this);
}

extension VehicleSummaryModelExtension on VehicleSummaryModel {
  Map<String, dynamic> toJson() => VehicleSummaryDto(
    id: id, brand: brand, model: model,
    licensePlate: licensePlate, vin: vin,
  ).toJson();
}
```

**Nota:** `VehicleSummaryModel` tiene un getter `displayName`. Los getters en el modelo son heredados automáticamente por el DTO — no hay que redeclararlos.

---

#### `SoatDto` — feature `soat` (`lib/features/soat/data/dto/soat_dto.dart`)

**Estado actual:** clase separada con `toModel()` y extension `SoatModelToRequest.toRequestJson()`.

**Modelo de dominio:** `lib/features/soat/domain/models/soat_model.dart`

**Particularidad:** `toRequestJson()` en la extension actual construye un JSON custom (campos opcionales, fechas en UTC ISO). Este comportamiento debe preservarse. La extension puede mantenerse como `toRequestJson()` en lugar de `toJson()` porque el DTO no necesita serializar el modelo completo para escritura — solo un subset de campos.

**Resultado esperado:**

```dart
@JsonSerializable(converters: apiJsonDateTimeConverters)
class SoatDto extends SoatModel {
  const SoatDto({
    required super.id,
    required super.vehicleId,
    super.policyNumber,
    super.startDate,
    required super.expiryDate,
    super.insurer,
    super.documentUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory SoatDto.fromJson(Map<String, dynamic> json) =>
      _$SoatDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SoatDtoToJson(this);
}

// Extension de escritura — mantiene el comportamiento actual
extension SoatModelToRequest on SoatModel {
  Map<String, dynamic> toRequestJson() {
    final map = <String, dynamic>{
      'expiryDate': expiryDate.toUtc().toIso8601String(),
    };
    if (policyNumber != null) map['policyNumber'] = policyNumber;
    if (startDate != null) map['startDate'] = startDate!.toUtc().toIso8601String();
    if (insurer != null) map['insurer'] = insurer;
    if (documentUrl != null) map['documentUrl'] = documentUrl;
    return map;
  }
}
```

**Verificar antes:** que `SoatModel` tenga todos los campos como `final` en el constructor con los mismos tipos que usa el DTO (`DateTime?` para `expiryDate`, no `DateTime`).

---

#### `SoatDto` — feature `vehicles` (`lib/features/vehicles/data/dto/soat_dto.dart`)

**Estado actual:** clase separada. Usa `String` para `startDate` y `expiryDate`, y `DateTime.parse()` en `toModel()`. El `SoatModel` de vehicles (`lib/features/vehicles/domain/models/soat_model.dart`) tiene `DateTime` para esas fechas.

**Este DTO requiere análisis adicional antes de migrar:**
- Determinar si el modelo de vehicles/soat ya está alineado con el de soat-feature.
- Si `vehicles/soat_model` y `soat/soat_model` son dos modelos distintos para el mismo concepto, evaluar unificarlos primero.
- La discrepancia de tipos (String vs DateTime) en el DTO sugiere que este fue creado antes de adoptar `apiJsonDateTimeConverters`.

**Acción:** primero unificar los dos `SoatModel` si son equivalentes; luego migrar.  
**Estado en esta iteración:** 🔶 Pendiente de análisis — no incluir en la primera iteración de migración.

---

### 5.4 DTOs que NO se migran (documentados para evitar confusión)

| DTO | Razón de exclusión |
|---|---|
| `HomeDto` | Agrega `VehicleDto` + `List<EventDto>` en un solo wrapper; no hay modelo de dominio 1:1 |
| `CreateMaintenanceResponseDto` | DTO de respuesta compuesta (`created: List<MaintenanceDto>`) |
| `VehicleMaintenancesListResponseDto` | Wrapper compuesto; solo se usa en el repositorio para deserializar y descomponer |
| `MaintenanceListSummaryDto` | Sub-DTO auxiliar embebido en `VehicleMaintenancesListResponseDto` |
| `CreateUserDto` | Request DTO minimal (2 campos), no tiene modelo de dominio |
| `NotificationDto` | `toModel()` contiene lógica de negocio no trivial (switch de tipos, construcción de título/body). Migración futura: extraer esa lógica a `NotificationModel` o a un mapper |
| `GeocodeResultDto` | Respuesta de API de geocodificación; no tiene modelo de dominio equivalente |
| `PlaceSuggestionDto` | Mapea a `AddressLocation` pero con lógica en getter; funciona como está |

---

## 6. Restricción técnica — `freezed` y herencia

El patrón `XDto extends XModel` **solo es posible si `XModel` es una clase Dart pura** (no generada con `@freezed`).

Las clases `@freezed` generan una implementación `sealed` que no soporta herencia personalizada.

**Modelos actualmente en freezed** que impiden la migración directa de sus DTOs:

> Verificar con `grep -rn "@freezed" lib/features/*/domain/model/` antes de migrar cada DTO.

Si un modelo es `@freezed`, hay dos opciones:
1. **Convertir el modelo a clase Dart pura** (recomendado cuando el modelo es simple y los `copyWith`/`==`/`hashCode` se pueden implementar manualmente).
2. **Mantener el DTO como clase separada** y documentarlo como excepción justificada.

---

## 7. Orden de ejecución recomendado

Ordenado de menor a mayor complejidad:

| # | DTO | Esfuerzo | Dependencias |
|---|---|---|---|
| 1 | `VehicleSummaryDto` | 🟢 Bajo | Ninguna; debe hacerse antes de `EventRegistrationDto` |
| 2 | `VehicleDto` — limpieza | 🟢 Bajo | Eliminar `toModel()`, ajustar repositorio |
| 3 | `UserDto` — limpieza | 🟢 Bajo | Reemplazar `fromModel()` por extension |
| 4 | `MaintenanceDto` | 🟡 Medio | Verificar que `MaintenanceModel` no es freezed |
| 5 | `EventRegistrationDto` | 🟡 Medio | Depende de `VehicleSummaryDto` (paso 1) |
| 6 | `SoatDto` (soat feature) | 🟡 Medio | Verificar `SoatModel` |
| 7 | `SoatDto` (vehicles) | 🔴 Alto | Resolver duplicación de `SoatModel` primero |

---

## 8. Criterios de aceptación

- [ ] Todos los DTOs listados en §5.2 y §5.3 (excepto el marcado 🔶) siguen el Patrón B.
- [ ] Ningún repositorio llama `.toModel()` sobre un DTO (excepto DTOs de §5.4).
- [ ] Ningún DTO tiene `factory XDto.fromModel()` (excepto DTOs de §5.4).
- [ ] Cada DTO migrado tiene su extension `XModelExtension.toJson()` en el mismo archivo.
- [ ] `dart analyze` pasa sin errores nuevos.
- [ ] `flutter test` pasa al 100% (ninguna prueba existente rota).
- [ ] Cada archivo de DTO migrado tiene un único `part` file generado (`.g.dart`), sin archivos `.g.dart` huérfanos.
- [ ] El documento `docs/features/events.md` y `CLAUDE.md` reflejan el patrón actualizado como el único estándar.

---

## 9. Actualización de reglas de codificación

Al completar la migración, actualizar `.cursor/rules/rideglory-coding-standards.mdc` con:

```markdown
## DTOs — Patrón obligatorio

Todo DTO que representa un modelo de dominio con relación 1:1 DEBE heredar del modelo:

class XDto extends XModel { ... }
extension XModelExtension on XModel { Map<String, dynamic> toJson() => ... }

Prohibido: toModel(), fromModel(), toDto() — ver docs/prds/prd-dto-inheritance-standard.md §4 para excepciones.
```
