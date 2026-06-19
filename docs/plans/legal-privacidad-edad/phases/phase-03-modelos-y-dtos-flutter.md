# Fase 3 — Modelos y DTOs Flutter

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:56:41Z
**Nivel rg-exec recomendado:** normal
**dependsOn:** [1]

---

## Objetivo

Extender los modelos de dominio y DTOs de Flutter para que reflejen los campos legales definidos en los contratos del backend (Fase 1). Al término de esta fase, la app puede serializar y enviar los 4 campos legales de inscripción en el body del POST, `EventModel` expone los timestamps de responsabilidad del organizador y SOS, y `UserModel` porta el timestamp de consentimiento médico Ley 1581 — sin descartes silenciosos en ningún payload de escritura.

---

## Alcance (entra / no entra)

### Entra
- `EventRegistrationModel`: +4 campos de consentimiento/waiver + cambio de tipo en `bloodType` de `BloodType` (enum no-nullable) a `BloodType?` con `_BloodTypeConverter` custom en el DTO.
- `EventRegistrationDto`: mismos 4 campos, ajuste de tipo `bloodType` a `BloodType?` con `_BloodTypeConverter`, regenerar `.g.dart`.
- `EventRegistrationModelExtension.toJson()`: incluir los 4 campos nuevos en la construcción del DTO — corrección C1.
- `EventModel`: +2 campos (`organizerAcceptedResponsibilityAt`, `sosTriggeredAt`).
- `EventDto`: mismos 2 campos, `EventModelExtension.toJson()` actualizado, regenerar `.g.dart`.
- `UserModel`: +1 campo (`medicalConsentAcceptedAt`), `copyWith` completo si no existe.
- `UserDto`: +1 campo, `UserModelExtension.toJson()` actualizado, regenerar `.g.dart`.
- `RegistrationFormFields`: +2 constantes para los switches de privacidad (`shareMedicalInfo`, `allowOrganizerContact`).
- `RegistrationFormCubit._preloadFromExistingRegistration`: parchear los 2 campos booleanos en modo edición.
- `RegistrationFormCubit._buildRegistration`: cast a `BloodType?`.
- `registration_detail_page.dart` línea 128: actualizar acceso al campo `BloodType?` para que compile.
- Gate de calidad: `dart analyze` sin errores + `dart run build_runner build --delete-conflicting-outputs` sin conflictos.
- Tests unitarios del `toJson()` y del `_BloodTypeConverter`.

### No entra
- Lógica de UI (switches, pantallas de waiver, consentimiento). Eso es Fases 4, 5 y 6.
- Ofuscación en el frontend. El backend retorna los centinelas; Flutter los renderiza tal cual (Fase 7).
- Campo `bloodTypeRaw: String?` en el modelo: el render de los centinelas `"__NOT_SHARED__"` y `"••••"` en la UI es responsabilidad de Fase 7. En Fase 3 la línea 128 de `registration_detail_page.dart` queda `value: registration.bloodType?.label ?? ""` — el centinela queda invisible hasta Fase 7. No se añade ningún campo de respaldo de tipo `String?` al modelo de dominio.
- Cambios en `RegistrationService` ni en `EventRegistrationRepositoryImpl`: el repo ya llama `registration.toJson()` correctamente; solo el contenido del `toJson()` cambia.
- Nuevos use cases ni interfaces de repositorio.
- Cambios en el backend.

---

## Que se debe hacer (pasos concretos y ordenados)

### 1. Decisión de tipo para `bloodType` — BloodType?

**Decisión adoptada: `bloodType: BloodType?` en `EventRegistrationModel` con `_BloodTypeConverter` en `EventRegistrationDto`.**

Justificación: el architect review (Ajuste 4, R3) confirma que el backend puede retornar `"__NOT_SHARED__"` o `"••••"` como string cuando el campo está ofuscado. El enum `BloodType` no puede deserializarlos sin excepción.

- **Enfoque adoptado:** El campo de almacenamiento en `EventRegistrationModel` es `final BloodType? bloodType`. El DTO aplica `_BloodTypeConverter` en `fromJson` para mapear `@JsonValue` exactos del enum y retornar `null` para cualquier string no reconocido (centinelas). El modelo de dominio no tiene campo `bloodTypeRaw`; el render del centinela es trabajo de Fase 7.
- **Alternativa descartada:** `bloodType: String` en el modelo de dominio — mayor blast radius en el cubit y en `RiderProfileModel`.

