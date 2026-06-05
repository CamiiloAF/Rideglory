# Auditoría Backend — rtm-push-notifications

**Auditor:** Opus
**Generado:** 2026-06-05T00:16:35Z
**Resultado:** APROBADO (score 95/100)

## AC cubiertos
1. ✅ 3 NotificationType RTM presentes e idénticos en api-gateway y notifications-ms.
2. ✅ Helper único `sendDocumentExpiryReminders(kind, days, type)`; `sendSoatReminders` eliminado.
3. ✅ Crons SOAT vivos, reapuntados al helper genérico; payload observable idéntico (route + type). Tests de regresión lo verifican.
4. ✅ 3 crons RTM nuevos, `0 9 * * *`, timeZone America/Bogota, RPC findTecnomecanicasExpiringIn con days 30/7/0.
5. ✅ route 'rideglory://garage' + type RTM correcto en createNotification y sendFcm.
6. ✅ Copy RTM propio (revisión técnico-mecánica), distinto de SOAT, varía por umbral.
7. ✅ notifications.service.spec cubre payload de los 3 tipos RTM (vehicleId, vehicleName, route, type) sin alterar assertions SOAT.
8. ✅ Crons RTM con fixtures 30/7/0 + guard lista-vacía (no createNotification/sendFcm).
9. ✅ Suite api-gateway 71/71 verde; tsc --noEmit limpio en api-gateway y notifications-ms.

## Verificaciones
- Prerequisito Fase 2: RPC findTecnomecanicasExpiringIn existe en vehicles-ms (controller L127).
- findOneUser usa vehicle.ownerId (L326) correctamente.
- Sin secretos, sin URLs HTTP hardcodeadas, sin SQL concatenado.
- Sin cambios en Flutter lib/ por este change.
- Tests llaman a métodos reales del servicio (no literales auto-afirmados); sabotaje confirmado por el agente.

## Findings menores (no bloqueantes)
- El mapa `messages` se reconstruye en cada invocación del helper dentro del método; podría elevarse a constante de módulo. Cosmético.
- Tests SOAT/RTM comparten fragmentos "30 días"/"7 días"/"hoy"; el test "body no menciona RTM" mitiga colisión SOAT↔RTM correctamente.
- .DS_Store quedó modificado en el working tree del repo padre (ruido, no parte del change).
