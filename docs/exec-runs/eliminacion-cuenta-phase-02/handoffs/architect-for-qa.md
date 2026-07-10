# Architect → QA — eliminacion-cuenta-phase-02

Ver `handoffs/architect.md` para el detalle completo. Esta fase es 100% backend (sin cambios de UI
Flutter) — el flujo visible ya existe desde fase 1 y no cambia; lo que hay que verificar es que el
borrado en cascada realmente ocurre en el backend.

## Qué verificar (más allá de la respuesta HTTP)

1. **Vehículos + SOAT + RTM desaparecen de verdad.** Con un usuario QA que tenga N vehículos, cada
   uno con SOAT y RTM (con foto/documento) y M registros de mantenimiento: tras `DELETE /users/me`,
   consultar directo la BD de `vehicles-ms` (Postgres) — cero filas de `Vehicle`, `Soat`,
   `Tecnomecanica` con ese `ownerId`/`vehicleId`. **No confiar solo en que la UI ya no los muestre.**
2. **Mantenimientos quedan soft-deleted, no hard-deleted.** Los M registros de `Maintenance` del
   usuario deben tener `isDeleted: true` en BD (no deben desaparecer físicamente).
3. **Imágenes desaparecen del bucket de Firebase Storage.** Verificar en la consola de Firebase
   Storage (o `bucket.file(path).exists()`) que las imágenes de vehículos y los documentos de
   SOAT/RTM del usuario ya no existen tras el borrado.
4. **Casos borde que NO deben producir error 500 ni abortar el borrado de cuenta:**
   - Usuario con SOAT o RTM capturado sin foto (`documentUrl: null`).
   - Usuario con imagen de vehículo ya borrada manualmente del bucket antes de eliminar la cuenta
     (URL apunta a un objeto inexistente).
   - Usuario sin ningún vehículo (garage vacío) — el borrado de cuenta debe completar igual.
5. **La pantalla y el copy de confirmación no cambian** (fase 1 ya los entregó) — si algo en la UI
   de confirmación se ve distinto, es una regresión fuera de alcance de esta fase, repórtalo como
   tal.

## Cuentas de prueba

Usar **solo** las cuentas QA dedicadas — hay usuarios reales en producción desde 2026-07-10:
- `qa1@gmail.com` (rider) — password `Test123.`
- `qa2@gmail.com` (owner de "Mi Evento") — password `Test123.`

Antes de ejecutar el borrado real de cuenta contra estas cuentas QA, asegurarse de poder
recrearlas/repoblarlas después (el borrado de cuenta es irreversible por diseño), o usar una cuenta
QA desechable adicional creada solo para esta verificación si `qa1`/`qa2` se necesitan para otras
pruebas del ciclo.

## Suites que deben seguir en verde (regresión, sin cobertura nueva esperada del lado Flutter)

- `dart analyze` y `flutter test` (Flutter) — esta fase no toca código Flutter, solo
  `docs/features/*.md`; cualquier fallo aquí es una regresión ajena a esta fase o un error de
  ejecución.
- Tests unitarios nuevos en `rideglory-api`: `vehicles-ms/src/vehicles/vehicles.service.spec.ts`,
  `maintenances-ms/src/maintenances/maintenances.service.spec.ts` (nuevo),
  `api-gateway/src/ai/storage-cleanup.service.spec.ts`,
  `api-gateway/src/users/account-deletion.service.spec.ts` — todos deben pasar en CI del repo
  `rideglory-api`.

## Fuera de alcance de esta fase (no reportar como bug si aparece)

- Anonimización de `EventRegistration` / bloqueo por organizador con eventos activos (fase 3).
- Reintentos/idempotencia del endpoint completo de borrado de cuenta ante fallo parcial (fase 4).
- Cualquier cambio visual en la pantalla de confirmación de borrado de cuenta.