**Consecuencias mecánicas del cambio:**

- `_buildRegistration` en el cubit: cast pasa de `as BloodType` a `as BloodType?`.
- `_buildRiderProfile`: `bloodType: reg.bloodType` pasa de `BloodType` a `BloodType?` — `RiderProfileModel.bloodType` ya es `BloodType?`, sin cambio de código.
- `_preloadFromExistingRegistration` línea 141: `existingRegistration.bloodType` sigue siendo válido; el selector acepta `BloodType?`, sin cambio.
- `registration_detail_page.dart` línea 128: `registration.bloodType.label` (acceso no-nullable) falla con el nuevo tipo; actualizar a `registration.bloodType?.label ?? ""`.

### 2. `EventRegistrationModel` — cambiar tipo de `bloodType` y añadir 4 campos

Archivo: `lib/features/event_registration/domain/model/event_registration_model.dart`

**2a. Cambiar `bloodType: BloodType` a `bloodType: BloodType?`**

- Campo: `final BloodType? bloodType;`
- Constructor: `this.bloodType,` (sin `required`, sin default).
- `copyWith`: parámetro `BloodType? bloodType`.

**2b. Añadir 4 campos nuevos al modelo**

```dart
final bool shareMedicalInfo;       // default: false
final bool allowOrganizerContact;  // default: false
final DateTime? riskAcceptedAt;
final String? riskAcceptanceVersion;
```

Constructor:
```dart
this.shareMedicalInfo = false,
this.allowOrganizerContact = false,
this.riskAcceptedAt,
this.riskAcceptanceVersion,
```

Extender `copyWith` con los 4 nuevos parámetros:
```dart
bool? shareMedicalInfo,
bool? allowOrganizerContact,
DateTime? riskAcceptedAt,
String? riskAcceptanceVersion,
```
Y en el body: `shareMedicalInfo: shareMedicalInfo ?? this.shareMedicalInfo`, etc.

### 3. `_BloodTypeConverter` — JsonConverter custom para BloodType?

En el archivo `lib/features/event_registration/data/dto/event_registration_dto.dart`, agregar el converter antes de la clase del DTO:

```dart
String _bloodTypeJsonValue(BloodType bt) {
  switch (bt) {
    case BloodType.aPositive:  return 'A_POSITIVE';
    case BloodType.aNegative:  return 'A_NEGATIVE';
    case BloodType.bPositive:  return 'B_POSITIVE';
    case BloodType.bNegative:  return 'B_NEGATIVE';
    case BloodType.abPositive: return 'AB_POSITIVE';
    case BloodType.abNegative: return 'AB_NEGATIVE';
    case BloodType.oPositive:  return 'O_POSITIVE';
    case BloodType.oNegative:  return 'O_NEGATIVE';
  }
}

class _BloodTypeConverter implements JsonConverter<BloodType?, String?> {
  const _BloodTypeConverter();

  @override
  BloodType? fromJson(String? value) {
    if (value == null) return null;
    try {
      return BloodType.values.firstWhere(
        (bt) => _bloodTypeJsonValue(bt) == value,
      );
    } catch (_) {
      return null; // centinelas '__NOT_SHARED__', '••••' u otros → null
    }
  }

  @override
  String? toJson(BloodType? value) =>
      value == null ? null : _bloodTypeJsonValue(value);
}
```

El `fromJson` usa **solo** `_bloodTypeJsonValue(bt) == value` — coincidencia exacta contra los `@JsonValue` declarados en el enum. No se añade una condición alternativa con `bt.name.toUpperCase()` porque produciría falsos positivos (e.g. `'APOSITIVE'` ≠ `'A_POSITIVE'`) y complica el test R1.

La función `_bloodTypeJsonValue` debe coincidir exactamente con los `@JsonValue` declarados en el enum (confirmado en `event_registration_model.dart`: `'A_POSITIVE'`, `'A_NEGATIVE'`, etc.).

### 4. `EventRegistrationDto` — reflejar cambios del modelo

Archivo: `lib/features/event_registration/data/dto/event_registration_dto.dart`

