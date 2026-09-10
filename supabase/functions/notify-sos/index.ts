// notify-sos: invocada por un Database Webhook al insertar en sos_alerts. Manda push a todos
// los tokens del organizador y de los inscritos aprobados del evento, EXCEPTO el emisor del SOS
// (quien lo emitió ya lo sabe). Es la tercera pata del SOS junto con la escritura durable en
// Postgres y el broadcast por Realtime del canal del evento (CLAUDE.md regla 6): el SOS nunca
// viaja solo como mensaje efímero.
//
// Idempotencia: raise_sos es idempotente por client_id (un reintento del cliente nunca inserta
// una segunda fila para el mismo SOS), así que el webhook solo dispara una vez por SOS real. Un
// reintento de ENTREGA del webhook (por ejemplo si esta función no respondió a tiempo) puede
// volver a mandar el mismo push -- eso no es un duplicado de producto, es el mismo aviso
// confirmándose, igual que en notify-route-change.
//
// Configuración del webhook (igual que notify-route-change): Supabase Studio > Database >
// Webhooks > Create a new hook. Tabla: sos_alerts. Evento: INSERT. Tipo: HTTP Request a esta
// función, con el header Authorization: Bearer <service_role key> (el mismo patrón que usa
// event-start-watchdog vía pg_cron/pg_net; aquí el disparador es el webhook, no un cron). En
// producción, configurar con `supabase functions deploy notify-sos` y crear el webhook desde el
// dashboard del proyecto (no hay CLI declarativo para Database Webhooks todavía).

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { sendFcmPush } from '../_shared/fcm.ts';

interface SosAlertRow {
  id: string;
  event_id: string;
  user_id: string;
}

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: SosAlertRow;
}

Deno.serve(async (request) => {
  const authHeader = request.headers.get('Authorization') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  if (authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403 });
  }

  const payload = (await request.json()) as WebhookPayload;
  if (payload.table !== 'sos_alerts' || payload.type !== 'INSERT') {
    return new Response(JSON.stringify({ ignored: true }), { status: 200 });
  }

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, serviceRoleKey);
  const { record } = payload;

  const { data: event } = await admin
    .from('events')
    .select('name, owner_id')
    .eq('id', record.event_id)
    .single();

  const { data: sender } = await admin
    .from('profiles')
    .select('full_name')
    .eq('id', record.user_id)
    .single();

  const { data: registrations } = await admin
    .from('event_registrations')
    .select('user_id')
    .eq('event_id', record.event_id)
    .eq('status', 'approved');

  const recipientIds = new Set<string>((registrations ?? []).map((r) => r.user_id as string));
  if (event?.owner_id) {
    recipientIds.add(event.owner_id as string);
  }
  recipientIds.delete(record.user_id);

  if (recipientIds.size === 0) {
    return new Response(JSON.stringify({ notified: 0 }), { status: 200 });
  }

  const { data: tokens } = await admin
    .from('device_tokens')
    .select('token')
    .in('user_id', Array.from(recipientIds));

  const senderName = (sender?.full_name as string | undefined) ?? 'Un rider';
  const eventName = (event?.name as string | undefined) ?? 'la rodada';

  let notified = 0;
  for (const deviceToken of tokens ?? []) {
    const result = await sendFcmPush(
      deviceToken.token as string,
      `SOS · ${senderName}`,
      `${senderName} pidió ayuda en ${eventName}`,
      { type: 'sos', event_id: record.event_id, sos_id: record.id },
    );
    if (result.sent) notified += 1;
  }

  return new Response(JSON.stringify({ notified }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
