// Cliente mínimo de FCM HTTP v1 para las Edge Functions de Rideglory.
// La service account vive SOLO como secret de Supabase (`supabase secrets set FCM_SERVICE_ACCOUNT_JSON=...`).
// Si el secret no está configurado (por ejemplo en local sin push real), se loguea y no se falla:
// el resto del flujo (escritura en Postgres, broadcast, etc.) no debe depender del push.

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

let cachedToken: { token: string; expiresAt: number } | null = null;

function base64UrlEncode(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 30) {
    return cachedToken.token;
  }

  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const unsignedJwt = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claimSet))}`;

  const keyData = serviceAccount.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsignedJwt),
  );

  const jwt = `${unsignedJwt}.${base64UrlEncode(new Uint8Array(signature))}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    throw new Error(`fcm_oauth_failed: ${await response.text()}`);
  }

  const json = await response.json();
  cachedToken = { token: json.access_token, expiresAt: now + json.expires_in };
  return json.access_token;
}

export interface PushResult {
  sent: boolean;
  reason?: string;
}

export async function sendFcmPush(
  token: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<PushResult> {
  const raw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
  if (!raw) {
    console.log('fcm_secret_missing: push omitido, no se falla el flujo principal');
    return { sent: false, reason: 'fcm_secret_missing' };
  }

  try {
    const serviceAccount: ServiceAccount = JSON.parse(raw);
    const accessToken = await getAccessToken(serviceAccount);

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data,
          },
        }),
      },
    );

    if (!response.ok) {
      console.log(`fcm_send_failed: ${await response.text()}`);
      return { sent: false, reason: 'fcm_send_failed' };
    }

    return { sent: true };
  } catch (error) {
    console.log(`fcm_send_error: ${error instanceof Error ? error.message : String(error)}`);
    return { sent: false, reason: 'fcm_send_error' };
  }
}