- Añadir `@_BloodTypeConverter()` sobre la clase (o per-field si json_serializable lo soporta). Aplicar el converter solo al campo `bloodType`.
- Cambiar `required super.bloodType` a `super.bloodType` (ahora `BloodType?`, sin `required`).
- Añadir los 4 parámetros nuevos al constructor con `super.*`:
  ```dart
  super.shareMedicalInfo = false,
  super.allowOrganizerContact = false,
  super.riskAcceptedAt,
  super.riskAcceptanceVersion,
  ```
- Para `riskAcceptedAt` el converter `apiJsonDateTimeConverters` ya está en la anotación `@JsonSerializable` — maneja `DateTime?` correctamente, igual que `endDate` en `EventDto`.

### 5. `EventRegistrationModelExtension.toJson()` — incluir los 4 campos (corrección C1)

En el mismo archivo `event_registration_dto.dart`, la extensión `EventRegistrationModelExtension.toJson()` construye un `EventRegistrationDto` literal y llama `.toJson()`. Sin actualización, los 4 campos legales no viajan en el POST (descarte silencioso — corrección C1 de la síntesis).

Actualizar la extensión para que el DTO literal incluya los 4 campos nuevos y el `bloodType` actualizado:

```dart
extension EventRegistrationModelExtension on EventRegistrationModel {
  Map<String, dynamic> toJson() => EventRegistrationDto(
    id: id,
    eventId: eventId,
    eventName: eventName,
    userId: userId,
    status: status,
    fullName: fullName,
    identificationNumber: identificationNumber,
    birthDate: birthDate,
    phone: phone,
    email: email,
    residenceCity: residenceCity,
    eps: eps,
    medicalInsurance: medicalInsurance,
    bloodType: bloodType,                          // BloodType?
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
    vehicleId: vehicleId,
    vehicleSummary: vehicleSummary == null
        ? null
        : VehicleSummaryDto(
            id: vehicleSummary!.id,
            brand: vehicleSummary!.brand,
            model: vehicleSummary!.model,
            licensePlate: vehicleSummary!.licensePlate,
            vin: vehicleSummary!.vin,
          ),
    shareMedicalInfo: shareMedicalInfo,
    allowOrganizerContact: allowOrganizerContact,
    riskAcceptedAt: riskAcceptedAt,
    riskAcceptanceVersion: riskAcceptanceVersion,
    createdAt: createdAt,
    updatedAt: updatedAt,
  ).toJson();
}
```

### 6. Regenerar `.g.dart` de `EventRegistrationDto`

```bash
dart run build_runner build --delete-conflicting-outputs
```

Verificar que `event_registration_dto.g.dart` incluye los 4 campos en la lógica generada y que `bloodType` usa `_BloodTypeConverter` en el código de `fromJson` / `toJson`.

### 7. `EventModel` — añadir 2 campos

Archivo: `lib/features/events/domain/model/event_model.dart`

```dart
final DateTime? organizerAcceptedResponsibilityAt;
final DateTime? sosTriggeredAt;
```

- Añadir al constructor como parámetros opcionales.
- Extender `copyWith` con los 2 nuevos parámetros.

### 8. `EventDto` — reflejar cambios de `EventModel`

Archivo: `lib/features/events/data/dto/event_dto.dart`

- Añadir `super.organizerAcceptedResponsibilityAt` y `super.sosTriggeredAt` al constructor.
- Ambos son `DateTime?` — el converter `apiJsonDateTimeConverters` ya los maneja (mismo patrón que `endDate: DateTime?`).
- Actualizar `EventModelExtension.toJson()` para incluirlos en la construcción del DTO literal (misma razón que corrección C1: evitar descarte silencioso cuando el organizador acepta responsabilidad y cuando se activa el SOS).

### 9. Regenerar `.g.dart` de `EventDto`

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 10. `UserModel` — añadir `medicalConsentAcceptedAt`

Archivo: `lib/features/users/domain/model/user_model.dart`

```dart
final DateTime? medicalConsentAcceptedAt;
```

- Añadir al constructor como parámetro opcional.
- Verificar si `UserModel` tiene `copyWith`; si no existe, agregar el método completo siguiendo el patrón de `EventRegistrationModel` (no parcial — para no dejar el modelo sin `copyWith`).

### 11. `UserDto` — reflejar cambio de `UserModel`

Archivo: `lib/features/users/data/dto/user_dto.dart`

