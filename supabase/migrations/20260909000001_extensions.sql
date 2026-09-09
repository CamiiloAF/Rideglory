-- Extensiones necesarias para el esquema de Rideglory.
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "pg_cron" with schema extensions;
create extension if not exists "pg_net" with schema extensions;

grant usage on schema cron to postgres;
grant all privileges on all tables in schema cron to postgres;
