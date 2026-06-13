# ENV Delta — observability-sentry-phase01

**Generado (UTC):** 2026-06-11T19:21:19Z

---

## Variables nuevas

| Variable | Servicio(s) | Descripción | Ejemplo | Joi validation |
|----------|-------------|-------------|---------|----------------|
| `NODE_ENV` | api-gateway, users-ms, events-ms, vehicles-ms, maintenances-ms, notifications-ms | Controla formato de logs. `production` → JSON; cualquier otro valor → pino-pretty (legible). | `production` | NO en fase 1. Se añade en Fase 2 junto con `SENTRY_DSN`. |

## Notas operativas

- `NODE_ENV` ya existe en el ambiente Docker/EC2 de producción. No requiere añadirlo a `.env` local; solo verificar que el runtime Docker lo inyecte.
- `pino-pretty` es una dependencia de runtime en dev (`devDependency`). En prod no se instala si la imagen usa `npm install --omit=dev`. La factory `loggerOptions()` debe omitir `transport: { target: 'pino-pretty' }` cuando `NODE_ENV === 'production'` para evitar un crash al intentar requerir el módulo.
- Recomendación: mover `pino-pretty` a `devDependencies` en los `package.json` de los 6 servicios; esto reduce el tamaño de la imagen de producción.

## Variables NO añadidas en esta fase (reservadas para Fase 2)

| Variable | Fase |
|----------|------|
| `SENTRY_DSN` | Fase 2 |
| Cualquier `OTEL_*` | Fuera de las 3 fases actuales |