- Añadir `super.medicalConsentAcceptedAt` al constructor.
- Actualizar `UserModelExtension.toJson()` para incluirlo.
- Regenerar `user_dto.g.dart`.

**Nota importante:** `UserDto.bloodType` usa la serialización estándar de `json_serializable` para `BloodType?` (sin `_BloodTypeConverter`). El endpoint `GET /users/me` es la vista del propio rider sobre sus propios datos y NO aplica ofuscación (la regla de `findMyRegistrationForEvent` de Fase 2 confirma que la vista propia nunca se ofusca). Por lo tanto, no se debe copiar `_BloodTypeConverter` a `UserDto` ni al `UserModel`, y no se espera que `bloodType` retorne centinelas en esa respuesta. El implementador no debe agregar el converter aquí.

### 12. `RegistrationFormFields` — añadir 2 constantes

Archivo: `lib/features/event_registration/constants/registration_form_fields.dart`

```dart
static const String shareMedicalInfo = 'shareMedicalInfo';
static const String allowOrganizerContact = 'allowOrganizerContact';
```

Estas constantes son necesarias para los `AppSwitchTile` del paso médico (Fase 4) y para el `_preloadFromExistingRegistration`.

### 13. `RegistrationFormCubit` — ajustes por cambio de tipo

Archivo: `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`

**13a. `_preloadFromExistingRegistration` — añadir los 2 booleanos nuevos.**

La línea existente `RegistrationFormFields.bloodType: existingRegistration.bloodType` permanece sin cambio — el selector acepta `BloodType?`.

Añadir los 2 campos booleanos nuevos al `patchValue`:
```dart
RegistrationFormFields.shareMedicalInfo: existingRegistration.shareMedicalInfo,
RegistrationFormFields.allowOrganizerContact: existingRegistration.allowOrganizerContact,
```
Los switches aún no existen en el form (se crean en Fase 4), pero `FormBuilder` ignora claves sin campo registrado — no rompe.

**13b. `_buildRegistration` — cast actualizado a nullable.**

Cambiar la línea (actualmente línea 331):
```dart
bloodType: formData[RegistrationFormFields.bloodType] as BloodType,
```
a:
```dart
bloodType: formData[RegistrationFormFields.bloodType] as BloodType?,
```

**13c. `_buildRiderProfile` — sin cambio requerido.**

`bloodType: reg.bloodType` pasa de `BloodType` a `BloodType?`. `RiderProfileModel.bloodType` ya es `BloodType?` — compatible sin edición.

### 14. `registration_detail_page.dart` — ajuste mínimo de compilación

Archivo: `lib/features/event_registration/presentation/registration_detail_page.dart`

Línea 128 actualmente:
```dart
value: registration.bloodType.label,
```

Con `bloodType: BloodType?`, el acceso `.label` sobre el nullable no compila. Actualizar a:
```dart
value: registration.bloodType?.label ?? '',
```

El centinela `"••••"` o `"__NOT_SHARED__"` quedará como string vacío en la UI hasta que Fase 7 implemente el render localizado. Esto es correcto e intencional — no se añade `bloodTypeRaw` ni ningún campo adicional al modelo.

### 15. Correr gate final

```bash
dart analyze
dart run build_runner build --delete-conflicting-outputs
```

Sin errores en ninguno de los dos.

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

