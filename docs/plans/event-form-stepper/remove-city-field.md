# Tarea: Eliminar campo `city` de eventos por completo

## Objetivo

Eliminar el campo `city` de la entidad Event en todos los layers: DB, contratos, backend, Flutter domain/data/presentation. No hay usuarios ni eventos reales en producción — la eliminación es segura y no requiere migración de datos.

`meetingPointName` actúa como proxy geográfico en el cubit y en el contexto de IA. El campo `city` de filtro en GET /events también se elimina (la UI no lo usa actualmente).

## Alcance

### Backend (rideglory-api)

1. **`events-ms/prisma/schema.prisma`**: eliminar campo `city` del modelo `Event`. Correr `npx prisma migrate dev --name remove_event_city`. Regenerar el cliente Prisma (`npx prisma generate`).
2. **`rideglory-contracts/src/events/dto/create-event.dto.ts`**: eliminar campo `city`.
3. **`rideglory-contracts/src/events/dto/event-filter.dto.ts`**: eliminar campo `city`.
4. **`rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts`**: eliminar campo `city`.
5. **`events-ms/src/events/events.service.ts`**: eliminar referencias a `city` en create/update/filter.
6. **`api-gateway/src/ai/gemini.service.ts`**: eliminar `city` del contexto enviado a Gemini (usar `meetingPoint` si está disponible, o simplemente omitirlo).
7. Rebuild contracts: `cd rideglory-contracts && npm run build`. Reinstalar en microservicios afectados (`pnpm install`).

### Flutter (lib/)

1. **`lib/features/events/domain/model/event_model.dart`**: eliminar campo `city` (constructor, copyWith, toString, ==, hashCode). Regenerar freezed si aplica.
2. **`lib/features/events/data/dto/event_dto.dart`**: eliminar `city` del DTO.
3. **`lib/features/events/data/service/event_service.dart`**: eliminar `@Query('city') String? city` del método GET events.
4. **`lib/features/events/data/repository/event_repository_impl.dart`**: eliminar parámetro `city`.
5. **`lib/features/events/domain/repository/event_repository.dart`**: eliminar parámetro `city`.
6. **`lib/features/events/domain/use_cases/get_events_use_case.dart`**: eliminar parámetro `city`.
7. **`lib/features/events/domain/model/ai_description_request.dart`**: eliminar campo `city`.
8. **`lib/features/events/data/dto/ai_event_context_dto.dart`**: eliminar campo `city`; actualizar `fromRequest()` para no incluirlo.
9. **`lib/features/events/domain/use_cases/generate_event_description_use_case.dart`**: eliminar `city: request.city`.
10. **`lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart`**: eliminar `AppCityAutocomplete` y toda referencia a `EventFormFields.city`.
11. **`lib/features/events/constants/event_form_fields.dart`** (o donde viva): eliminar constante `city`.
12. Correr `dart run build_runner build --delete-conflicting-outputs` y `dart analyze`. Todo en verde.

## Criterios de aceptación

1. `grep -rn "\.city" lib/features/events/ --include="*.dart"` retorna vacío (excepto archivos generados).
2. `grep -rn "city" rideglory-api/events-ms/prisma/schema.prisma` retorna vacío.
3. `grep -rn "city" rideglory-api/rideglory-contracts/src/events/` retorna vacío.
4. Migración Prisma aplicada localmente; `events-ms` compila y las pruebas pasan.
5. `dart analyze lib/` — No issues found.
6. `flutter test` — todos los tests en verde (los tests de city en analytics test usan `city: ''` — actualizar a que no pasen city).
7. `AppCityAutocomplete` no aparece en `lib/features/events/presentation/`.
8. `EventFormFields.city` no existe.

## Nivel rg-exec: normal
