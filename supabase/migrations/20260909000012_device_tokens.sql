-- device_tokens: tokens FCM para push (inicio de rodada, cambio de ruta). Solo lo lee
-- service_role desde las Edge Functions; el dueño administra sus propios tokens.

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform public.device_platform not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

alter table public.device_tokens enable row level security;

create trigger set_device_tokens_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();

create policy device_tokens_select_own
  on public.device_tokens for select
  to authenticated
  using (user_id = auth.uid());

create policy device_tokens_insert_own
  on public.device_tokens for insert
  to authenticated
  with check (user_id = auth.uid());

create policy device_tokens_update_own
  on public.device_tokens for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy device_tokens_delete_own
  on public.device_tokens for delete
  to authenticated
  using (user_id = auth.uid());