| Acción | Ruta | Que cambia |
|--------|------|------------|
| Modificar | `lib/features/event_registration/domain/model/event_registration_model.dart` | `bloodType` de `BloodType` a `BloodType?`; +4 campos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt?`, `riskAcceptanceVersion?`); `copyWith` extendido |
| Modificar | `lib/features/event_registration/data/dto/event_registration_dto.dart` | `_BloodTypeConverter` custom + función `_bloodTypeJsonValue`; `bloodType` a `BloodType?` con converter; +4 campos en constructor y en `EventRegistrationModelExtension.toJson()` |
| Auto-generado | `lib/features/event_registration/data/dto/event_registration_dto.g.dart` | Regenerado con campos nuevos y converter |
| Modificar | `lib/features/events/domain/model/event_model.dart` | +`organizerAcceptedResponsibilityAt: DateTime?` y `sosTriggeredAt: DateTime?`; `copyWith` extendido |
| Modificar | `lib/features/events/data/dto/event_dto.dart` | Constructor + `EventModelExtension.toJson()` con los 2 campos nuevos |
| Auto-generado | `lib/features/events/data/dto/event_dto.g.dart` | Regenerado |
| Modificar | `lib/features/users/domain/model/user_model.dart` | +`medicalConsentAcceptedAt: DateTime?`; `copyWith` completo si no existe |
| Modificar | `lib/features/users/data/dto/user_dto.dart` | Constructor + `UserModelExtension.toJson()` con el campo nuevo (sin `_BloodTypeConverter`) |
| Auto-generado | `lib/features/users/data/dto/user_dto.g.dart` | Regenerado |
| Modificar | `lib/features/event_registration/constants/registration_form_fields.dart` | +constantes `shareMedicalInfo` y `allowOrganizerContact` |
| Modificar | `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | `_preloadFromExistingRegistration` parchea los 2 nuevos booleanos; `_buildRegistration` cast a `BloodType?`; `_buildRiderProfile` sin cambio |
| Modificar | `lib/features/event_registration/presentation/registration_detail_page.dart` | Línea 128: `bloodType.label` → `bloodType?.label ?? ''` para que compile con el campo nullable |

---

## Contratos / API rideglory-api

Ninguno en esta fase. La Fase 3 solo adapta Flutter para consumir los contratos ya definidos en Fase 1. No se agregan endpoints ni se cambia la API.

El implementador debe confirmar que los nombres de campo JSON en los DTOs Flutter coincidan exactamente con los definidos en `rideglory-contracts` (Fase 1):

| Campo Flutter (camelCase) | Campo JSON esperado del backend |
|--------------------------|--------------------------------|
| `shareMedicalInfo` | `shareMedicalInfo` |
| `allowOrganizerContact` | `allowOrganizerContact` |
| `riskAcceptedAt` | `riskAcceptedAt` |
| `riskAcceptanceVersion` | `riskAcceptanceVersion` |
| `organizerAcceptedResponsibilityAt` | `organizerAcceptedResponsibilityAt` |
| `sosTriggeredAt` | `sosTriggeredAt` |
| `medicalConsentAcceptedAt` | `medicalConsentAcceptedAt` |

Si alguno difiere, usar `@JsonKey(name: '...')` en el DTO.

---

## Cambios de datos / migraciones

Ninguno. Esta fase es puramente Flutter. Las migraciones de base de datos están en Fase 1 (backend).

---

## Criterios de aceptacion (numerados, observables, testeables)

1. **`EventRegistrationModel` tiene los 4 campos nuevos con sus defaults correctos.** Instanciar `EventRegistrationModel` con solo los campos requeridos existentes: `shareMedicalInfo` es `false`, `allowOrganizerContact` es `false`, `riskAcceptedAt` es `null`, `riskAcceptanceVersion` es `null`.

2. **`bloodType` en el modelo es `BloodType?`; deserialización tolerante a centinelas.** Test unitario: `EventRegistrationDto.fromJson({'bloodType': '__NOT_SHARED__', ...})` completa sin excepción y el campo `bloodType` retorna `null`. Con `'A_POSITIVE'` retorna `BloodType.aPositive`. Con `'••••'` retorna `null`.

3. **`EventRegistrationModelExtension.toJson()` incluye los 4 campos en el body de escritura.** Construir un `EventRegistrationModel` con `shareMedicalInfo: true`, `allowOrganizerContact: false`, `riskAcceptedAt: DateTime(2026, 6, 19)`, `riskAcceptanceVersion: 'v0.1-2026-06'`; llamar `.toJson()` y verificar que el mapa resultante contiene las 4 claves con los valores correctos. Este test unitario es el criterio de aceptación canónico — no requiere curl.

4. **`EventDto.fromJson()` deserializa `organizerAcceptedResponsibilityAt` y `sosTriggeredAt` sin lanzar excepción.** Pasar un mapa JSON con ambos campos como strings ISO-8601 y verificar que el `EventDto` resultante tiene los `DateTime?` correctos.

5. **`UserDto.fromJson()` deserializa `medicalConsentAcceptedAt` sin lanzar excepción.** Pasar un mapa JSON con el campo presente y ausente; verificar `DateTime?` correcto en ambos casos.

6. **`RegistrationFormFields` expone las 2 nuevas constantes.** `RegistrationFormFields.shareMedicalInfo == 'shareMedicalInfo'` y `RegistrationFormFields.allowOrganizerContact == 'allowOrganizerContact'`.

