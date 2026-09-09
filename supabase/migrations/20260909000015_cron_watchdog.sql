-- Programa event-start-watchdog cada minuto vía pg_cron + pg_net.
--
-- NOTA sobre la service_role key hardcodeada abajo: es la clave DEMO fija que Supabase CLI usa
-- para TODO proyecto local (documentada en supabase/docs, idéntica en cualquier `supabase start`
-- de cualquier máquina) — no es un secreto de este proyecto. En producción, este job se
-- reconfigura para leer la key real desde Vault (`vault.create_secret` + `vault.decrypted_secrets`)
-- o desde un secret de Supabase; nunca se commitea una service_role key de producción. Queda
-- pendiente de verificación humana antes de ir a producción (ver informe de la corrida).
select
  cron.schedule(
    'event-start-watchdog',
    '* * * * *',
    $$
    select net.http_post(
      url := 'http://127.0.0.1:54321/functions/v1/event-start-watchdog',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU'
      ),
      body := '{}'::jsonb
    );
    $$
  );
