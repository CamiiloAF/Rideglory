// notify-route-change: invocada por un Database Webhook al insertar en event_route_changes.
// Manda push a los inscritos aprobados del evento. Idempotente por construcción: el webhook
// dispara una vez por fila insertada y event_route_changes no admite UPDATE, así que no hay
// forma de reprocesar la misma fila dos veces salvo un reintento de red del propio webhook —
// para ese caso se soporta reenvío seguro: enviar el mismo push dos veces ante un reintento de
// entrega no es un duplicado de producto, es el mismo aviso confirmándose.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { sendFcmPush } from '../_shared/fcm.ts';

interface RouteChangeRow {
  id: string;
  event_id: string;
  message: string;
}

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: RouteChangeRow;
}

Deno.serve(async (request) => {
  const authHeader = request.headers.get('Authorization') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  if (authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403 });
  }

  const payload = (await request.json()) as WebhookPayload;
  if (payload.table !== 'event_route_changes' || payload.type !== 'INSERT') {
    return new Response(JSON.stringify({ ignored: true }), { status: 200 });
  }

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, serviceRoleKey);
  const { record } = payload;

  const { data: event } = await admin
    .from('events')
    .select('name')
    .eq('id', record.event_id)
    .single();

  const { data: registrations } = await admin
    .from('event_registrations')
    .select('user_id')
    .eq('event_id', record.event_id)
    .eq('status', 'approved');

  const userIds = (registrations ?? []).map((registration) => registration.user_id as string);
  if (userIds.length === 0) {
    return new Response(JSON.stringify({ notified: 0 }), { status: 200 });
  }

  const { data: tokens } = await admin
    .from('device_tokens')
    .select('token')
    .in('user_id', userIds);

  let notified = 0;
  for (const deviceToken of tokens ?? []) {
    const result = await sendFcmPush(
      deviceToken.token as string,
      `Cambio de ruta: ${event?.name ?? 'tu rodada'}`,
      record.message,
      { eventId: record.event_id, type: 'route_change' },
    );
    if (result.sent) notified += 1;
  }

  return new Response(JSON.stringify({ notified }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
