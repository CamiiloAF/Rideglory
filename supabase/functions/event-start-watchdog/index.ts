// event-start-watchdog: invocada por pg_cron cada minuto. Busca eventos published cuyo start_at
// ya pasó y que el organizador nunca marcó como iniciados, y avisa por push a organizador e
// inscritos (D11 / P-09: que nadie descubra al final que el mapa nunca arrancó).
//
// Idempotencia: la marca start_reminder_sent_at se escribe con un UPDATE ... WHERE
// start_reminder_sent_at IS NULL, así que un reintento, un solapamiento o un redeploy del job
// nunca reenvía el mismo aviso. Solo se envía el push para los eventos cuyo UPDATE afectó filas.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { sendFcmPush } from '../_shared/fcm.ts';

Deno.serve(async (request) => {
  // Esta función solo la invoca pg_cron con el service role; no expone datos a un cliente final.
  const authHeader = request.headers.get('Authorization') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  if (authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: 'forbidden' }), { status: 403 });
  }

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, serviceRoleKey);

  const { data: dueEvents, error: dueEventsError } = await admin
    .from('events')
    .select('id, name, owner_id')
    .eq('state', 'published')
    .is('start_reminder_sent_at', null)
    .lte('start_at', new Date().toISOString());

  if (dueEventsError) {
    console.log(`watchdog_query_failed: ${dueEventsError.message}`);
    return new Response(JSON.stringify({ error: 'query_failed' }), { status: 500 });
  }

  let notified = 0;

  for (const event of dueEvents ?? []) {
    // Reclama el evento con un UPDATE condicional: si otra ejecución concurrente ya lo marcó,
    // count será 0 y este proceso no manda push duplicado.
    const { data: claimed, error: claimError } = await admin
      .from('events')
      .update({ start_reminder_sent_at: new Date().toISOString() })
      .eq('id', event.id)
      .is('start_reminder_sent_at', null)
      .select('id');

    if (claimError || !claimed || claimed.length === 0) {
      continue;
    }

    const recipientIds = new Set<string>([event.owner_id as string]);

    const { data: registrations } = await admin
      .from('event_registrations')
      .select('user_id')
      .eq('event_id', event.id)
      .eq('status', 'approved');

    for (const registration of registrations ?? []) {
      recipientIds.add(registration.user_id as string);
    }

    const { data: tokens } = await admin
      .from('device_tokens')
      .select('token')
      .in('user_id', Array.from(recipientIds));

    for (const deviceToken of tokens ?? []) {
      await sendFcmPush(
        deviceToken.token as string,
        'La rodada no ha iniciado',
        `"${event.name}" ya debería haber empezado y el organizador no la ha iniciado.`,
        { eventId: event.id as string, type: 'event_start_watchdog' },
      );
    }

    notified += 1;
  }

  return new Response(JSON.stringify({ notified }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
