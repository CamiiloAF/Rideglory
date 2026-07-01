# REVIEW CHECKLIST — ws-cleanup-on-event-end

**Generado:** 2026-06-20T02:08:22Z

---

## Antes de commitear

### Automatizados (ya verificados por QA)

- [x] `dart analyze` — sin nuevas violaciones.
- [x] `flutter test` — 897/897 en verde.
- [x] `flutter test test/features/events/presentation/tracking/` — 9/9 (4 nuevos + 5 existentes).
- [x] `live_tracking_cubit_analytics_test.dart` no modificado y en verde.
- [x] `pubspec.yaml` sin cambios.
- [x] No se tocan contratos de dominio (`TrackingRepository` interface intacta).
- [x] No hay cambios en `rideglory-api`.

### Manuales recomendados

1. **Lista de eventos públicos:** Verificar que la pantalla de eventos públicos muestre eventos futuros por defecto (no históricos) después del cambio de `dateFrom` en `events_cubit.dart`.
2. **Integration tests bundle:** Revisar si `app_test.dart`, `events_patrol_test.dart`, `home_patrol_test.dart`, `profile_patrol_test.dart` están listos para CI antes de mergear. Si no, revertir los cambios en `integration_test/test_bundle.dart` o excluirlos del pipeline.
3. **Tracking end-to-end (opcional, post-deploy):**
   - Organizador inicia evento y riders se conectan con GPS activo.
   - Organizador finaliza evento desde la pantalla de tracking.
   - Verificar que la UI de riders muestra estado finalizado.
   - Verificar en logs del backend que no llegan pings de ubicación después del evento `tracking.event.ended`.

### Mensaje de commit sugerido

```
fix(tracking): cleanup GPS y WS al recibir tracking.event.ended

LiveTrackingCubit._subscribeToEventEnded ahora cancela la suscripción
GPS, invoca stopTrackingUseCase (cierra WS via leaveSession) y emite
isTracking=false, isFinished=true en orden correcto. Previene pings al
backend para eventos ya finalizados. 4 tests nuevos cubren path principal,
doble-disparo, sin sesión y fallo del use case.
```
