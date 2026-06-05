> Slim handoff — read this before docs/exec-runs/rtm-push-notifications/handoffs/architect.md

# Backend slim handoff — rtm-push-notifications

## Repo
`/Users/cami/Developer/Personal/rideglory-api`

## Archivos a tocar (en este orden)

### 1. `api-gateway/src/notifications/notifications.service.ts`
Añadir al string-union `NotificationType` (línea ~7):
```typescript
| 'TECNOMECANICA_30D'
| 'TECNOMECANICA_7D'
| 'TECNOMECANICA_DAY_OF'
```

### 2. `notifications-ms/src/notifications/notifications.service.ts`
Mismo cambio exacto (paridad obligatoria). Línea ~14 del union existente.

### 3. `api-gateway/src/scheduler/notification-scheduler.service.ts`

**Añadir interface** junto a `SoatRecord`:
```typescript
interface TecnomecanicaRecord {
  id: string;
  vehicleId: string;
  expiryDate: Date | string;
}
```

**Refactorizar** `private async sendSoatReminders(daysUntilExpiry, type)` en:
```typescript
private async sendDocumentExpiryReminders(
  kind: 'soat' | 'tecnomecanica',
  daysUntilExpiry: number,
  type: NotificationType,
): Promise<void>
```

Dentro del helper:
- RPC: `kind === 'soat'` → `findSoatsExpiringIn`, `kind === 'tecnomecanica'` → `findTecnomecanicasExpiringIn`
- Variable de registro: `SoatRecord | TecnomecanicaRecord` (misma forma: `id`, `vehicleId`)
- Copy FCM: tabla `messages` extendida con los 3 tipos RTM (ver cuerpos en architect.md §Contratos)
- El flujo `getVehicleById → findOneUser → createNotification + sendFcm` es idéntico para ambos kinds

**Reapuntar crons SOAT** (sin cambiar su cron expression ni nombre):
```typescript
async soatReminder30Days() { await this.sendDocumentExpiryReminders('soat', 30, 'SOAT_30D'); }
async soatReminder7Days()  { await this.sendDocumentExpiryReminders('soat', 7,  'SOAT_7D');  }
async soatReminderDayOf()  { await this.sendDocumentExpiryReminders('soat', 0,  'SOAT_DAY_OF'); }
```

**Añadir 3 crons RTM** (mismo decorador que SOAT):
```typescript
@Cron('0 9 * * *', { timeZone: 'America/Bogota' })
async tecnomecanicaReminder30Days() { await this.sendDocumentExpiryReminders('tecnomecanica', 30, 'TECNOMECANICA_30D'); }

@Cron('0 9 * * *', { timeZone: 'America/Bogota' })
async tecnomecanicaReminder7Days()  { await this.sendDocumentExpiryReminders('tecnomecanica', 7,  'TECNOMECANICA_7D');  }

@Cron('0 9 * * *', { timeZone: 'America/Bogota' })
async tecnomecanicaReminderDayOf()  { await this.sendDocumentExpiryReminders('tecnomecanica', 0,  'TECNOMECANICA_DAY_OF'); }
```

## RPC consumido (ya existe — NO crear)
- Patrón: `findTecnomecanicasExpiringIn`
- En: `vehicles-ms/src/vehicles/vehicles.controller.ts` línea 127
- Response shape: `{ id, vehicleId, expiryDate, ... }` — usar solo `id` y `vehicleId`

## Copy RTM
| Tipo | Título | Cuerpo |
|------|--------|--------|
| `TECNOMECANICA_30D` | `'Tu RTM vence en 30 días'` | `'La revisión técnico-mecánica de tu moto ${vehicle.name} vence en 30 días. ¡Sácala a tiempo!'` |
| `TECNOMECANICA_7D`  | `'Tu RTM vence en 7 días'`  | `'La revisión técnico-mecánica de tu moto ${vehicle.name} vence en 7 días. No esperes más.'` |
| `TECNOMECANICA_DAY_OF` | `'Tu RTM vence hoy'` | `'La revisión técnico-mecánica de tu moto ${vehicle.name} vence hoy. Preséntala cuanto antes.'` |

`route: 'rideglory://garage'` en createNotification y sendFcm data.

## Sin cambios
- Migraciones de DB: ninguna
- Variables de entorno: ninguna
- Módulos NestJS (`notification-scheduler.module.ts`): ninguno

> Full detail: docs/exec-runs/rtm-push-notifications/handoffs/architect.md