7. **`dart analyze` retorna 0 errores** (warnings aceptables solo si son pre-existentes y documentados).

8. **`dart run build_runner build --delete-conflicting-outputs` completa sin errores ni conflictos** y los 3 archivos `.g.dart` afectados están actualizados.

9. **No hay código de producción que acceda a `registration.bloodType` como `BloodType` no-nullable directamente.** Buscar con `grep -rn '\.bloodType\b' lib/` y verificar que cada resultado accede al campo `BloodType?` con `?.` o mediante un null check explícito. La línea 128 de `registration_detail_page.dart` debe mostrar `registration.bloodType?.label ?? ''`.

10. **`_buildRiderProfile` en `RegistrationFormCubit` asigna `reg.bloodType` (ya `BloodType?`) a `RiderProfileModel.bloodType` (también `BloodType?`) sin error de tipo.** `dart analyze` lo confirma en AC#7.

---

## Pruebas (unitarias/widget/integracion)

### Unitarias (obligatorias, sin widget tree)

**Archivo nuevo:** `test/features/event_registration/data/dto/event_registration_dto_test.dart`

Casos de prueba:
- `toJson() incluye shareMedicalInfo` — verifica clave presente con valor `true`/`false`.
- `toJson() incluye allowOrganizerContact` — ídem.
- `toJson() incluye riskAcceptedAt como string ISO-8601` — verifica que el datetime se serializa con el converter correcto.
- `toJson() incluye riskAcceptanceVersion` — verifica string presente.
- `toJson() incluye los 4 campos cuando el modelo tiene defaults false/null` — verifica que las claves están presentes aunque tengan valor por defecto (no se omiten).
- `fromJson() deserializa bloodType como BloodType.aPositive para 'A_POSITIVE'` — converter retorna el enum correcto.
- `fromJson() retorna null para bloodType '__NOT_SHARED__'` — converter tolerante, sin excepción.
- `fromJson() retorna null para bloodType '••••'` — converter tolerante, sin excepción.
- `fromJson() con bloodType null retorna null sin excepción` — campo nullable del backend.
- Round-trip: `toJson()` de un modelo con `bloodType: BloodType.oNegative` produce `'O_NEGATIVE'`; `fromJson()` de ese resultado retorna `BloodType.oNegative`.

**Archivo nuevo o actualizar:** `test/features/events/data/dto/event_dto_test.dart`

Casos:
- `fromJson() con organizerAcceptedResponsibilityAt presente` — retorna `DateTime` correcto.
- `fromJson() con organizerAcceptedResponsibilityAt ausente` — retorna null, sin excepción.
- `fromJson() con sosTriggeredAt presente` — retorna `DateTime` correcto.
- `toJson() incluye organizerAcceptedResponsibilityAt` — verifica presencia en mapa.

**Archivo nuevo o actualizar:** `test/features/users/data/dto/user_dto_test.dart`

Casos:
- `fromJson() con medicalConsentAcceptedAt presente` — retorna `DateTime` correcto.
- `fromJson() con medicalConsentAcceptedAt ausente` — retorna null, sin excepción.

### No requeridas en esta fase
- Tests de widget (no hay UI nueva).
- Tests de integración (el backend no está disponible para integration tests; la verificación del contrato se hace con los unit tests del `toJson()`).

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | `_BloodTypeConverter.fromJson` no mapea correctamente los `@JsonValue` del enum | Baja | `fromJson()` retorna siempre `null` incluso para tipos de sangre válidos | La función `_bloodTypeJsonValue` declara las 8 cadenas explícitamente — no depende de `bt.name`. Cubrir con tests del round-trip y de los 8 valores; el test de `'A_POSITIVE' → BloodType.aPositive` detecta el error inmediatamente. |
| R2 | `_buildRegistration()` aún usa cast no-nullable `as BloodType` después del cambio | Alta | `dart analyze` falla (type mismatch) | Paso 13b del plan es mecánico; AC#7 (`dart analyze` sin errores) lo detecta. |
| R3 | `EventRegistrationDto.fromJson()` recibe `bloodType: null` del backend en inscripciones antiguas | Baja | Campo `BloodType?` acepta null nativamente | No requiere mitigación adicional. |
| R4 | `riskAcceptedAt` y `medicalConsentAcceptedAt` como `DateTime?` — el converter genera código incorrecto si `apiJsonDateTimeConverters` no maneja nullable | Baja | Falla en build_runner o en fromJson | Revisar `api_date_time.dart`; el patrón ya funciona para `endDate: DateTime?` en `EventModel` — usar la misma anotación. |
| R5 | `UserModel` no tiene `copyWith` | Media | Si código llama `user.copyWith(medicalConsentAcceptedAt: ...)` sin el método, falla en compilación | Añadir `copyWith` completo en este paso; no parcial. |
| R6 | Conflictos en `.g.dart` si hay corrida previa de build_runner con estado sucio | Baja | Build falla | Usar `--delete-conflicting-outputs`; si falla, correr `dart run build_runner clean` primero. |
| R7 | `registration_detail_page.dart` línea 128: acceso `.label` sobre `BloodType?` sin actualizar | Alta | Error de compilación | Paso 14 del plan; AC#7 lo detecta en `dart analyze`. |

