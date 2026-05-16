> Slim handoff for /custom-iter vehicle-form-specs. Full detail in architect.md (read only if ambiguous).

# Backend Handoff — vehicle-form-specs

## What to do
Add 4 nullable string columns (engine, horsepower, torque, weight) to the Vehicle data model and propagate through the NestJS microservice stack.

## Files to modify (in order)

### 1. `vehicles-ms/prisma/schema.prisma`
Add after `isMainVehicle`:
```prisma
engine       String?
horsepower   String?
torque       String?
weight       String?
```

### 2. Generate Prisma migration
```bash
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
npx prisma migrate dev --name add_vehicle_specs
```
This creates `prisma/migrations/<timestamp>_add_vehicle_specs/migration.sql`.

### 3. `rideglory-contracts/src/vehicles/dto/create-vehicle.dto.ts`
Add after `imageUrl` optional field:
```typescript
@IsOptional()
@IsString()
engine?: string;

@IsOptional()
@IsString()
horsepower?: string;

@IsOptional()
@IsString()
torque?: string;

@IsOptional()
@IsString()
weight?: string;
```

### 4. `vehicles-ms/src/vehicles/entities/vehicle.entity.ts`
Add same 4 optional @IsString() fields (matching the class-validator pattern already used).

### 5. Rebuild contracts package
```bash
cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
npm run build
```

## Files NOT to modify
- `update-vehicle.dto.ts` — uses `PartialType(CreateVehicleDto)`, inherits automatically
- `vehicles.service.ts` — `create()` and `update()` use `...rest` spread, new fields pass through automatically
- `vehicles.controller.ts` — no change

## Tests
Run before your changes (baseline) and after:
```bash
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
npm run test:e2e
```
Record both results in your handoff.

## Hard Rules
- NO git commits
- NO modification of any files outside this list
