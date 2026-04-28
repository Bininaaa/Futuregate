const BUCKET_NAME = "avenirdz-files";
const FIREBASE_PROJECT_ID = "avenirdz-7305d";

const GOOGLE_JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const FIREBASE_ISSUER = `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;
const MAX_CV_BYTES = 10 * 1024 * 1024;
const MAX_COMMERCIAL_REGISTER_BYTES = 10 * 1024 * 1024;
const MAX_PROFILE_PHOTO_BYTES = 5 * 1024 * 1024;
const MAX_PROJECT_IDEA_IMAGE_BYTES = 5 * 1024 * 1024;
const MAX_CHAT_IMAGE_BYTES = 10 * 1024 * 1024;
const MAX_CHAT_FILE_BYTES = 20 * 1024 * 1024;
const DEFAULT_ALLOWED_ORIGINS = [
  "https://futuregate.tech",
  "https://www.futuregate.tech",
  "https://admin.futuregate.tech",
  "https://avenirdz-7305d.web.app",
  "https://avenirdz-7305d.firebaseapp.com",
  "https://avenirdz-7305d-admin.web.app",
  "https://avenirdz-7305d-admin.firebaseapp.com",
];

let cachedJwks = null;
let jwksCachedAt = 0;
const JWKS_CACHE_TTL_MS = 3600_000;

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: buildCorsHeaders(request, env),
      });
    }

    if (isDisallowedOrigin(request, env)) {
      return jsonResponse(
        request,
        env,
        {
          success: false,
          error: "Origin is not allowed.",
        },
        403,
      );
    }

    try {
      const url = new URL(request.url);

      if (request.method === "POST" && url.pathname === "/upload") {
        return await handleUpload(request, env, url);
      }

      if (url.pathname.startsWith("/file/")) {
        const objectKey = getObjectKeyFromPath(url.pathname);
        if (!objectKey) {
          return jsonResponse(
            request,
            env,
            {
              success: false,
              error: "File key is required.",
            },
            400,
          );
        }

        if (request.method === "GET") {
          return await handleGetFile(request, env, objectKey);
        }

        if (request.method === "DELETE") {
          const authResult = await verifyFirebaseToken(request);
          if (!authResult.valid) {
            return jsonResponse(
              request,
              env,
              { success: false, error: authResult.error },
              401,
            );
          }
          return await handleDeleteFile(request, env, objectKey, authResult);
        }
      }

      return jsonResponse(
        request,
        env,
        {
          success: false,
          error: "Route not found.",
        },
        404,
      );
    } catch (error) {
      return jsonResponse(
        request,
        env,
        {
          success: false,
          error: error instanceof Error ? error.message : "Unexpected error.",
        },
        500,
      );
    }
  },
};

// ── Auth ─────────────────────────────────────────────────────────────────

async function verifyFirebaseToken(request) {
  const authHeader = request.headers.get("Authorization") || "";
  if (!authHeader.startsWith("Bearer ")) {
    return {
      valid: false,
      uid: null,
      error: "Missing or invalid Authorization header.",
    };
  }

  const token = authHeader.slice(7).trim();
  if (!token) {
    return { valid: false, uid: null, error: "Empty bearer token." };
  }

  try {
    const parts = token.split(".");
    if (parts.length !== 3) {
      return { valid: false, uid: null, error: "Malformed JWT." };
    }

    const headerJson = JSON.parse(base64UrlDecode(parts[0]));
    const payloadJson = JSON.parse(base64UrlDecode(parts[1]));

    if (headerJson.alg !== "RS256") {
      return { valid: false, uid: null, error: "Unsupported algorithm." };
    }

    const kid = headerJson.kid;
    if (!kid) {
      return { valid: false, uid: null, error: "Missing key ID in token." };
    }

    const now = Math.floor(Date.now() / 1000);

    if (!payloadJson.exp || payloadJson.exp < now) {
      return { valid: false, uid: null, error: "Token has expired." };
    }
    if (!payloadJson.iat || payloadJson.iat > now + 60) {
      return { valid: false, uid: null, error: "Token issued in the future." };
    }
    if (payloadJson.iss !== FIREBASE_ISSUER) {
      return { valid: false, uid: null, error: "Invalid token issuer." };
    }
    if (payloadJson.aud !== FIREBASE_PROJECT_ID) {
      return { valid: false, uid: null, error: "Invalid token audience." };
    }
    if (
      !payloadJson.sub ||
      typeof payloadJson.sub !== "string" ||
      payloadJson.sub.length === 0
    ) {
      return { valid: false, uid: null, error: "Invalid token subject." };
    }

    const jwks = await fetchJwks();
    const matchingKey = jwks.keys.find((k) => k.kid === kid);
    if (!matchingKey) {
      cachedJwks = null;
      const refreshedJwks = await fetchJwks();
      const retryKey = refreshedJwks.keys.find((k) => k.kid === kid);
      if (!retryKey) {
        return {
          valid: false,
          uid: null,
          error: "Token signing key not found.",
        };
      }
      return await verifySignature(token, parts, retryKey, payloadJson);
    }

    return await verifySignature(token, parts, matchingKey, payloadJson);
  } catch (e) {
    return {
      valid: false,
      uid: null,
      error: `Token verification failed: ${e.message || "unknown error"}`,
    };
  }
}

async function verifySignature(token, parts, jwk, payloadJson) {
  try {
    const cryptoKey = await crypto.subtle.importKey(
      "jwk",
      jwk,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["verify"],
    );

    const signedData = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const signature = base64UrlDecodeToBuffer(parts[2]);

    const valid = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
      signature,
      signedData,
    );

    if (!valid) {
      return { valid: false, uid: null, error: "Invalid token signature." };
    }

    return { valid: true, uid: payloadJson.sub, error: null };
  } catch (e) {
    return {
      valid: false,
      uid: null,
      error: `Signature verification error: ${e.message || "unknown"}`,
    };
  }
}

async function fetchJwks() {
  const now = Date.now();
  if (cachedJwks && now - jwksCachedAt < JWKS_CACHE_TTL_MS) {
    return cachedJwks;
  }

  const response = await fetch(GOOGLE_JWKS_URL);
  if (!response.ok) {
    throw new Error("Failed to fetch Google public keys.");
  }

  cachedJwks = await response.json();
  jwksCachedAt = now;
  return cachedJwks;
}

function base64UrlDecode(str) {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (padded.length % 4)) % 4);
  return atob(padded + padding);
}

function base64UrlDecodeToBuffer(str) {
  const binary = base64UrlDecode(str);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

// ── Upload ───────────────────────────────────────────────────────────────

async function handleUpload(request, env, url) {
  const authResult = await verifyFirebaseToken(request);
  if (!authResult.valid) {
    return jsonResponse(
      request,
      env,
      { success: false, error: authResult.error },
      401,
    );
  }

  const verifiedUid = authResult.uid;

  const contentType = request.headers.get("content-type") || "";
  if (!contentType.includes("multipart/form-data")) {
    return jsonResponse(
      request,
      env,
      {
        success: false,
        error: "Expected multipart/form-data upload.",
      },
      415,
    );
  }

  const formData = await request.formData();
  const file = formData.get("file");
  if (!(file instanceof File)) {
    return jsonResponse(
      request,
      env,
      {
        success: false,
        error: 'A file field named "file" is required.',
      },
      400,
    );
  }

  const fileType = normalizeString(formData.get("fileType")) || "original_cv";
  const templateId = normalizeString(formData.get("templateId"));
  const userId = sanitizeSegment(verifiedUid);
  const rawFileName = normalizeString(formData.get("fileName")) || file.name;
  const fileName = sanitizeFileName(
    rawFileName || buildDefaultFileName(fileType, templateId),
  );
  const mimeType = normalizeMimeType({
    requestedMimeType: normalizeString(formData.get("mimeType")),
    fileMimeType: file.type,
    fileName,
  });
  const uploadValidationError = validateUploadRequest({
    fileType,
    fileName,
    mimeType,
    fileSize: file.size,
  });
  if (uploadValidationError) {
    return jsonResponse(
      request,
      env,
      {
        success: false,
        error: uploadValidationError,
      },
      400,
    );
  }
  const objectKey = buildObjectKey({
    userId,
    fileType,
    fileName,
  });

  await env.FILES_BUCKET.put(objectKey, await file.arrayBuffer(), {
    httpMetadata: {
      contentType: mimeType,
    },
    customMetadata: {
      userId,
      fileType,
      templateId: templateId || "",
      originalFileName: fileName,
      uploadedAt: new Date().toISOString(),
    },
  });

  const accessPath = `/file/${encodeObjectKey(objectKey)}`;

  return jsonResponse(request, env, {
    success: true,
    objectKey,
    bucketName: BUCKET_NAME,
    fileName,
    mimeType,
    sizeOriginal: file.size,
    fileType,
    accessPath,
    url: `${url.origin}${accessPath}`,
  });
}

// ── File ops ─────────────────────────────────────────────────────────────

async function handleGetFile(request, env, objectKey) {
  const object = await env.FILES_BUCKET.get(objectKey);
  if (!object) {
    return jsonResponse(
      request,
      env,
      {
        success: false,
        error: "File not found.",
      },
      404,
    );
  }

  const url = new URL(request.url);

  // Public-facing assets can be served directly so they render in feeds and
  // detail pages without an authenticated fetch.
  const isPublicAsset =
    objectKey.startsWith("profiles/") || objectKey.startsWith("ideas/");

  if (!isPublicAsset) {
    const ownerId = resolveOwnerId(objectKey, object.customMetadata);
    const signedAccessAllowed = await verifySignedAccess({
      env,
      objectKey,
      expires: url.searchParams.get("expires"),
      signature: url.searchParams.get("signature"),
    });

    let ownerAccessAllowed = false;
    const authHeader = request.headers.get("Authorization") || "";
    if (!signedAccessAllowed && authHeader.startsWith("Bearer ")) {
      const authResult = await verifyFirebaseToken(request);
      ownerAccessAllowed =
        authResult.valid &&
        ownerId &&
        sanitizeSegment(authResult.uid) === ownerId;
    }

    if (!signedAccessAllowed && !ownerAccessAllowed) {
      return jsonResponse(
        request,
        env,
        {
          success: false,
          error: "You do not have permission to access this file.",
        },
        403,
      );
    }
  }

  const headers = new Headers(buildCorsHeaders(request, env));
  headers.set(
    "Content-Type",
    object.httpMetadata?.contentType || "application/octet-stream",
  );
  headers.set("ETag", object.httpEtag);
  headers.set(
    "Cache-Control",
    isPublicAsset ? "public, max-age=3600" : "private, max-age=60",
  );

  const fileName =
    object.customMetadata?.originalFileName ||
    objectKey.split("/").pop() ||
    "file";
  const disposition =
    url.searchParams.get("download") == "1" ? "attachment" : "inline";
  headers.set(
    "Content-Disposition",
    `${disposition}; filename="${sanitizeHeaderValue(fileName)}"`,
  );

  return new Response(object.body, {
    status: 200,
    headers,
  });
}

async function handleDeleteFile(request, env, objectKey, authResult) {
  const object = await env.FILES_BUCKET.get(objectKey);
  if (!object) {
    return jsonResponse(
      request,
      env,
      {
        success: false,
        error: "File not found.",
      },
      404,
    );
  }

  const ownerId = resolveOwnerId(objectKey, object.customMetadata);
  if (!ownerId || sanitizeSegment(authResult.uid) !== ownerId) {
    return jsonResponse(
      request,
      env,
      {
        success: false,
        error: "You do not have permission to delete this file.",
      },
      403,
    );
  }

  await env.FILES_BUCKET.delete(objectKey);

  return jsonResponse(request, env, {
    success: true,
    objectKey,
    bucketName: BUCKET_NAME,
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────

function buildObjectKey({ userId, fileType, fileName }) {
  const safeUserId = sanitizeSegment(userId);
  const safeFileName = sanitizeFileName(fileName);

  if (fileType === "generated_cv") {
    return `cvs/${safeUserId}/exports/${Date.now()}_${safeFileName}`;
  }

  if (fileType === "commercial_register") {
    return `companies/${safeUserId}/commercial_register/${Date.now()}_${safeFileName}`;
  }

  if (fileType === "profile_photo") {
    return `profiles/${safeUserId}/${Date.now()}_${safeFileName}`;
  }

  if (fileType === "project_idea_image") {
    return `ideas/${safeUserId}/covers/${Date.now()}_${safeFileName}`;
  }

  if (fileType === "chat_image") {
    return `chat/${safeUserId}/images/${Date.now()}_${safeFileName}`;
  }

  if (fileType === "chat_file") {
    return `chat/${safeUserId}/files/${Date.now()}_${safeFileName}`;
  }

  return `cvs/${safeUserId}/uploads/${Date.now()}_${safeFileName}`;
}

function buildDefaultFileName(fileType, templateId) {
  if (fileType === "generated_cv") {
    const safeTemplateId = sanitizeSegment(templateId || "default");
    return `cv_${safeTemplateId}.pdf`;
  }

  if (fileType === "commercial_register") {
    return "commercial_register.pdf";
  }

  if (fileType === "profile_photo") {
    return "profile_photo.jpg";
  }

  if (fileType === "project_idea_image") {
    return "idea_cover.jpg";
  }

  if (fileType === "chat_image") {
    return "chat_image.jpg";
  }

  if (fileType === "chat_file") {
    return "chat_attachment.bin";
  }

  return "upload.bin";
}

function getObjectKeyFromPath(pathname) {
  const prefix = "/file/";
  if (!pathname.startsWith(prefix)) {
    return "";
  }

  const rawKey = pathname.slice(prefix.length);
  if (!rawKey) {
    return "";
  }

  return rawKey
    .split("/")
    .map((segment) => decodeURIComponent(segment))
    .join("/");
}

function encodeObjectKey(objectKey) {
  return objectKey
    .split("/")
    .filter(Boolean)
    .map((segment) => encodeURIComponent(segment))
    .join("/");
}

function sanitizeFileName(value) {
  return String(value)
    .trim()
    .replace(/[^\w.\-]/g, "_")
    .replace(/_+/g, "_");
}

function sanitizeSegment(value) {
  return String(value)
    .trim()
    .replace(/[^\w\-]/g, "_")
    .replace(/_+/g, "_");
}

function sanitizeHeaderValue(value) {
  return String(value).replace(/["\r\n]/g, "_");
}

function normalizeString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeMimeType({ requestedMimeType, fileMimeType, fileName }) {
  const requested = normalizeString(requestedMimeType).toLowerCase();
  if (requested && requested !== "application/octet-stream") {
    return requested;
  }

  const detected = normalizeString(fileMimeType).toLowerCase();
  if (detected && detected !== "application/octet-stream") {
    return detected;
  }

  const normalizedFileName = normalizeString(fileName).toLowerCase();
  if (normalizedFileName.endsWith(".pdf")) {
    return "application/pdf";
  }
  if (normalizedFileName.endsWith(".doc")) {
    return "application/msword";
  }
  if (normalizedFileName.endsWith(".docx")) {
    return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  }
  if (normalizedFileName.endsWith(".png")) {
    return "image/png";
  }
  if (
    normalizedFileName.endsWith(".jpg") ||
    normalizedFileName.endsWith(".jpeg")
  ) {
    return "image/jpeg";
  }
  if (normalizedFileName.endsWith(".webp")) {
    return "image/webp";
  }
  if (normalizedFileName.endsWith(".xls")) {
    return "application/vnd.ms-excel";
  }
  if (normalizedFileName.endsWith(".xlsx")) {
    return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
  }
  if (normalizedFileName.endsWith(".ppt")) {
    return "application/vnd.ms-powerpoint";
  }
  if (normalizedFileName.endsWith(".pptx")) {
    return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
  }
  if (normalizedFileName.endsWith(".txt")) {
    return "text/plain";
  }
  if (normalizedFileName.endsWith(".zip")) {
    return "application/zip";
  }
  if (normalizedFileName.endsWith(".rar")) {
    return "application/vnd.rar";
  }

  return "application/octet-stream";
}

function validateUploadRequest({ fileType, fileName, mimeType, fileSize }) {
  const normalizedFileType = normalizeString(fileType);
  const normalizedFileName = normalizeString(fileName);
  const normalizedMimeType = normalizeString(mimeType).toLowerCase();

  if (!normalizedFileName) {
    return "A valid file name is required.";
  }

  if (!Number.isFinite(fileSize) || fileSize <= 0) {
    return "The selected file is empty.";
  }

  if (normalizedFileType === "generated_cv") {
    if (fileSize > MAX_CV_BYTES) {
      return "Generated CV files must be smaller than 10 MB.";
    }
    if (normalizedMimeType !== "application/pdf") {
      return "Generated CV files must be uploaded as PDF files.";
    }
    return "";
  }

  if (normalizedFileType === "original_cv") {
    if (fileSize > MAX_CV_BYTES) {
      return "Primary CV files must be smaller than 10 MB.";
    }
    if (normalizedMimeType !== "application/pdf") {
      return "Primary CV files must be uploaded as PDF files.";
    }
    return "";
  }

  if (normalizedFileType === "commercial_register") {
    if (fileSize > MAX_COMMERCIAL_REGISTER_BYTES) {
      return "Commercial Register files must be smaller than 10 MB.";
    }
    if (
      normalizedMimeType !== "application/pdf" &&
      normalizedMimeType !== "image/png" &&
      normalizedMimeType !== "image/jpeg"
    ) {
      return "Commercial Register files must be uploaded as PDF, JPG, or PNG files.";
    }
  }

  if (normalizedFileType === "profile_photo") {
    if (fileSize > MAX_PROFILE_PHOTO_BYTES) {
      return "Profile photos must be smaller than 5 MB.";
    }
    if (
      normalizedMimeType !== "image/png" &&
      normalizedMimeType !== "image/jpeg" &&
      normalizedMimeType !== "image/webp"
    ) {
      return "Profile photos must be JPG, PNG, or WebP images.";
    }
  }

  if (normalizedFileType === "project_idea_image") {
    if (fileSize > MAX_PROJECT_IDEA_IMAGE_BYTES) {
      return "Project idea images must be smaller than 5 MB.";
    }
    if (
      normalizedMimeType !== "image/png" &&
      normalizedMimeType !== "image/jpeg" &&
      normalizedMimeType !== "image/webp"
    ) {
      return "Project idea images must be JPG, PNG, or WebP files.";
    }
  }

  if (normalizedFileType === "chat_image") {
    if (fileSize > MAX_CHAT_IMAGE_BYTES) {
      return "Chat images must be smaller than 10 MB.";
    }
    if (
      normalizedMimeType !== "image/png" &&
      normalizedMimeType !== "image/jpeg" &&
      normalizedMimeType !== "image/webp"
    ) {
      return "Chat images must be JPG, PNG, or WebP files.";
    }
  }

  if (normalizedFileType === "chat_file") {
    if (fileSize > MAX_CHAT_FILE_BYTES) {
      return "Chat files must be smaller than 20 MB.";
    }
  }

  return "";
}

function resolveOwnerId(objectKey, customMetadata) {
  const metadataUserId = sanitizeSegment(customMetadata?.userId || "");
  if (metadataUserId) {
    return metadataUserId;
  }

  const segments = String(objectKey).split("/").filter(Boolean);
  if (
    (segments[0] === "cvs" ||
      segments[0] === "companies" ||
      segments[0] === "profiles" ||
      segments[0] === "ideas") &&
    segments[1]
  ) {
    return sanitizeSegment(segments[1]);
  }

  return "";
}

async function verifySignedAccess({ env, objectKey, expires, signature }) {
  const expiresAt = parseInt(String(expires || ""), 10);
  const normalizedSignature = normalizeString(signature);
  if (!normalizedSignature || !Number.isFinite(expiresAt)) {
    return false;
  }

  if (expiresAt <= Math.floor(Date.now() / 1000)) {
    return false;
  }

  const secret = normalizeString(env.FILE_ACCESS_SECRET);
  if (!secret) {
    return false;
  }

  const expectedSignature = await createFileAccessSignature({
    secret,
    objectKey,
    expiresAt,
  });

  return expectedSignature === normalizedSignature;
}

async function createFileAccessSignature({ secret, objectKey, expiresAt }) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const payload = new TextEncoder().encode(
    `${String(objectKey)}\n${String(expiresAt)}`,
  );
  const signature = await crypto.subtle.sign("HMAC", key, payload);
  return encodeBase64Url(signature);
}

function encodeBase64Url(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

// ── CORS ─────────────────────────────────────────────────────────────────

function buildCorsHeaders(request, env) {
  const origin = request.headers.get("Origin");
  const allowedOrigin = resolveAllowedOrigin(origin, env.ALLOWED_ORIGINS);

  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function resolveAllowedOrigin(origin, configuredOrigins) {
  const allowedOrigins = resolveAllowedOrigins(configuredOrigins);
  if (allowedOrigins.length === 0) {
    return "*";
  }

  if (!origin) {
    return allowedOrigins[0];
  }

  return allowedOrigins.includes(origin) || isLocalDevOrigin(origin)
    ? origin
    : "null";
}

function isDisallowedOrigin(request, env) {
  const origin = request.headers.get("Origin");
  if (!origin) {
    return false;
  }

  const allowedOrigins = resolveAllowedOrigins(env.ALLOWED_ORIGINS);
  if (allowedOrigins.length === 0) {
    return false;
  }

  return !allowedOrigins.includes(origin) && !isLocalDevOrigin(origin);
}

function parseAllowedOrigins(configuredOrigins) {
  return String(configuredOrigins || "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function resolveAllowedOrigins(configuredOrigins) {
  const configured = parseAllowedOrigins(configuredOrigins);
  if (configured.length === 0 || configured.includes("*")) {
    return configured;
  }

  return [...new Set([...configured, ...DEFAULT_ALLOWED_ORIGINS])];
}

function isLocalDevOrigin(origin) {
  if (!origin) {
    return false;
  }

  try {
    const url = new URL(origin);
    return (
      (url.hostname === "localhost" || url.hostname === "127.0.0.1") &&
      (url.protocol === "http:" || url.protocol === "https:")
    );
  } catch (_) {
    return false;
  }
}

function jsonResponse(request, env, payload, status = 200) {
  return new Response(JSON.stringify(payload, null, 2), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...buildCorsHeaders(request, env),
    },
  });
}
