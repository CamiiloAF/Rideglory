# Review Checklist — rtm-backend-persistencia
Generated: 2026-06-04T17:50:58Z

Pasos manuales a completar antes de hacer commit. Los puntos marcados con (AUTO) se verificaron automáticamente por QA/TechLead.

---

## 1. Verificar tests (AUTO)

- [ ] `cd vehicles-ms && npx jest --testPathPatterns=tecnomecanica` → 18/18 verde
- [ ] `cd vehicles-ms && npx jest --testPathPatterns=soat` → 9/9 verde (regresión)

## 2. Verificar build TS (AUTO)

- [ ] `cd vehicles-ms && npm run build` → exit 0
- [ ] `cd api-gateway && npm run build` → exit 0

## 3. Verificar migración local (GATE HUMANO)

- [ ] `cd vehicles-ms && npx prisma migrate deploy` contra DB local confirma que la tabla `Tecnomecanica` fue creada
- [ ] `psql ... -c "\dt"` lista: `Soat`, `Tecnomecanica`, `Vehicle`, `_prisma_migrations`
- [ ] Diff de `schema.prisma` solo añade líneas; `model Soat` queda intacto

## 4. Prueba manual: Auth guard (sin token → 401)

- [ ] Levantar api-gateway localmente
- [ ] `curl -X POST http://localhost:3000/api/vehicles/<uuid>/tecnomecanica -H "Content-Type: application/json" -d '{"certificateNumber":"CRT","cdaName":"CDA","expiryDate":"2027-01-01"}'`
- [ ] Respuesta esperada: `401 Unauthorized`

## 5. Prueba manual: validateVehicleOwnership (no-dueño → 403)

- [ ] Autenticado como usuario A, hacer `GET /api/vehicles/<vehicleId-de-usuario-B>/tecnomecanica` con token de A
- [ ] Respuesta esperada: `403 Forbidden`

## 6. Prueba manual: GET 404 cuando no existe RTM

- [ ] Con token válido del dueño, `GET /api/vehicles/<vehicleId-sin-rtm>/tecnomecanica`
- [ ] Respuesta esperada: `404 Not Found` (no `200` con body `null`)

## 7. Prueba manual: POST upsert + GET + DELETE (happy path)

- [ ] `POST /api/vehicles/:vehicleId/tecnomecanica` con body válido → `201` + objeto persistido
- [ ] `GET /api/vehicles/:vehicleId/tecnomecanica` → `200` + mismo objeto
- [ ] `DELETE /api/vehicles/:vehicleId/tecnomecanica` → `200` + `{ success: true }`
- [ ] `GET /api/vehicles/:vehicleId/tecnomecanica` → `404` (ya no existe)

## 8. Verificar regresión SOAT

- [ ] `GET /api/vehicles/:vehicleId/soat` sin RTM devuelve `200` con body `null` (comportamiento SOAT sin cambios)
- [ ] `POST/DELETE /api/vehicles/:vehicleId/soat` siguen funcionando igual

## 9. Migración remota (fuera de scope de esta fase — responsabilidad humana)

- [ ] Antes del deploy a producción, ejecutar `prisma migrate deploy` en el servidor remoto
- [ ] Verificar que `Tecnomecanica` aparece en la DB de producción
- [ ] Verificar que `Soat` no fue alterada
