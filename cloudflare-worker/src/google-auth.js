// Google service-account OAuth 2 authentication for Cloudflare Workers.
// Produces short-lived access tokens used by firestore.js and FCM calls.

let cachedToken = null;
let tokenExpiry = 0;

// Parses the service-account JSON stored in FIREBASE_SERVICE_ACCOUNT_KEY.
// Cloudflare dashboard sometimes stores the secret with literal newlines (0x0A)
// inside the private_key PEM block instead of the JSON escape sequence \n,
// which makes JSON.parse throw "Unterminated string". Detect and fix that case.
function parseServiceAccountKey(raw) {
  if (!raw) {
    throw new Error(
      '[google-auth] FIREBASE_SERVICE_ACCOUNT_KEY is not set. ' +
        'Add it with: wrangler secret put FIREBASE_SERVICE_ACCOUNT_KEY < /path/to/service-account.json',
    );
  }
  try {
    return JSON.parse(raw);
  } catch (firstErr) {
    // Attempt recovery: re-escape any literal newlines inside the PEM block.
    try {
      const normalized = raw.replace(
        /(-----BEGIN [A-Z ]+ KEY-----)([\s\S]*?)(-----END [A-Z ]+ KEY-----)/,
        (_, begin, body, end) => begin + body.replace(/\r?\n/g, '\\n') + end,
      );
      return JSON.parse(normalized);
    } catch {
      throw new Error(
        `[google-auth] FIREBASE_SERVICE_ACCOUNT_KEY is not valid JSON: ${firstErr.message}. ` +
          'Upload the exact service-account file with: ' +
          'wrangler secret put FIREBASE_SERVICE_ACCOUNT_KEY < /path/to/service-account.json',
      );
    }
  }
}

function base64urlEncode(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function textToBase64url(text) {
  return base64urlEncode(new TextEncoder().encode(text));
}

async function importPrivateKey(pemKey) {
  const pemBody = pemKey
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');

  const binaryDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  return crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

async function createSignedJwt(email, privateKeyPem, scopes) {
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: email,
    sub: email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: scopes,
  };

  const signingInput = `${textToBase64url(JSON.stringify(header))}.${textToBase64url(JSON.stringify(payload))}`;
  const key = await importPrivateKey(privateKeyPem);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64urlEncode(signature)}`;
}

async function getAccessToken(env) {
  if (cachedToken && Date.now() < tokenExpiry) {
    return cachedToken;
  }

  const sa = parseServiceAccountKey(env.FIREBASE_SERVICE_ACCOUNT_KEY);
  const scopes =
    'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/identitytoolkit';

  const jwt = await createSignedJwt(sa.client_email, sa.private_key, scopes);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`OAuth2 token exchange failed: ${res.status} ${body}`);
  }

  const data = await res.json();
  cachedToken = data.access_token;
  tokenExpiry = Date.now() + (data.expires_in - 120) * 1000;
  return cachedToken;
}

export { getAccessToken };
