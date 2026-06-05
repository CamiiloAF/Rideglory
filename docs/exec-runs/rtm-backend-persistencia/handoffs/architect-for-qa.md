> Slim handoff — read this before docs/exec-runs/rtm-backend-persistencia/handoffs/architect.md

# Architect → QA

## Repo bajo prueba
`/Users/cami/Developer/Personal/rideglory-api` — paquete `vehicles-ms`

## Comandos de test
```bash
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
npm test                         # suite completa (jest)
npm test -- --testPathPattern=tecnomecanica   # solo RTM
npm test -- --testPathPattern=soat            # regresión SOAT (debe verde)
npm run build                    # TypeScript sin errores
```

```bash
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npm run build                    # TypeScript sin errores
```

## Criterios de aceptación a verificar

| # | Criterio | Verificación |
|---|----------|--------------|
| 1 | `model Tecnomecanica` existe en schema con campos correctos | `grep -A15 "model Tecnomecanica" vehicles-ms/prisma/schema.prisma` |
| 2 | Migración crea `Tecnomecanica` sin alterar `Soat` | Revisar SQL de la migración generada |
| 3 | Rutas REST protegidas por Firebase Auth | Llamar sin token → 401/403 |
| 4 | `validateVehicleOwnership` en upsert/find/delete | Usuario no-dueño → 403 en las 3 operaciones |
| 5 | `400` cuando `expiryDate <= startDate` | Test unitario cubriendo este caso |
| 5b | Acepta body sin `startDate` | Test unitario: upsert sin startDate → persistido |
| 6 | `GET /tecnomecanica` → 404 cuando no existe | Verificar que el gateway lanza NotFoundException (no retorna null) |
| 7 | `DELETE /tecnomecanica` → 404 si no hay RTM; `{ success: true }` si borra | Tests unitarios + build |
| 8 | DTO rechaza body sin `certificateNumber`, `cdaName` o `expiryDate` | Test unitario o e2e |
| 9 | `findTecnomecanicasExpiringIn` usa ventana UTC día-exacto | Test unitario de lógica de ventana |
| 10 | `tecnomecanica.service.spec.ts` pasa verde | `npm test -- --testPathPattern=tecnomecanica` |
| 11 | Build TS sin errores nuevos | `npm run build` en ambos paquetes |
| 12 | Suite SOAT sigue verde | `npm test -- --testPathPattern=soat` |
| 13 | Gate: migración local validada por humano | No automatizable |

## Regresión crítica
- `soat.service.spec.ts` — debe seguir verde sin modificaciones.
- `model Soat` en schema — sin cambios (diff de schema solo añade líneas).
- Rutas REST SOAT — sin cambios funcionales.
- No se añadió `NotificationType` ni cron en esta fase.

> Full detail: docs/exec-runs/rtm-backend-persistencia/handoffs/architect.md
