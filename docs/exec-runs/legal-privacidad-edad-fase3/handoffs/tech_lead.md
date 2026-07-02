# Tech Lead — legal-privacidad-edad-fase3

**Generado:** 2026-07-01T04:47:00Z
**Nivel:** normal

## Veredicto

**ready** — sin blockers. Los 9 archivos modificados coinciden 1:1 con el change map del
architect, los 4 archivos de test nuevos cubren cada AC del PRD con casos que fallarían sin el
cambio, `dart analyze` reporta 0 errores, y la suite completa (901 tests) pasa. Verifiqué de forma
independiente (no solo leyendo los handoffs de frontend/QA): re-corrí `build_runner`,
`dart analyze`, los tests nuevos y la suite completa, y leí cada hunk del diff contra el change map
y los guardrails del §6/§7 del PRD.

## Hallazgos

Ninguno bloqueante. Una desviación documentada, ya validada:

- **`_BloodTypeConverter` a nivel de clase, no de campo** (`event_registration_dto.dart`): el
  handoff del architect pedía la anotación a nivel de campo (`@_BloodTypeConverter() required
  super.bloodType`); frontend documentó en su handoff que `json_serializable` 6.11.2 ignora
  silenciosamente converters custom en parámetros `super.xxx` (el analyzer no reporta error, pero
  el `.g.dart` generado seguía usando el enum decoder automático). Verifiqué el `.g.dart`
  regenerado localmente: `bloodType: const _BloodTypeConverter().fromJson(json['bloodType'] as
  String?)` — el converter de clase sí se aplica correctamente. Es seguro porque `bloodType` es el
  único campo `BloodType?` del DTO. Watchlist: si una fase futura agrega un segundo campo
  `BloodType?` a este mismo DTO, revisar que el converter de clase siga aplicándose al campo
  correcto (o migrar a `@JsonKey(fromJson:, toJson:)` explícito por campo).

## Seguridad

- Sin secretos, URLs hardcodeadas, ni SQL/concatenación (fase 100% Flutter domain/data).
- Sin PII en logs — no se agregó ningún `print`/log de los campos legales nuevos (verificado por
  grep, ningún archivo tocado contiene `print(` ni referencias de logging con estos campos).
- `bloodType` (dato médico sensible) pasa a nullable de forma intencional para tolerar ofuscación
  del backend — correcto desde la perspectiva de Ley 1581 (el frontend nunca fuerza a mostrar un
  dato médico no compartido). No hay riesgo de exposición nueva: el converter retorna `null` para
  cualquier valor no reconocible, nunca hace *passthrough* de un centinela como si fuera texto
  clínico válido.
- `sosTriggeredAt` incluido en `EventModelExtension.toJson()` (usado en escritura de eventos): el
  architect verificó contra `api-gateway/src/main.ts` que el `ValidationPipe` usa
  `whitelist: true` sin `forbidNonWhitelisted`, por lo que el campo se descarta silenciosamente en
  el backend sin error 400 si se envía por error en un create/update — no hay riesgo de que un
  cliente falsifique este timestamp servidor-controlado.

## Arquitectura

- Clean Architecture respetada: cambios de domain (`event_registration_model.dart`,
  `event_model.dart`, `user_model.dart`) sin imports de Flutter ni I/O de red; DTOs sin
  `BuildContext`; el único cambio de presentation (`registration_detail_page.dart`) es una
  corrección de null-safety de una línea, no una decisión de UI/diseño (consistente con la
  decisión del architect de `needsDesign = false`).
- Pattern B (DTO extends Model + `XModelExtension.toJson()`) preservado en los 3 DTOs tocados; no
  se usó `toModel()`/`fromModel()`/`.toDto()` en ningún punto.
- Nombres de campo JSON verificados 1:1 contra los contratos backend documentados por el architect
  (no hubo necesidad de `@JsonKey(name:)` porque ya coinciden).
- `UserModel.copyWith` se agregó completo (14 campos previos + el nuevo) — evita el riesgo de
  "copyWith parcial" señalado como riesgo por el architect.
- Ningún archivo fuera del change map fue tocado; `RegistrationService`,
  `EventRegistrationRepositoryImpl`, `rider_profile_repository_impl.dart`,
  `rider_profile_model.dart`, `edit_profile_page.dart` permanecen intactos (confirmado por
  `git status`/`git diff --stat`).
- No hay ERD/migraciones en esta fase (backend ya cerrado en Fase 1) — no aplica revisión de
  schema.

## Tests

- Cada uno de los 10 AC del PRD tiene test explícito o verificación manual documentada
  (`handoffs/qa.md`), y los tests fallarían sin el cambio correspondiente:
  - AC#1 (defaults) — `TC-model-01`.
  - AC#2 (tolerancia a centinelas) — `TC-dto-01..04` (incluye el caso de clave ausente, no solo
    los 2 centinelas explícitos del PRD).
  - AC#3 (`toJson()` propaga los 4 campos) — `TC-dto-05`.
  - AC#4 (`EventDto.fromJson` de los 2 timestamps) — 2 tests, presente/ausente.
  - AC#5 (`UserDto.fromJson` del timestamp médico) — 2 tests, presente/ausente.
  - AC#6 (constantes de `RegistrationFormFields`) — 2 assertions literales, agregadas a pedido del
    auditor Opus de QA tras señalar que un typo en cualquiera de las 2 constantes rompería el
    binding de `_preloadFromExistingRegistration` sin fallar ningún test previo. Correcto — sin
    esta corrección el AC#6 quedaba solo cubierto "implícitamente" por `dart analyze`, que no
    detecta un typo de valor string.
  - AC#7/#8 (analyze/build_runner limpios) — verificado por Tech Lead de forma independiente.
  - AC#9 (grep de `bloodType` no-nullable) — verificado por Tech Lead con
    `grep -rn '\.bloodType\b' lib/`.
  - AC#10 (`_buildRiderProfile` sin error de tipo) — implícito en AC#7, confirmado por lectura de
    `registration_form_cubit.dart:357`.
- Re-ejecuté de forma independiente: `dart run build_runner build --delete-conflicting-outputs`
  (0 outputs nuevos), `dart analyze` (0 errores, 6 info preexistentes), los 4 archivos de test
  nuevos (12/12 pass), y la suite completa (`flutter test` → 901/901 pass, exit 0).
- No hay tests de widget/golden afectados — `registration_detail_page.dart` no tiene golden test
  en este repo para esa fila.

## Pruebas manuales

No se requieren pruebas manuales de UI — fase puramente domain/data, sin pantallas ni widgets
nuevos (confirmado por `git diff --stat`: 0 archivos bajo `presentation/**` con cambios visuales,
solo 1 línea defensiva de null-safety y ajustes internos de cubit).

Sugerencia para cuando exista UI (Fases 4-6, no bloqueante aquí):
- Cargar una inscripción existente en `RegistrationDetailPage` y confirmar que la fila "Tipo de
  sangre" no crashea cuando el backend envía un centinela de ofuscación u omite el campo (mecanismo
  de datos ya cubierto por esta fase; falta validación visual cuando exista la UI real de Fase 2
  backend + Fase 7 frontend).