---

## Dependencias (fases prerequisito y por que)

| Fase prerequisito | Por que |
|------------------|---------|
| **Fase 1** (Contratos, schema de backend y endpoint medical-consent) | Los nombres de campo, tipos y semántica de los campos nuevos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`, `organizerAcceptedResponsibilityAt`, `sosTriggeredAt`, `medicalConsentAcceptedAt`) son definidos en `rideglory-contracts` durante Fase 1. Sin los contratos cerrados, los nombres de campo en los DTOs Flutter podrían disentir con el backend y generar errores de deserialización silenciosos. La decisión del centinela `"__NOT_SHARED__"` / `"••••"` también la fija Fase 1 — son los valores que `_BloodTypeConverter.fromJson` debe tolerar sin lanzar excepción. |

**Esta fase NO depende de Fase 2** (validación de edad y ofuscación condicional en backend). Los modelos y DTOs se pueden definir antes de que el backend implemente la ofuscación. Las Fases 2 y 3 pueden correr en paralelo una vez que Fase 1 está completa.

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por que normal:** Feature acotada de dominio/datos sin migraciones ni endpoints nuevos. El cambio de tipo en `bloodType` (de enum `BloodType` a `BloodType?` con `_BloodTypeConverter`) introduce riesgo de regresión medio pero contenido: todos los sitios de impacto son identificables con `dart analyze` y `grep`. Requiere `build_runner` sin conflictos en 3 DTOs. El criterio de aceptación verificable del `toJson()` mediante test unitario añade rigor sin elevar el blast radius a full. No hay lógica de negocio nueva, solo extensión de modelos y serialización. Los tests unitarios son rápidos y no requieren infraestructura.

**No requiere full porque:** no hay migraciones, no hay endpoints nuevos, no hay UI cross-cutting, no hay lógica de seguridad, y el blast radius está acotado a la capa de dominio/datos. Los tres puntos de impacto en el cubit (`_preloadFromExistingRegistration`, `_buildRegistration`, `_buildRiderProfile`) son cambios de cast mecánicos o no-cambios confirmados por análisis de tipo.

**Secuencia de ejecución sugerida para el agente:**
1. Leer todos los archivos a modificar antes de escribir cualquier cambio.
2. Modificar modelos primero (`EventRegistrationModel`, `EventModel`, `UserModel`) — sin ellos los DTOs no compilan.
3. Implementar `_bloodTypeJsonValue` y `_BloodTypeConverter` en `event_registration_dto.dart`.
4. Modificar `EventRegistrationDto` (tipo de `bloodType`, +4 campos).
5. Actualizar `EventRegistrationModelExtension.toJson()` con los 4 campos nuevos.
6. Modificar `EventDto` y `EventModelExtension.toJson()`.
7. Modificar `UserDto` y `UserModelExtension.toJson()` (sin `_BloodTypeConverter`).
8. Actualizar `RegistrationFormFields` y `RegistrationFormCubit`.
9. Actualizar `registration_detail_page.dart` línea 128.
10. Correr `dart analyze` — corregir errores de tipo antes de continuar.
11. Correr `build_runner` — confirmar `.g.dart` actualizados.
12. Escribir tests unitarios del `toJson()` y del `_BloodTypeConverter`.
13. Correr `dart analyze` final — 0 errores.
