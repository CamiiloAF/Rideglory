# REVIEW CHECKLIST — rtm-push-notifications

**Tech Lead:** 2026-06-05T00:24:38Z

## Antes de commitear (backend)

- [ ] `cd /Users/cami/Developer/Personal/rideglory-api/api-gateway && npm test` → 71/71 verde
- [ ] `cd /Users/cami/Developer/Personal/rideglory-api/api-gateway && npx tsc --noEmit` → sin errores
- [ ] Verificar que `TECNOMECANICA_30D | TECNOMECANICA_7D | TECNOMECANICA_DAY_OF` están en AMBOS archivos:
  - `api-gateway/src/notifications/notifications.service.ts`
  - `notifications-ms/src/notifications/notifications.service.ts`
- [ ] Verificar que `sendSoatReminders` NO existe en `notification-scheduler.service.ts` (grep debe devolver vacío)
- [ ] Verificar que los 3 crons SOAT (`soatReminder30Days/7Days/DayOf`) siguen presentes y usan `sendDocumentExpiryReminders('soat', ...)`

## Antes de commitear (Flutter)

- [ ] `dart analyze lib/` → No issues found
- [ ] Probar flujo de **creación de vehículo con RTM**:
  1. Iniciar creación de vehículo
  2. En sección de documentos, tocar "Revisión técnico-mecánica"
  3. Completar datos en `TecnomecanicaManualCapturePage`
  4. Volver al formulario → la tarjeta muestra "Datos agregados"
  5. Guardar vehículo → confirmar que la RTM queda guardada en backend
- [ ] Probar flujo de **edición de vehículo**:
  1. Abrir edición de vehículo existente
  2. El slot RTM carga estado real (válido/por vencer/vencido) desde API
  3. Al tocar: sin RTM → navega a captura; con RTM → navega a pantalla de estado
- [ ] Verificar que documentos vencidos muestran "Venció hace N días" (no fecha)
- [ ] Verificar plural: "Venció hace 1 día" (singular correcto)

## Staging (post-deploy backend)

- [ ] Poblar `Tecnomecanica` con `expiryDate = hoy + 30 días` → invocar `tecnomecanicaReminder30Days()` → verificar `type='TECNOMECANICA_30D'` en tabla `Notification` y push FCM con título "Tu RTM vence en 30 días"
- [ ] Repetir para 7 días y día-of
- [ ] Invocar crons SOAT → payload idéntico al anterior al refactor (regresión cero)
- [ ] Tocar notificación RTM en app → navega a Garage (`rideglory://garage`)
- [ ] Lista vacía (`Tecnomecanica` vacía) → invocar cron → no se crean notificaciones
