// delete-account: borrado de cuenta dentro de la app (requisito de Apple y Google Play, y de la
// Ley 1581 de 2012). Anonimiza el perfil, borra vehículos/mantenimientos/documentos y sus
// objetos de Storage, CONSERVA consent_log (evidencia legal) y por último borra el usuario de
// auth.users con service_role. Valida auth.uid() antes de actuar: nunca confía en un user_id
// que venga en el body.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const authHeader = request.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'missing_authorization' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Cliente "como el usuario" solo para identificarlo a partir de su JWT. Nunca se usa
  // service_role para autenticar: eso validaría cualquier request, no solo al dueño del token.
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await callerClient.auth.getUser();
  if (userError || !userData?.user) {
    return jsonResponse({ error: 'invalid_session' }, 401);
  }

  const userId = userData.user.id;
  const admin = createClient(supabaseUrl, serviceRoleKey);

  try {
    const { data: vehicles } = await admin
      .from('vehicles')
      .select('id, image_path')
      .eq('owner_id', userId);

    const vehicleIds = (vehicles ?? []).map((vehicle) => vehicle.id as string);

    if (vehicleIds.length > 0) {
      const { data: documents } = await admin
        .from('vehicle_documents')
        .select('file_path')
        .in('vehicle_id', vehicleIds);

      const documentPaths = (documents ?? [])
        .map((document) => document.file_path as string | null)
        .filter((path): path is string => Boolean(path));
      if (documentPaths.length > 0) {
        await admin.storage.from('documents').remove(documentPaths);
      }

      await admin.from('vehicle_documents').delete().in('vehicle_id', vehicleIds);
      await admin.from('maintenances').delete().in('vehicle_id', vehicleIds);
    }

    const imagePaths = (vehicles ?? [])
      .map((vehicle) => vehicle.image_path as string | null)
      .filter((path): path is string => Boolean(path));
    if (imagePaths.length > 0) {
      await admin.storage.from('vehicle-images').remove(imagePaths);
    }

    await admin.from('vehicles').delete().eq('owner_id', userId);
    await admin.from('device_tokens').delete().eq('user_id', userId);

    // consent_log se conserva intacto: es evidencia legal, no tiene FK a auth.users, y nada en
    // este flujo lo toca.

    // Se anonimiza el perfil primero como defensa en profundidad (por si en el futuro la FK de
    // profiles hacia auth.users deja de tener ON DELETE CASCADE). Con el esquema actual, borrar
    // el usuario más abajo cascadea y elimina la fila de profiles por completo -- que es un
    // resultado igual de válido para "borrado real de datos" (Ley 1581 / requisitos de tienda):
    // no queda ni una fila con estos datos, en vez de quedar una fila con columnas en null.
    // event_registrations también cascadea con el usuario: su snapshot médico/de contacto no
    // debe sobrevivir al borrado de cuenta.
    await admin
      .from('profiles')
      .update({
        full_name: null,
        phone: null,
        birth_date: null,
        residence_city: null,
        eps: null,
        medical_insurance: null,
        blood_type: null,
        emergency_contact_name: null,
        emergency_contact_phone: null,
        deleted_at: new Date().toISOString(),
      })
      .eq('id', userId);

    const { error: deleteUserError } = await admin.auth.admin.deleteUser(userId);
    if (deleteUserError) {
      console.log(`delete_user_failed: ${deleteUserError.message}`);
      return jsonResponse({ error: 'delete_user_failed' }, 500);
    }

    return jsonResponse({ success: true }, 200);
  } catch (error) {
    console.log(`delete_account_error: ${error instanceof Error ? error.message : String(error)}`);
    return jsonResponse({ error: 'delete_account_failed' }, 500);
  }
});
