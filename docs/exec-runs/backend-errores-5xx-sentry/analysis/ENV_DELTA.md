# ENV Delta — backend-errores-5xx-sentry

**Generado:** 2026-06-11T22:22:09Z

## Variables nuevas (×6 servicios: api-gateway, users-ms, events-ms, vehicles-ms, maintenances-ms, notifications-ms)

| Variable | joi schema | Default | Descripción |
|----------|-----------|---------|-------------|
| `SENTRY_DSN` | `joi.string().uri().optional()` | — | DSN del proyecto Sentry único. Si está ausente, `initSentry` no inicializa el SDK y el servicio arranca normalmente. |
| `SENTRY_TRACES_SAMPLE_RATE` | `joi.number().min(0).max(1).optional()` | `0.1` (prod) | Fracción de traces enviados a Sentry. Controla volumen en cuota free (5k errores/mes). |
| `SENTRY_DEV_VERIFY` | `joi.string().optional()` | — | Palanca temporal. `'true'` habilita Sentry cuando `NODE_ENV !== 'production'`. Eliminar al cerrar las fases Sentry (no debe llegar al PR final de cierre). |

## Variables NO modificadas

Ninguna variable existente se renombra, elimina o cambia de tipo.

## Notas de despliegue

- Las 3 vars son **opcionales** — dev local no requiere ninguna.
- En producción: inyectar `SENTRY_DSN` via secrets manager (no commitear en `.env`).
- `SENTRY_DEV_VERIFY` solo para entornos de staging durante el rollout; nunca en producción persistente.
- `SENTRY_TRACES_SAMPLE_RATE=0.1` recomendado para inicio; ajustar según volumen real de traces.
