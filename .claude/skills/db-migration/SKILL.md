---
name: db-migration
description: Guia y ejecuta un cambio seguro al esquema Postgres de Supabase de Rideglory (tabla, columna, indice, constraint, vista), delegando en sql-migration-helper, y confirma lo que no se puede dar por hecho - politicas RLS, indices, tipos regenerados, rollback y que la app siga compilando.
---

# db-migration

Uso: `/db-migration <descripcion del cambio>` (ej. `/db-migration anadir columna "notes" a maintenance_records`).

## Antes de empezar

**Nunca contra produccion.** El desarrollo y la verificacion van contra Supabase local (`supabase start`, `supabase db reset`). Si aparece un `supabase db push`, un `supabase link` o cualquier comando apuntando al proyecto remoto, detente y avisale al usuario: aplicar la migracion en produccion es una decision suya, no de este flujo.

## Pasos

1. Si no hay descripcion suficiente, pregunta que tabla/columna se anade, modifica o elimina, con nombre y tipo. No inventes el cambio.
2. Delega a `sql-migration-helper` (via Agent, subagent_type: `sql-migration-helper`), describiendole exactamente el cambio pedido y quien debe poder leerlo y escribirlo (eso determina las politicas).
3. Cuando el subagente termine, **confirma explicitamente** — cada punto es una omision que ya ha costado caro en proyectos asi, no un tramite:
   - **RLS.** La tabla tiene RLS habilitado y politicas que expresan quien ve que. En Rideglory el acceso vive en la base, nunca en el cliente: una tabla nueva sin politicas o con RLS apagado es una fuga, aunque hoy solo la consulte una pantalla. Si el cambio toca datos sensibles (ubicacion, contactos de emergencia, datos medicos, fotos de documentos con placa), el **enmascarado se hace aqui, con politicas y vistas** — filtrar el campo en Dart no cuenta, porque el dato ya viajo.
   - **Indices.** Las columnas por las que se filtra u ordena de verdad (usuario, evento, fecha) estan indexadas.
   - **Convenciones**: PKs UUID, timestamps (`created_at` / `updated_at`), tipos correctos, y los timestamps de consentimiento sellados por el servidor, nunca por el cliente.
   - **Rollback.** Toda migracion destructiva (drop de tabla o columna, cambio de tipo con perdida) trae su checklist de rollback escrito. Si no lo trae, pidelo antes de seguir.
   - **Tipos regenerados y app compilando.** Los tipos de Supabase se regeneraron y `dart analyze` sale limpio. Un cambio de esquema que rompe los DTOs en `data/` no esta terminado.
   - **Verificado en local**: `supabase db reset` corre la migracion desde cero sin errores.
4. Si el cambio afecta una tabla que ya tiene features construidas encima (`lib/features/*`), advierte cuales carpetas probablemente necesiten actualizarse (DTOs y datasources en `data/`, modelos en `domain/`) en vez de asumir que siguen compilando.
5. Cierra diciendole al usuario que la migracion quedo escrita y verificada **en local y sin commitear**, y que aplicarla en el proyecto remoto es paso suyo.

## Notas

- Si el cambio necesita ademas logica server-side (Edge Function, `pg_cron`, canal de Realtime, politica de Storage, push FCM), eso es `supabase-backend-dev`, no este flujo. Dilo como pendiente en vez de improvisarlo.
- El backend de Rideglory **es** Supabase: no hay NestJS, ni Firestore, ni servidor propio. Si el cambio pedido asume alguno de esos, aclaralo antes de escribir SQL.
