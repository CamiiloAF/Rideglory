> Slim handoff — read this before docs/exec-runs/rtm-push-notifications/handoffs/architect.md

# QA slim handoff — rtm-push-notifications

## Comandos de prueba

```bash
# api-gateway
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npm test

# notifications-ms
cd /Users/cami/Developer/Personal/rideglory-api/notifications-ms
npm test
```

## Archivos de spec a verificar

| Archivo | Estado | Cobertura requerida |
|---------|--------|---------------------|
| `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` | **NUEVO** | Tests RTM 30/7/0 días + regresión SOAT |
| `api-gateway/src/notifications/notifications.service.spec.ts` | **MODIFICADO** | Añadir assertions RTM; assertions SOAT sin tocar |

## Criterios de aceptación — checklist

- [ ] CA1: `TECNOMECANICA_30D`, `TECNOMECANICA_7D`, `TECNOMECANICA_DAY_OF` presentes en `api-gateway/src/notifications/notifications.service.ts`
- [ ] CA2: Mismos 3 valores presentes en `notifications-ms/src/notifications/notifications.service.ts` (comparación literal)
- [ ] CA3: `sendSoatReminders` ya no existe como helper; `sendDocumentExpiryReminders` existe con firma `(kind, daysUntilExpiry, type)`
- [ ] CA4: Los 3 crons SOAT (`soatReminder30Days/7Days/DayOf`) siguen existiendo con `@Cron('0 9 * * *', { timeZone: 'America/Bogota' })` y llaman `sendDocumentExpiryReminders('soat', ...)`
- [ ] CA5: Los 3 crons RTM (`tecnomecanicaReminder30Days/7Days/DayOf`) existen con misma cron expression y llaman `sendDocumentExpiryReminders('tecnomecanica', ...)`
- [ ] CA6: Payload de cada notificación RTM contiene `vehicleId`, `vehicleName`, `route: 'rideglory://garage'`, `type: TECNOMECANICA_*`
- [ ] CA7: Copy RTM distinto del SOAT literal (título y cuerpo diferentes)
- [ ] CA8: `notifications.service.spec.ts` — bloque `SOAT reminder payload` sin cambios en assertions existentes
- [ ] CA9: `npm test` api-gateway 100% verde
- [ ] CA10: `npm test` notifications-ms 100% verde

## Casos de regresión SOAT obligatorios en el nuevo spec

```typescript
// Para cada tipo SOAT: verifica que el kind correcto llama el RPC correcto
// y que route === 'rideglory://garage' y type === 'SOAT_30D' | 'SOAT_7D' | 'SOAT_DAY_OF'
```

## Casos RTM en el nuevo spec

```typescript
// Fixture: lista de 1 TecnomecanicaRecord expiring en 30 días → verifica type TECNOMECANICA_30D y route garage
// Fixture: lista de 1 TecnomecanicaRecord expiring en 7 días  → verifica type TECNOMECANICA_7D
// Fixture: lista de 1 TecnomecanicaRecord expiring en 0 días  → verifica type TECNOMECANICA_DAY_OF
// Fixture: lista vacía → no emite ninguna notificación (assert 0 llamadas a createNotification)
```

## Sin cambios en Flutter
`lib/` no se modifica en esta fase. `dart analyze` y `flutter test` no aplican a este PR.

> Full detail: docs/exec-runs/rtm-push-notifications/handoffs/architect.md
