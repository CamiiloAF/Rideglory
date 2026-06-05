> Slim handoff — read this before docs/exec-runs/rtm-backend-persistencia/handoffs/architect.md

# Architect → Backend

## Repo
`/Users/cami/Developer/Personal/rideglory-api`

## Files to create / modify

| File | Action |
|------|--------|
| `vehicles-ms/prisma/schema.prisma` | Añadir `model Tecnomecanica` después de `model Soat` |
| `vehicles-ms/prisma/migrations/<ts>_add_tecnomecanica/migration.sql` | Generado por `prisma migrate dev` |
| `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts` | Crear DTO (ver spec abajo) |
| `vehicles-ms/src/vehicles/tecnomecanica.service.ts` | Crear service (espejo de soat.service.ts) |
| `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` | Tests pure-logic (espejo de soat.service.spec.ts) |
| `vehicles-ms/src/vehicles/vehicles.controller.ts` | Añadir 4 MessagePatterns + inyectar TecnomecanicaService |
| `vehicles-ms/src/vehicles/vehicles.module.ts` | Añadir TecnomecanicaService a providers[] |
| `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts` | Copia idéntica del DTO |
| `api-gateway/src/vehicles/vehicles.controller.ts` | Añadir 3 rutas REST RTM |

## Model Prisma
```prisma
model Tecnomecanica {
  id                String    @id @default(uuid())
  vehicleId         String    @unique
  certificateNumber String
  cdaName           String
  cdaCode           String?
  startDate         DateTime?
  expiryDate        DateTime
  documentUrl       String?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}
```

## DTO (idéntico en ambos paquetes)
```typescript
export class CreateTecnomecanicaDto {
  @IsString() @IsNotEmpty()  certificateNumber: string;
  @IsString() @IsNotEmpty()  cdaName: string;
  @IsString() @IsOptional()  cdaCode?: string;
  @IsDateString() @IsOptional()  startDate?: string;   // opcional — diferente a SOAT
  @IsDateString()            expiryDate: string;
  @IsString() @IsOptional()  documentUrl?: string;
}
```

## MessagePatterns (vehicles-ms controller)
- `'upsertTecnomecanica'` — payload: `{ vehicleId, ownerId, dto }`
- `'findTecnomecanicaByVehicle'` — payload: `{ vehicleId, ownerId }`
- `'deleteTecnomecanica'` — payload: `{ vehicleId, ownerId }`
- `'findTecnomecanicasExpiringIn'` — payload: `{ daysUntilExpiry: number }`

## Rutas REST (api-gateway)
- `POST :vehicleId/tecnomecanica` → `upsertTecnomecanica` → 201
- `GET :vehicleId/tecnomecanica` → `findTecnomecanicaByVehicle` → 200 **o NotFoundException(404) si null**
- `DELETE :vehicleId/tecnomecanica` → `deleteTecnomecanica` → 200

**El GET de SOAT devuelve `null` con 200; el GET de RTM DEBE lanzar `NotFoundException` cuando no existe — no copiar el `?? null` del SOAT.**

## Lógica del service
- Copiar `validateVehicleOwnership` (privado, mismo código que SoatService — cada service tiene su propia instancia, no compartir).
- `upsertTecnomecanica`: si `startDate` presente → parseDate + validar `expiry > start`; si `startDate` ausente → no validar, persistir sin `startDate`.
- `findTecnomecanicasExpiringIn`: misma ventana UTC día-exacto que `findSoatsExpiringIn`.
- `deleteTecnomecanica`: buscar antes; lanzar `RpcException{status:404}` si no existe; borrar y retornar `{ success: true }`.

## Env
Sin nuevas variables. `DATABASE_URL` ya existe.

## Restricciones críticas
- `model Soat`, `SoatService`, `CreateSoatDto` — NO tocar.
- Los `@MessagePattern` existentes — NO modificar, solo añadir los 4 nuevos.
- Migración local: ejecutar `prisma migrate dev --name add_tecnomecanica` y validar que solo crea la tabla `Tecnomecanica` sin alterar `Soat`. Gate humano antes de cerrar la fase.

> Full detail: docs/exec-runs/rtm-backend-persistencia/handoffs/architect.md
