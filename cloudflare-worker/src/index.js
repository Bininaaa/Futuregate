import {
  firestoreGet,
  firestoreSet,
  firestoreUpdate,
  firestoreDelete,
  firestoreQuery,
  firestoreBatchWrite,
  sendFcmMessage,
} from "./firestore.js";
import { getAccessToken } from "./google-auth.js";

const GOOGLE_BOOKS_API_URL = "https://www.googleapis.com/books/v1/volumes";
const YOUTUBE_API_URL = "https://www.googleapis.com/youtube/v3/search";
const IDENTITY_TOOLKIT_API_URL = "https://identitytoolkit.googleapis.com/v1";
const MAX_BOOKS_RESULTS = 20;
const MAX_CHAT_PREVIEW_LENGTH = 100;
const PASSWORD_SIGN_IN_METHOD = "password";
const GOOGLE_PROVIDER_ID = "google.com";
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PUBLIC_ADMIN_NAME = "FutureGate Admin";
const DEFAULT_FIREBASE_WEB_API_KEY = "AIzaSyDcQlwKznxxnom_W5nIhC4uT1HyxSAOqHk";
const DAY_MS = 24 * 60 * 60 * 1000;

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function err(message, status = 400) {
  return json({ error: message }, status);
}

function trim(value, fallback = "") {
  return typeof value === "string" ? value.trim() : fallback;
}

function clamp(value, min, max, fallback) {
  const parsed =
    typeof value === "number" ? value : parseInt(String(value), 10);
  return Number.isFinite(parsed)
    ? Math.max(min, Math.min(max, parsed))
    : fallback;
}

function secureThumbnail(url) {
  const raw = trim(url);
  return raw ? raw.replace(/^http:\/\//i, "https://") : "";
}

function positiveInt(value) {
  if (typeof value === "number" && Number.isInteger(value) && value > 0) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = parseInt(value, 10);
    if (Number.isInteger(parsed) && parsed > 0) {
      return parsed;
    }
  }
  return null;
}

function pageCountToDuration(pageCount) {
  return pageCount ? `${pageCount} pages` : "Book";
}

function truncateMessage(text, maxLength = MAX_CHAT_PREVIEW_LENGTH) {
  const safeText = trim(text);
  if (!safeText) {
    return "";
  }
  return safeText.length > maxLength
    ? `${safeText.slice(0, maxLength)}...`
    : safeText;
}

function displayNameForUser(userData) {
  if (!userData || typeof userData !== "object") {
    return "Someone";
  }
  if (trim(userData.role).toLowerCase() === "admin") {
    return PUBLIC_ADMIN_NAME;
  }
  return (
    trim(userData.companyName) ||
    trim(userData.fullName) ||
    trim(userData.email) ||
    "Someone"
  );
}

function normalizeOpportunityType(value) {
  const normalized = trim(value).toLowerCase();
  return ["job", "internship", "sponsoring"].includes(normalized)
    ? normalized
    : "job";
}

function opportunityTypeLabel(value) {
  switch (normalizeOpportunityType(value)) {
    case "internship":
      return "Internship";
    case "sponsoring":
      return "Sponsoring";
    case "job":
    default:
      return "Job";
  }
}

function normalizeApplicationStatus(value) {
  const normalized = trim(value).toLowerCase();
  if (normalized === "accepted" || normalized === "approved") {
    return "accepted";
  }
  if (normalized === "rejected") {
    return "rejected";
  }
  if (normalized === "withdrawn") {
    return "withdrawn";
  }
  return "pending";
}

function normalizeCompanyApprovalStatus(value) {
  const normalized = trim(value).toLowerCase();
  return ["approved", "rejected", "pending"].includes(normalized)
    ? normalized
    : "approved";
}

function normalizeDeadlineDate(value) {
  if (!value) {
    return null;
  }

  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }

  if (typeof value === "string") {
    const rawValue = trim(value);
    if (!rawValue) {
      return null;
    }

    const dateOnlyMatch = rawValue.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (dateOnlyMatch) {
      const [, year, month, day] = dateOnlyMatch;
      return new Date(
        Date.UTC(
          Number(year),
          Number(month) - 1,
          Number(day),
          23,
          59,
          59,
          999,
        ),
      );
    }

    const parsed = new Date(rawValue);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  return null;
}

function opportunityDeadlineDate(opportunity) {
  if (!opportunity || typeof opportunity !== "object") {
    return null;
  }

  return (
    normalizeDeadlineDate(opportunity.applicationDeadline) ||
    normalizeDeadlineDate(opportunity.deadline)
  );
}

function isOpportunityDeadlineExpired(opportunity, now = new Date()) {
  const deadline = opportunityDeadlineDate(opportunity);
  return deadline ? deadline.getTime() <= now.getTime() : false;
}

function scholarshipDeadlineDate(scholarship) {
  if (!scholarship || typeof scholarship !== "object") {
    return null;
  }

  return normalizeDeadlineDate(scholarship.deadline);
}

function isDeadlineReminderCandidate(deadline, now = new Date()) {
  if (!deadline || Number.isNaN(deadline.getTime())) {
    return false;
  }

  const remainingMs = deadline.getTime() - now.getTime();
  return remainingMs > 0 && remainingMs <= 3 * DAY_MS;
}

function deadlineReminderBucket(deadline, now = new Date()) {
  if (!isDeadlineReminderCandidate(deadline, now)) {
    return "";
  }

  const days = Math.ceil((deadline.getTime() - now.getTime()) / DAY_MS);
  return days <= 1 ? "1d" : "3d";
}

function deadlineRelativeLabel(deadline, now = new Date()) {
  const days = Math.ceil((deadline.getTime() - now.getTime()) / DAY_MS);
  if (days <= 0) {
    return "today";
  }
  if (days === 1) {
    return "tomorrow";
  }
  return `in ${days} days`;
}

function normalizeFcmPlatform(value) {
  const platform = trim(value).toLowerCase();
  return ["android", "ios", "web"].includes(platform) ? platform : "";
}

function corsHeaders(request, env) {
  const origin = request.headers.get("Origin") || "";
  const allowedOrigins = (env.ALLOWED_ORIGINS || "*")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  const matchedOrigin = allowedOrigins.includes("*")
    ? "*"
    : allowedOrigins.includes(origin)
      ? origin
      : "";

  return {
    "Access-Control-Allow-Origin": matchedOrigin,
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Max-Age": "86400",
  };
}

function withCors(response, request, env) {
  const responseWithCors = new Response(response.body, response);
  for (const [key, value] of Object.entries(corsHeaders(request, env))) {
    if (value) {
      responseWithCors.headers.set(key, value);
    }
  }
  return responseWithCors;
}

let jwksCache = null;
let jwksExpiry = 0;

async function fetchJwks() {
  if (jwksCache && Date.now() < jwksExpiry) {
    return jwksCache;
  }

  const response = await fetch(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  );

  if (!response.ok) {
    throw new Error("Failed to fetch Google JWKS");
  }

  jwksCache = (await response.json()).keys;
  jwksExpiry = Date.now() + 60 * 60 * 1000;
  return jwksCache;
}

function b64UrlDecode(value) {
  const padded = value + "=".repeat((4 - (value.length % 4)) % 4);
  const binary = atob(padded.replace(/-/g, "+").replace(/_/g, "/"));
  return new Uint8Array([...binary].map((char) => char.charCodeAt(0)));
}

async function verifyFirebaseToken(idToken, projectId) {
  const parts = idToken.split(".");
  if (parts.length !== 3) {
    throw new Error("Invalid token format");
  }

  const header = JSON.parse(new TextDecoder().decode(b64UrlDecode(parts[0])));
  const payload = JSON.parse(new TextDecoder().decode(b64UrlDecode(parts[1])));
  const now = Math.floor(Date.now() / 1000);

  if (
    !payload.sub ||
    payload.exp < now ||
    payload.aud !== projectId ||
    payload.iss !== `https://securetoken.google.com/${projectId}`
  ) {
    throw new Error("Invalid token claims");
  }

  const keys = await fetchJwks();
  const jwk = keys.find((item) => item.kid === header.kid);
  if (!jwk) {
    throw new Error("Signing key not found");
  }

  const cryptoKey = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );

  const isValid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    b64UrlDecode(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );

  if (!isValid) {
    throw new Error("Invalid signature");
  }

  return {
    uid: payload.sub,
    email: payload.email || "",
  };
}

async function authenticate(request, env) {
  const header = request.headers.get("Authorization") || "";
  if (!header.startsWith("Bearer ")) {
    return { error: err("Missing or invalid Authorization header", 401) };
  }

  try {
    const user = await verifyFirebaseToken(
      header.slice(7),
      env.FIREBASE_PROJECT_ID,
    );
    return { user };
  } catch (error) {
    return { error: err(`Authentication failed: ${error.message}`, 401) };
  }
}

async function requireUser(
  request,
  env,
  { roles = null, requireActive = true } = {},
) {
  const auth = await authenticate(request, env);
  if (auth.error) {
    return auth;
  }

  const userDoc = await firestoreGet(env, "users", auth.user.uid);
  if (!userDoc) {
    return { error: err("Your account could not be verified.", 403) };
  }

  const profile = userDoc.data || {};
  if (requireActive && profile.isActive === false) {
    return { error: err("Only active users can perform this action.", 403) };
  }

  if (
    Array.isArray(roles) &&
    roles.length > 0 &&
    !roles.includes(profile.role)
  ) {
    return {
      error: err("You do not have permission to perform this action.", 403),
    };
  }

  return {
    user: auth.user,
    profile,
    userDoc,
  };
}

function isValidEmail(value) {
  return EMAIL_PATTERN.test(trim(value));
}

function maskEmailForLogs(email) {
  const normalized = trim(email).toLowerCase();
  const atIndex = normalized.indexOf("@");
  if (atIndex <= 0) {
    return "unknown-email";
  }

  const localPart = normalized.slice(0, atIndex);
  const domain = normalized.slice(atIndex + 1);
  const visibleLocal =
    localPart.length <= 2
      ? `${localPart[0] || "*"}*`
      : `${localPart.slice(0, 2)}***`;

  return `${visibleLocal}@${domain}`;
}

function passwordResetRequestIp(request) {
  const cfConnectingIp =
    trim(request.headers.get("CF-Connecting-IP")) ||
    trim(request.headers.get("cf-connecting-ip"));
  if (cfConnectingIp) {
    return cfConnectingIp;
  }

  const forwardedFor = trim(request.headers.get("x-forwarded-for"));
  if (forwardedFor) {
    return trim(forwardedFor.split(",")[0]);
  }

  const realIp = trim(request.headers.get("x-real-ip"));
  if (realIp) {
    return realIp;
  }

  const hostname = trim(new URL(request.url).hostname).toLowerCase();
  if (hostname === "localhost" || hostname === "127.0.0.1") {
    return "127.0.0.1";
  }

  return "";
}

function identityToolkitContinueUrl(env) {
  const projectId = trim(env.FIREBASE_PROJECT_ID);
  return `https://${projectId}.firebaseapp.com/__/auth/handler`;
}

function firebaseWebApiKey(env) {
  return trim(env.FIREBASE_WEB_API_KEY) || DEFAULT_FIREBASE_WEB_API_KEY;
}

function extractIdentityToolkitErrorMessage(payload, fallbackMessage) {
  const details = payload && typeof payload === "object" ? payload.error : null;
  const message =
    trim(details?.message) ||
    trim(details?.status) ||
    trim(payload?.error) ||
    trim(fallbackMessage);
  return message || "Identity Toolkit request failed.";
}

async function identityToolkitRequest(
  env,
  path,
  { body = null, includeApiKey = false } = {},
) {
  const accessToken = await getAccessToken(env);
  const url = new URL(`${IDENTITY_TOOLKIT_API_URL}${path}`);

  if (includeApiKey) {
    const apiKey = firebaseWebApiKey(env);
    if (!apiKey) {
      throw new Error(
        "Password reset is not configured: FIREBASE_WEB_API_KEY is missing.",
      );
    }
    url.searchParams.set("key", apiKey);
  }

  const response = await fetch(url.toString(), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body ?? {}),
  });

  const rawBody = await response.text();
  let payload = {};
  if (rawBody) {
    try {
      payload = JSON.parse(rawBody);
    } catch {
      payload = { error: rawBody };
    }
  }

  if (!response.ok) {
    throw Object.assign(
      new Error(
        extractIdentityToolkitErrorMessage(
          payload,
          `Identity Toolkit request failed with status ${response.status}.`,
        ),
      ),
      {
        statusCode: response.status,
        payload,
      },
    );
  }

  return payload;
}

async function fetchSignInMethodsForEmail(env, email) {
  const payload = await identityToolkitRequest(env, "/accounts:createAuthUri", {
    includeApiKey: true,
    body: {
      identifier: email,
      continueUri: identityToolkitContinueUrl(env),
    },
  });

  const signInMethods = Array.isArray(payload?.signinMethods)
    ? payload.signinMethods.map((value) => trim(value)).filter(Boolean)
    : [];

  return {
    registered: payload?.registered === true,
    signInMethods,
  };
}

async function lookupAccountByEmail(env, email) {
  const projectId = encodeURIComponent(trim(env.FIREBASE_PROJECT_ID));
  const payload = await identityToolkitRequest(
    env,
    `/projects/${projectId}/accounts:lookup`,
    {
      body: {
        email: [email],
      },
    },
  );

  const users = Array.isArray(payload?.users) ? payload.users : [];
  const account = users.find((user) => user && typeof user === "object");
  return account && typeof account === "object" ? account : null;
}

function accountProviderIds(account) {
  return new Set(
    (Array.isArray(account?.providerUserInfo) ? account.providerUserInfo : [])
      .map((providerInfo) => trim(providerInfo?.providerId))
      .filter(Boolean),
  );
}

function accountHasPasswordMethod(account, signInMethods = []) {
  const normalizedMethods = Array.isArray(signInMethods)
    ? signInMethods.map((value) => trim(value)).filter(Boolean)
    : [];
  if (normalizedMethods.includes(PASSWORD_SIGN_IN_METHOD)) {
    return true;
  }

  const providerIds = accountProviderIds(account);
  if (providerIds.has(PASSWORD_SIGN_IN_METHOD)) {
    return true;
  }

  if (trim(account?.passwordHash)) {
    return true;
  }

  const passwordUpdatedAt = Number(account?.passwordUpdatedAt);
  return Number.isFinite(passwordUpdatedAt) && passwordUpdatedAt > 0;
}

function accountHasGoogleMethod(account, signInMethods = []) {
  const normalizedMethods = Array.isArray(signInMethods)
    ? signInMethods.map((value) => trim(value)).filter(Boolean)
    : [];
  if (normalizedMethods.includes(GOOGLE_PROVIDER_ID)) {
    return true;
  }

  return accountProviderIds(account).has(GOOGLE_PROVIDER_ID);
}

async function sendPasswordResetEmail(env, email, userIp) {
  const projectId = encodeURIComponent(trim(env.FIREBASE_PROJECT_ID));
  const apiKey = firebaseWebApiKey(env);
  if (!apiKey) {
    throw new Error(
      "Password reset is not configured: FIREBASE_WEB_API_KEY is missing.",
    );
  }

  await identityToolkitRequest(
    env,
    `/projects/${projectId}/accounts:sendOobCode`,
    {
      includeApiKey: true,
      body: {
        requestType: "PASSWORD_RESET",
        email,
        userIp,
      },
    },
  );
}

async function handlePasswordReset(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON body.");
  }

  const email = trim(body?.email);
  const maskedEmail = maskEmailForLogs(email);
  if (!isValidEmail(email)) {
    console.warn("[passwordReset] invalid-email", { email: maskedEmail });
    return err("The email address is not valid.", 400);
  }

  const userIp = passwordResetRequestIp(request);
  if (!userIp) {
    console.error("[passwordReset] missing-user-ip", { email: maskedEmail });
    return err("Could not determine the caller IP for password reset.", 500);
  }

  try {
    const signInContext = await fetchSignInMethodsForEmail(env, email);
    let hasPassword = signInContext.signInMethods.includes(
      PASSWORD_SIGN_IN_METHOD,
    );
    let hasGoogle = signInContext.signInMethods.includes(GOOGLE_PROVIDER_ID);

    // Email-enumeration protection can hide `registered` and `signinMethods`
    // for real accounts, so verify with the privileged lookup before failing.
    const account =
      !signInContext.registered || !hasPassword || !hasGoogle
        ? await lookupAccountByEmail(env, email)
        : null;

    if (!signInContext.registered && !account) {
      console.info("[passwordReset] email-not-found", { email: maskedEmail });
      return err("No account was found for that email address.", 404);
    }

    if (account) {
      hasPassword =
        hasPassword ||
        accountHasPasswordMethod(account, signInContext.signInMethods);
      hasGoogle =
        hasGoogle || accountHasGoogleMethod(account, signInContext.signInMethods);
    }

    if (hasGoogle && !hasPassword) {
      console.info("[passwordReset] google-only-account", { email: maskedEmail });
      return err(
        "This account uses Google sign-in. Sign in with Google first, then add a password from Settings if you want reset emails later.",
        409,
      );
    }

    await sendPasswordResetEmail(env, email, userIp);
    console.info("[passwordReset] email-sent", {
      email: maskedEmail,
      hasPassword,
      hasGoogle,
    });
    return json({ success: true });
  } catch (error) {
    const message = trim(error?.message).toUpperCase();
    console.error("[passwordReset] failed", {
      email: maskedEmail,
      message: trim(error?.message),
      statusCode: error?.statusCode ?? 0,
    });

    if (!message) {
      throw error;
    }

    if (message.includes("INVALID_EMAIL")) {
      return err("The email address is not valid.", 400);
    }

    if (message.includes("EMAIL_NOT_FOUND")) {
      return json({ success: true });
    }

    if (
      message.includes("TOO_MANY_ATTEMPTS_TRY_LATER") ||
      message.includes("RESET_PASSWORD_EXCEED_LIMIT") ||
      message.includes("CAPTCHA_CHECK_FAILED")
    ) {
      return err("Too many attempts. Please try again later.", 429);
    }

    if (message.includes("OPERATION_NOT_ALLOWED")) {
      return err("Password reset is not configured right now.", 503);
    }

    if (message.includes("FIREBASE_WEB_API_KEY IS MISSING")) {
      return err("Password reset is not configured right now.", 503);
    }

    throw error;
  }
}

function normalizeBookItem(item) {
  const safeItem = item && typeof item === "object" ? item : {};
  const volumeInfo =
    safeItem.volumeInfo && typeof safeItem.volumeInfo === "object"
      ? safeItem.volumeInfo
      : {};
  const imageLinks =
    volumeInfo.imageLinks && typeof volumeInfo.imageLinks === "object"
      ? volumeInfo.imageLinks
      : {};

  const previewLink = trim(volumeInfo.previewLink);
  const infoLink = trim(volumeInfo.infoLink) || previewLink;

  return {
    googleBookId: trim(safeItem.id),
    title: trim(volumeInfo.title) || "Untitled Book",
    description: trim(volumeInfo.description).slice(0, 5000),
    authors: Array.isArray(volumeInfo.authors)
      ? volumeInfo.authors
          .map((author) => trim(author))
          .filter(Boolean)
          .slice(0, 20)
      : [],
    provider: trim(volumeInfo.publisher) || "Google Books",
    thumbnail: secureThumbnail(imageLinks.thumbnail),
    language: trim(volumeInfo.language),
    previewLink,
    infoLink,
    pageCount: positiveInt(volumeInfo.pageCount),
    publishedDate: trim(volumeInfo.publishedDate),
  };
}

function bestYoutubeThumbnail(thumbnails) {
  const safeThumbnails =
    thumbnails && typeof thumbnails === "object" ? thumbnails : {};
  for (const quality of ["maxres", "standard", "high", "medium", "default"]) {
    const url = trim(safeThumbnails[quality]?.url);
    if (url) {
      return secureThumbnail(url);
    }
  }
  return "";
}

function normalizeYoutubeItem(item) {
  const safeItem = item && typeof item === "object" ? item : {};
  const idData =
    safeItem.id && typeof safeItem.id === "object" ? safeItem.id : {};
  const snippet =
    safeItem.snippet && typeof safeItem.snippet === "object"
      ? safeItem.snippet
      : {};
  const youtubeVideoId = trim(idData.videoId);

  if (!youtubeVideoId) {
    return null;
  }

  return {
    youtubeVideoId,
    title: trim(snippet.title) || "Untitled Video",
    description: trim(snippet.description).slice(0, 5000),
    provider: trim(snippet.channelTitle) || "YouTube",
    channelTitle: trim(snippet.channelTitle) || "YouTube",
    thumbnail: bestYoutubeThumbnail(snippet.thumbnails),
    link: `https://www.youtube.com/watch?v=${youtubeVideoId}`,
    publishedAtSource: trim(snippet.publishedAt),
  };
}

async function getActiveUsersByRole(env, role) {
  return firestoreQuery(env, "users", [
    { field: "role", op: "EQUAL", value: role },
    { field: "isActive", op: "EQUAL", value: true },
  ]);
}

async function getExistingNotificationsByEventKey(env, eventKey) {
  if (!eventKey) {
    return [];
  }

  return firestoreQuery(env, "notifications", [
    { field: "eventKey", op: "EQUAL", value: eventKey },
  ]);
}

async function markNotificationsReadByEventKey(env, eventKey) {
  const normalizedEventKey = trim(eventKey);
  if (!normalizedEventKey) {
    return { markedRead: 0 };
  }

  try {
    const notifications = await getExistingNotificationsByEventKey(
      env,
      normalizedEventKey,
    );
    const unreadNotifications = notifications.filter(
      (item) => trim(item?.id) && item?.data?.isRead !== true,
    );

    if (unreadNotifications.length === 0) {
      return { markedRead: 0 };
    }

    const results = await firestoreBatchWrite(
      env,
      unreadNotifications.map((item) => ({
        update: {
          path: `notifications/${trim(item.id)}`,
          data: { isRead: true },
          mask: ["isRead"],
          currentDocument: { exists: true },
        },
      })),
    );

    const markedRead = results.filter((result) => result?.ok).length;
    const failed = Math.max(0, unreadNotifications.length - markedRead);
    if (failed > 0) {
      console.warn(
        `[markNotificationsReadByEventKey:${normalizedEventKey}] ${failed} notification update(s) failed`,
      );
    }

    return { markedRead, failed };
  } catch (error) {
    console.warn(
      `[markNotificationsReadByEventKey:${normalizedEventKey}] failed`,
      error,
    );
    return { markedRead: 0, failed: 1 };
  }
}

function uniqueTrimmedStrings(values) {
  const seen = new Set();
  const result = [];

  for (const value of Array.isArray(values) ? values : []) {
    const normalized = trim(value);
    if (!normalized || seen.has(normalized)) {
      continue;
    }
    seen.add(normalized);
    result.push(normalized);
  }

  return result;
}

function defaultNotificationRoute(
  type,
  { targetId = "", conversationId = "" } = {},
) {
  const safeType = trim(type);
  const safeTargetId = trim(targetId);
  const safeConversationId = trim(conversationId);

  if (safeType === "chat" && safeConversationId) {
    return `/notifications/chat/${encodeURIComponent(safeConversationId)}`;
  }

  if (safeType && safeTargetId) {
    return `/notifications/${encodeURIComponent(safeType)}/${encodeURIComponent(safeTargetId)}`;
  }

  return "/notifications";
}

async function stableNotificationDocId(eventKey, recipientId) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(
      `notification:${trim(eventKey)}:${trim(recipientId)}`,
    ),
  );
  const hash = [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
  return `notif_${hash.slice(0, 40)}`;
}

function normalizeIdeaValue(value, { lowerCase = false } = {}) {
  const normalized = trim(value).replace(/\s+/g, " ");
  return lowerCase ? normalized.toLowerCase() : normalized;
}

function normalizeIdeaList(value) {
  if (Array.isArray(value)) {
    return [...new Set(value.map((item) => normalizeIdeaValue(item)).filter(Boolean))];
  }

  if (typeof value === "string") {
    return [
      ...new Set(
        value
          .split(",")
          .map((item) => normalizeIdeaValue(item))
          .filter(Boolean),
      ),
    ];
  }

  return [];
}

async function stableProjectIdeaIdentity({
  submittedBy,
  title,
  description,
  domain,
  level,
  tools,
  stage,
  skillsNeeded,
  teamNeeded,
}) {
  const fingerprintSource = [
    normalizeIdeaValue(submittedBy, { lowerCase: true }),
    normalizeIdeaValue(title, { lowerCase: true }),
    normalizeIdeaValue(description, { lowerCase: true }),
    normalizeIdeaValue(domain, { lowerCase: true }),
    normalizeIdeaValue(level, { lowerCase: true }),
    normalizeIdeaValue(tools, { lowerCase: true }),
    normalizeIdeaValue(stage, { lowerCase: true }),
    normalizeIdeaList(skillsNeeded).join(","),
    normalizeIdeaList(teamNeeded).join(","),
  ].join("|");

  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`project-idea:${fingerprintSource}`),
  );
  const hash = [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

  return {
    id: `idea_${hash.slice(0, 40)}`,
    dedupeKey: `project-idea-submit:${hash.slice(0, 40)}`,
  };
}

function isDuplicateWriteError(code) {
  return code === 6 || code === 9;
}

function normalizeIdeaInteractionType(value) {
  const normalized = trim(value).toLowerCase();
  return ["interest", "save"].includes(normalized) ? normalized : "";
}

function buildProjectIdeaInteractionId({ ideaId, userId, type }) {
  return `${type}_${userId}_${ideaId}`;
}

function chunkList(values, chunkSize) {
  const normalizedChunkSize =
    Number.isInteger(chunkSize) && chunkSize > 0 ? chunkSize : 10;
  const chunks = [];

  for (let index = 0; index < values.length; index += normalizedChunkSize) {
    chunks.push(values.slice(index, index + normalizedChunkSize));
  }

  return chunks;
}

function canAccessProjectIdea(ideaData, userId, role) {
  if (trim(role).toLowerCase() === "admin") {
    return true;
  }

  return (
    (trim(ideaData?.status).toLowerCase() === "approved" &&
      ideaData?.isHidden !== true) ||
    trim(ideaData?.submittedBy) === trim(userId)
  );
}

async function resolveAccessibleIdeaIds(env, ideaIds, auth) {
  const normalizedIdeaIds = uniqueTrimmedStrings(ideaIds);
  if (normalizedIdeaIds.length === 0) {
    return [];
  }

  if (trim(auth.profile?.role).toLowerCase() === "admin") {
    return normalizedIdeaIds;
  }

  const ideaDocs = await Promise.all(
    normalizedIdeaIds.map((ideaId) => firestoreGet(env, "projectIdeas", ideaId)),
  );

  return normalizedIdeaIds.filter((ideaId, index) => {
    const ideaDoc = ideaDocs[index];
    if (!ideaDoc) {
      return false;
    }

    return canAccessProjectIdea(
      ideaDoc.data || {},
      auth.user.uid,
      auth.profile?.role,
    );
  });
}

async function listIdeaInteractionDocs(env, ideaIds) {
  const normalizedIdeaIds = uniqueTrimmedStrings(ideaIds);
  if (normalizedIdeaIds.length === 0) {
    return [];
  }

  const interactionDocs = [];
  for (const chunk of chunkList(normalizedIdeaIds, 10)) {
    const chunkDocs = await firestoreQuery(env, "projectIdeaInteractions", [
      { field: "ideaId", op: "IN", value: chunk },
    ]);
    interactionDocs.push(...chunkDocs);
  }

  return interactionDocs;
}

function buildIdeaEngagementSnapshot(interactionDocs, currentUserId) {
  const normalizedUserId = trim(currentUserId);
  const interestedByIdeaId = {};
  const savedIdeaIds = new Set();
  const joinedIdeaIds = new Set();

  for (const doc of Array.isArray(interactionDocs) ? interactionDocs : []) {
    const data = doc?.data && typeof doc.data === "object" ? doc.data : {};
    const ideaId = trim(data.ideaId);
    const userId = trim(data.userId);
    const type = normalizeIdeaInteractionType(data.type);

    if (!ideaId || !type) {
      continue;
    }

    switch (type) {
      case "interest":
        interestedByIdeaId[ideaId] = (interestedByIdeaId[ideaId] || 0) + 1;
        if (userId === normalizedUserId) {
          joinedIdeaIds.add(ideaId);
        }
        break;
      case "save":
        if (userId === normalizedUserId) {
          savedIdeaIds.add(ideaId);
        }
        break;
    }
  }

  return {
    interestedByIdeaId,
    savedIdeaIds: [...savedIdeaIds],
    joinedIdeaIds: [...joinedIdeaIds],
  };
}

function collectRecipientTokens(recipientData) {
  const tokens = [];
  const primaryToken = trim(recipientData?.fcmToken);

  if (primaryToken) {
    tokens.push(primaryToken);
  }

  if (Array.isArray(recipientData?.fcmTokens)) {
    for (const value of recipientData.fcmTokens) {
      const token =
        typeof value === "string"
          ? trim(value)
          : value && typeof value === "object"
            ? trim(value.token)
            : "";
      if (token) {
        tokens.push(token);
      }
    }
  }

  return [...new Set(tokens)];
}

async function clearInvalidTokensForUsers(env, jobs, invalidToken) {
  if (!invalidToken) {
    return;
  }

  const uniqueUsers = new Map();
  for (const job of jobs) {
    if (!job?.userId || uniqueUsers.has(job.userId)) {
      continue;
    }
    uniqueUsers.set(job.userId, job.recipientData || {});
  }

  await Promise.allSettled(
    [...uniqueUsers.entries()].map(async ([userId, recipientData]) => {
      const nextData = {
        fcmTokenUpdatedAt: new Date(),
      };
      let shouldUpdate = false;

      if (trim(recipientData?.fcmToken) === invalidToken) {
        nextData.fcmToken = "";
        nextData.fcmTokenPlatform = "";
        shouldUpdate = true;
      }

      if (Array.isArray(recipientData?.fcmTokens)) {
        const filteredTokens = recipientData.fcmTokens.filter((value) => {
          const token =
            typeof value === "string"
              ? trim(value)
              : value && typeof value === "object"
                ? trim(value.token)
                : "";
          return token && token !== invalidToken;
        });

        if (filteredTokens.length !== recipientData.fcmTokens.length) {
          nextData.fcmTokens = filteredTokens;
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        await firestoreUpdate(env, "users", userId, nextData);
      }
    }),
  );
}

async function notifyRecipients(
  env,
  recipients,
  {
    title,
    message,
    type,
    targetId = "",
    conversationId = "",
    eventKey = "",
    logLabel = "",
    route = "",
    actorUserId = "",
    excludeUserIds = [],
    excludeTokens = [],
    includeInactiveRecipients = false,
  },
) {
  const recipientsFound = Array.isArray(recipients) ? recipients.length : 0;
  const actorId = trim(actorUserId);
  const excludedRecipientIds = new Set(
    uniqueTrimmedStrings([actorId, ...excludeUserIds]),
  );
  const excludedTokenSet = new Set(uniqueTrimmedStrings(excludeTokens));
  const dedupedRecipients = [];
  const seenRecipientIds = new Set();
  let duplicateRecipientInputsSkipped = 0;
  let inactiveRecipientsSkipped = 0;
  let excludedRecipientsSkipped = 0;

  for (const recipient of Array.isArray(recipients) ? recipients : []) {
    const recipientId = trim(recipient?.id);
    if (!recipientId) {
      continue;
    }
    if (seenRecipientIds.has(recipientId)) {
      duplicateRecipientInputsSkipped += 1;
      continue;
    }
    if (!includeInactiveRecipients && recipient?.data?.isActive === false) {
      inactiveRecipientsSkipped += 1;
      continue;
    }
    if (excludedRecipientIds.has(recipientId)) {
      excludedRecipientsSkipped += 1;
      continue;
    }
    seenRecipientIds.add(recipientId);
    dedupedRecipients.push({
      id: recipientId,
      data:
        recipient?.data && typeof recipient.data === "object"
          ? recipient.data
          : {},
    });
  }

  if (dedupedRecipients.length === 0) {
    return {
      recipientsFound,
      filteredRecipients: 0,
      uniqueRecipients: 0,
      actorUserId: actorId,
      excludedRecipients: excludedRecipientsSkipped,
      duplicateRecipientInputsSkipped,
      inactiveRecipientsSkipped,
      created: 0,
      notificationDocsCreated: 0,
      pushSent: 0,
      pushesSent: 0,
      duplicatesSkipped: 0,
      duplicateDocsSkipped: 0,
      duplicateTokensSkipped: 0,
      excludedTokens: excludedTokenSet.size,
      tokensBeforeDedup: 0,
      tokensAfterDedup: 0,
      missingTokens: 0,
      invalidTokens: 0,
      tokensInvalid: 0,
      errors: [],
      alreadyNotified: false,
    };
  }

  const existingNotifications = await getExistingNotificationsByEventKey(
    env,
    eventKey,
  ).catch(() => []);
  const existingUserIds = new Set(
    existingNotifications
      .map((item) => trim(item?.data?.userId))
      .filter(Boolean),
  );

  const now = new Date();
  const resolvedRoute =
    trim(route) || defaultNotificationRoute(type, { targetId, conversationId });
  const plannedNotifications = [];
  let duplicateDocsSkipped = 0;
  let excludedTokensCount = 0;

  for (const recipient of dedupedRecipients) {
    if (existingUserIds.has(recipient.id)) {
      duplicateDocsSkipped += 1;
      continue;
    }

    const allRecipientTokens = collectRecipientTokens(recipient.data);
    const recipientTokens = allRecipientTokens.filter(
      (token) => !excludedTokenSet.has(token),
    );
    excludedTokensCount += Math.max(
      0,
      allRecipientTokens.length - recipientTokens.length,
    );

    plannedNotifications.push({
      notificationId: eventKey
        ? await stableNotificationDocId(eventKey, recipient.id)
        : crypto.randomUUID(),
      userId: recipient.id,
      recipientData: recipient.data,
      tokens: recipientTokens,
    });
  }

  if (plannedNotifications.length === 0) {
    return {
      recipientsFound,
      uniqueRecipients: dedupedRecipients.length,
      filteredRecipients: dedupedRecipients.length,
      actorUserId: actorId,
      excludedRecipients: excludedRecipientsSkipped,
      duplicateRecipientInputsSkipped,
      inactiveRecipientsSkipped,
      created: 0,
      notificationDocsCreated: 0,
      pushSent: 0,
      pushesSent: 0,
      duplicatesSkipped: duplicateDocsSkipped,
      duplicateDocsSkipped,
      duplicateTokensSkipped: 0,
      excludedTokens: excludedTokensCount,
      tokensBeforeDedup: 0,
      tokensAfterDedup: 0,
      missingTokens: 0,
      invalidTokens: 0,
      tokensInvalid: 0,
      errors: [],
      alreadyNotified: duplicateDocsSkipped > 0,
    };
  }

  const createWrites = plannedNotifications.map((entry) => ({
    update: {
      path: `notifications/${entry.notificationId}`,
      data: {
        id: entry.notificationId,
        userId: entry.userId,
        title,
        message,
        body: message,
        type,
        targetId,
        conversationId,
        route: resolvedRoute,
        createdAt: now,
        isRead: false,
        pushSent: false,
        pushTokenAvailable: entry.tokens.length > 0,
        eventKey,
      },
      currentDocument: eventKey ? { exists: false } : undefined,
    },
  }));

  const createResults = await firestoreBatchWrite(env, createWrites);
  const createdNotifications = [];
  const errors = [];

  for (let index = 0; index < plannedNotifications.length; index += 1) {
    const entry = plannedNotifications[index];
    const createResult = createResults[index] || {
      ok: true,
      code: 0,
      message: "",
      writeResult: {},
    };

    if (createResult.ok) {
      createdNotifications.push(entry);
      continue;
    }

    if (isDuplicateWriteError(createResult.code)) {
      duplicateDocsSkipped += 1;
      continue;
    }

    errors.push({
      code: createResult.code || "write_failed",
      message: createResult.message || "notification_write_failed",
      userId: entry.userId,
    });
  }

  if (createdNotifications.length === 0) {
    return {
      recipientsFound,
      uniqueRecipients: dedupedRecipients.length,
      filteredRecipients: dedupedRecipients.length,
      actorUserId: actorId,
      excludedRecipients: excludedRecipientsSkipped,
      duplicateRecipientInputsSkipped,
      inactiveRecipientsSkipped,
      created: 0,
      notificationDocsCreated: 0,
      pushSent: 0,
      pushesSent: 0,
      duplicatesSkipped: duplicateDocsSkipped,
      duplicateDocsSkipped,
      duplicateTokensSkipped: 0,
      excludedTokens: excludedTokensCount,
      tokensBeforeDedup: 0,
      tokensAfterDedup: 0,
      missingTokens: 0,
      invalidTokens: 0,
      tokensInvalid: 0,
      errors,
      alreadyNotified: duplicateDocsSkipped > 0 && errors.length === 0,
    };
  }

  const pendingPushJobsByToken = new Map();
  const missingPushStates = [];
  let tokensBeforeDedup = 0;

  for (const entry of createdNotifications) {
    tokensBeforeDedup += entry.tokens.length;

    if (entry.tokens.length === 0) {
      missingPushStates.push({
        notificationIds: [entry.notificationId],
        jobs: [
          {
            userId: entry.userId,
            recipientData: entry.recipientData,
          },
        ],
        token: "",
        pushSent: false,
        pushTokenAvailable: false,
        pushError: "missing_token",
        invalidToken: false,
      });
      continue;
    }

    for (const token of entry.tokens) {
      const existingJob = pendingPushJobsByToken.get(token);
      if (existingJob) {
        existingJob.notificationIds.push(entry.notificationId);
        existingJob.jobs.push({
          userId: entry.userId,
          recipientData: entry.recipientData,
        });
        continue;
      }

      pendingPushJobsByToken.set(token, {
        token,
        notificationIds: [entry.notificationId],
        jobs: [
          {
            userId: entry.userId,
            recipientData: entry.recipientData,
          },
        ],
      });
    }
  }

  const pendingPushes = [...pendingPushJobsByToken.values()];
  const pushResults = await Promise.allSettled(
    pendingPushes.map(async (job) => {
      try {
        const result = await sendFcmMessage(env, {
          token: job.token,
          notification: { title, body: message },
          data: {
            type,
            conversationId,
            targetId,
            notificationId: job.notificationIds[0],
            eventKey,
            route: resolvedRoute,
          },
          android: { priority: "high" },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default" } },
          },
          webpush: {
            notification: {
              title,
              body: message,
              icon: "/icons/Icon-192.png",
            },
          },
        });

        if (result.invalidToken) {
          await clearInvalidTokensForUsers(env, job.jobs, job.token).catch(
            () => {},
          );
        }

        return {
          notificationIds: job.notificationIds,
          jobs: job.jobs,
          token: job.token,
          pushSent: result.success === true,
          pushTokenAvailable: true,
          pushError: result.success
            ? ""
            : result.invalidToken
              ? "invalid_token"
              : "send_failed",
          invalidToken: result.invalidToken === true,
        };
      } catch (error) {
        return {
          notificationIds: job.notificationIds,
          jobs: job.jobs,
          token: job.token,
          pushSent: false,
          pushTokenAvailable: true,
          pushError: "send_failed",
          invalidToken: false,
        };
      }
    }),
  );

  const pushStateWrites = [];
  let pushSentCount = 0;
  let missingTokens = 0;
  let invalidTokens = 0;

  const allPushStates = [...missingPushStates];

  for (const result of pushResults) {
    const state =
      result.status === "fulfilled"
        ? result.value
        : {
            notificationIds: [],
            jobs: [],
            token: "",
            pushSent: false,
            pushTokenAvailable: false,
            pushError: "send_failed",
            invalidToken: false,
          };

    if (
      !Array.isArray(state.notificationIds) ||
      state.notificationIds.length === 0
    ) {
      continue;
    }

    allPushStates.push(state);

    if (state.pushSent) {
      pushSentCount += 1;
    }
    if (state.invalidToken) {
      invalidTokens += 1;
    }
    if (state.pushError && state.pushError !== "invalid_token") {
      errors.push({
        code: state.pushError,
        token: state.token ? "redacted" : "",
        notificationCount: state.notificationIds.length,
      });
    }
  }

  for (const state of allPushStates) {
    if (
      !Array.isArray(state.notificationIds) ||
      state.notificationIds.length === 0
    ) {
      continue;
    }

    if (!state.pushTokenAvailable) {
      missingTokens += state.notificationIds.length;
    }

    for (const notificationId of state.notificationIds) {
      pushStateWrites.push({
        update: {
          path: `notifications/${notificationId}`,
          data: {
            pushSent: state.pushSent,
            pushTokenAvailable: state.pushTokenAvailable,
            pushAttemptedAt: new Date(),
            pushError: state.pushError,
          },
          mask: [
            "pushSent",
            "pushTokenAvailable",
            "pushAttemptedAt",
            "pushError",
          ],
        },
      });
    }
  }

  if (pushStateWrites.length > 0) {
    await firestoreBatchWrite(env, pushStateWrites);
  }

  const notificationDocsCreated = createdNotifications.length;
  const tokensAfterDedup = pendingPushes.length;
  const duplicateTokensSkipped = Math.max(
    0,
    tokensBeforeDedup - tokensAfterDedup,
  );
  const result = {
    recipientsFound,
    filteredRecipients: dedupedRecipients.length,
    uniqueRecipients: dedupedRecipients.length,
    actorUserId: actorId,
    excludedRecipients: excludedRecipientsSkipped,
    duplicateRecipientInputsSkipped,
    inactiveRecipientsSkipped,
    created: notificationDocsCreated,
    notificationDocsCreated,
    pushSent: pushSentCount,
    pushesSent: pushSentCount,
    duplicatesSkipped: duplicateDocsSkipped,
    duplicateDocsSkipped,
    duplicateTokensSkipped,
    excludedTokens: excludedTokensCount,
    tokensBeforeDedup,
    tokensAfterDedup,
    missingTokens,
    invalidTokens,
    tokensInvalid: invalidTokens,
    errors,
    alreadyNotified: notificationDocsCreated === 0 && duplicateDocsSkipped > 0,
  };

  if (logLabel) {
    console.log(`${logLabel} notify summary:`, {
      eventKey,
      actorUserId: result.actorUserId,
      recipientsFound: result.recipientsFound,
      filteredRecipients: result.filteredRecipients,
      uniqueRecipients: result.uniqueRecipients,
      excludedRecipients: result.excludedRecipients,
      tokensBeforeDedup: result.tokensBeforeDedup,
      tokensAfterDedup: result.tokensAfterDedup,
      notificationDocsCreated: result.notificationDocsCreated,
      duplicateDocsSkipped: result.duplicateDocsSkipped,
      duplicateTokensSkipped: result.duplicateTokensSkipped,
      excludedTokens: result.excludedTokens,
      pushesSent: result.pushesSent,
      missingTokens: result.missingTokens,
      invalidTokens: result.invalidTokens,
      errorCount: result.errors.length,
    });
  }

  return result;
}

function handleHealth() {
  return json({
    status: "ok",
    timestamp: new Date().toISOString(),
  });
}

async function handleSearchBooks(request, env) {
  const auth = await requireUser(request, env);
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const query = trim(body.query).slice(0, 160);
  const langRestrict = trim(body.langRestrict).slice(0, 20);
  const maxResults = clamp(body.maxResults, 1, MAX_BOOKS_RESULTS, 10);

  if (!query) {
    return err("A search query is required.");
  }

  const params = new URLSearchParams({
    q: query,
    maxResults: String(maxResults),
    printType: "books",
    orderBy: "relevance",
    key: env.GOOGLE_BOOKS_API_KEY,
  });

  if (langRestrict) {
    params.set("langRestrict", langRestrict);
  }

  const response = await fetch(`${GOOGLE_BOOKS_API_URL}?${params.toString()}`);
  if (!response.ok) {
    return err("Google Books search failed. Please try again later.", 502);
  }

  const payload = await response.json();
  const items = (Array.isArray(payload.items) ? payload.items : [])
    .map(normalizeBookItem)
    .filter((item) => item.googleBookId);

  return json({ items });
}

async function handleSearchYoutube(request, env) {
  const auth = await requireUser(request, env);
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const query = trim(body.query).slice(0, 160);
  const maxResults = clamp(body.maxResults, 1, 20, 12);
  const language = trim(body.language).toLowerCase().slice(0, 20);
  const relevanceLanguage = ["fr", "en", "ar"].includes(language)
    ? language
    : "";

  if (!query) {
    return err("A search query is required.");
  }

  const params = new URLSearchParams({
    part: "snippet",
    q: query,
    type: "video",
    maxResults: String(maxResults),
    key: env.YOUTUBE_API_KEY,
  });

  if (relevanceLanguage) {
    params.set("relevanceLanguage", relevanceLanguage);
  }

  const response = await fetch(`${YOUTUBE_API_URL}?${params.toString()}`);
  if (!response.ok) {
    return err("YouTube search failed. Please try again later.", 502);
  }

  const payload = await response.json();
  const items = (Array.isArray(payload.items) ? payload.items : [])
    .map(normalizeYoutubeItem)
    .filter(Boolean);

  return json({ items });
}

async function handleImportBook(request, env) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const book = body.selectedBook;
  const domain = trim(body.domain).slice(0, 120);
  const level = trim(body.level).slice(0, 50) || "general";
  const languageOverride = trim(body.languageOverride).slice(0, 20);
  const isFeatured = body.isFeatured === true;

  if (!book || !trim(book.googleBookId)) {
    return err("A valid Google Books result is required.");
  }
  if (!domain) {
    return err("A training domain is required.");
  }

  const googleBookId = trim(book.googleBookId);
  const trainingId = `google_book_${googleBookId}`;
  const pageCount = positiveInt(book.pageCount);
  const existingTraining = await firestoreGet(env, "trainings", trainingId);

  const trainingData = {
    id: trainingId,
    title: trim(book.title) || "Untitled Book",
    description: trim(book.description).slice(0, 5000),
    provider: trim(book.provider) || "Google Books",
    duration: pageCountToDuration(pageCount),
    level,
    link: trim(book.infoLink) || trim(book.previewLink),
    type: "book",
    source: "google_books",
    authors: Array.isArray(book.authors)
      ? book.authors.map((author) => trim(author)).filter(Boolean)
      : [],
    thumbnail: secureThumbnail(book.thumbnail),
    domain,
    language: languageOverride || trim(book.language),
    previewLink: trim(book.previewLink),
    isApproved: true,
    isFeatured,
    googleBookId,
    pageCount,
    publishedDate: trim(book.publishedDate),
  };

  if (existingTraining) {
    await firestoreSet(env, "trainings", trainingId, trainingData, true);
  } else {
    await firestoreSet(env, "trainings", trainingId, {
      ...trainingData,
      createdBy: auth.user.uid,
      createdByRole: "admin",
      createdAt: new Date(),
    });

    const students = await getActiveUsersByRole(env, "student");
    await notifyRecipients(env, students, {
      title: `New Training: ${trainingData.title}`,
      message: `A new training has been posted: ${trainingData.title}.`,
      type: "training",
      targetId: trainingId,
      eventKey: `training:${trainingId}`,
      actorUserId: auth.user.uid,
      logLabel: `[notifyTraining:${trainingId}]`,
    }).catch((error) => {
      console.error("Training notification error:", error);
    });
  }

  return json({
    id: trainingId,
    alreadyExisted: !!existingTraining,
  });
}

async function handleImportYoutubeVideo(request, env) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const video = body.selectedVideo;
  const domain = trim(body.domain).slice(0, 120);
  const level = trim(body.level).slice(0, 50) || "general";
  const language = trim(body.language).slice(0, 20);
  const isFeatured = body.isFeatured === true;

  if (!video || !trim(video.youtubeVideoId)) {
    return err("A valid YouTube video is required.");
  }
  if (!domain) {
    return err("A training domain is required.");
  }
  if (!language) {
    return err("A training language is required.");
  }

  const youtubeVideoId = trim(video.youtubeVideoId);
  const trainingId = `youtube_video_${youtubeVideoId}`;
  const existingTraining = await firestoreGet(env, "trainings", trainingId);
  const existingData = existingTraining?.data || {};

  const trainingData = {
    id: trainingId,
    title: trim(video.title) || "Untitled Video",
    description: trim(video.description).slice(0, 5000),
    provider: trim(video.provider) || "YouTube",
    duration: "Video",
    level,
    link:
      trim(video.link) || `https://www.youtube.com/watch?v=${youtubeVideoId}`,
    createdBy: auth.user.uid,
    createdByRole: "admin",
    type: "video",
    source: "youtube",
    thumbnail: secureThumbnail(video.thumbnail),
    domain,
    language,
    youtubeVideoId,
    isApproved:
      typeof existingData.isApproved === "boolean"
        ? existingData.isApproved
        : true,
    isFeatured: existingTraining
      ? typeof existingData.isFeatured === "boolean"
        ? existingData.isFeatured
        : isFeatured
      : isFeatured,
  };

  if (!existingTraining) {
    trainingData.createdAt = new Date();
  }

  await firestoreSet(env, "trainings", trainingId, trainingData, true);

  if (!existingTraining) {
    const students = await getActiveUsersByRole(env, "student");
    await notifyRecipients(env, students, {
      title: `New Training: ${trainingData.title}`,
      message: `A new training has been posted: ${trainingData.title}.`,
      type: "training",
      targetId: trainingId,
      eventKey: `training:${trainingId}`,
      actorUserId: auth.user.uid,
      logLabel: `[notifyTraining:${trainingId}]`,
    }).catch((error) => {
      console.error("Training notification error:", error);
    });
  }

  return json({
    id: trainingId,
    alreadyExisted: !!existingTraining,
  });
}

async function handleDeleteTraining(request, env, trainingId) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  if (!trainingId) {
    return err("A training resource ID is required.");
  }

  const trainingDoc = await firestoreGet(env, "trainings", trainingId);
  if (!trainingDoc) {
    return err("Training resource not found.", 404);
  }

  await firestoreDelete(env, "trainings", trainingId);

  const savedTrainingRefs = await firestoreQuery(
    env,
    "saved_trainings",
    [{ field: "trainingId", op: "EQUAL", value: trainingId }],
    { allDescendants: true },
  );

  if (savedTrainingRefs.length > 0) {
    await firestoreBatchWrite(
      env,
      savedTrainingRefs.map((item) => ({ delete: item.ref })),
    );
  }

  return json({
    id: trainingId,
    deleted: true,
  });
}

async function handleSetTrainingFeatured(request, env, trainingId) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  if (!trainingId) {
    return err("A training resource ID is required.");
  }

  const body = await request.json();
  if (typeof body.isFeatured !== "boolean") {
    return err("isFeatured must be a boolean.");
  }

  const trainingDoc = await firestoreGet(env, "trainings", trainingId);
  if (!trainingDoc) {
    return err("Training resource not found.", 404);
  }

  await firestoreUpdate(env, "trainings", trainingId, {
    isFeatured: body.isFeatured,
  });

  return json({
    id: trainingId,
    isFeatured: body.isFeatured,
  });
}

async function handleCompanyDeleteOpportunity(request, env, opportunityId) {
  const auth = await requireUser(request, env, { roles: ["company"] });
  if (auth.error) {
    return auth.error;
  }

  if (!opportunityId) {
    return err("An opportunity ID is required.");
  }

  const opportunityDoc = await firestoreGet(
    env,
    "opportunities",
    opportunityId,
  );
  if (!opportunityDoc) {
    return err("Opportunity not found.", 404);
  }

  const opportunity = opportunityDoc.data || {};
  if (trim(opportunity.companyId) !== auth.user.uid) {
    return err("You can only manage your own opportunities.", 403);
  }

  const applications = await firestoreQuery(env, "applications", [
    { field: "opportunityId", op: "EQUAL", value: opportunityId },
    { field: "companyId", op: "EQUAL", value: auth.user.uid },
  ]);

  const pendingApplications = applications.filter(
    (application) =>
      normalizeApplicationStatus(application?.data?.status) === "pending",
  );

  if (pendingApplications.length > 0) {
    await firestoreUpdate(env, "opportunities", opportunityId, {
      status: "closed",
    });

    return json({
      id: opportunityId,
      deleted: false,
      closedInsteadOfDeleted: true,
      applicationsCount: applications.length,
      pendingApplicationsCount: pendingApplications.length,
    });
  }

  const savedRefs = await firestoreQuery(env, "savedOpportunities", [
    { field: "opportunityId", op: "EQUAL", value: opportunityId },
  ]);

  const writes = [
    ...savedRefs.map((item) => ({ delete: item.ref })),
    ...applications.map((item) => ({ delete: item.ref })),
    { delete: `opportunities/${opportunityId}` },
  ];

  await firestoreBatchWrite(env, writes);

  return json({
    id: opportunityId,
    deleted: true,
    closedInsteadOfDeleted: false,
    savedReferencesDeleted: savedRefs.length,
    applicationsDeleted: applications.length,
  });
}

async function expireDeadlineOpportunities(env, { companyId = "" } = {}) {
  const normalizedCompanyId = trim(companyId);

  const now = new Date();
  const openOpportunities = await firestoreQuery(env, "opportunities", [
    { field: "status", op: "EQUAL", value: "open" },
  ]);
  const scopedOpportunities = normalizedCompanyId
    ? openOpportunities.filter(
        (doc) => trim(doc.data?.companyId) === normalizedCompanyId,
      )
    : openOpportunities;
  const expired = scopedOpportunities.filter((doc) =>
    isOpportunityDeadlineExpired(doc.data, now),
  );

  if (expired.length === 0) {
    return {
      checked: scopedOpportunities.length,
      closed: 0,
      closedIds: [],
    };
  }

  const writes = expired.map((doc) => ({
    update: {
      path: `opportunities/${doc.id}`,
      data: {
        status: "closed",
        updatedAt: now,
        closedAt: now,
        closedReason: "deadline_expired",
      },
      mask: ["status", "updatedAt", "closedAt", "closedReason"],
      currentDocument: { exists: true },
    },
  }));

  await firestoreBatchWrite(env, writes);

  return {
    checked: scopedOpportunities.length,
    closed: expired.length,
    closedIds: expired.map((doc) => doc.id),
  };
}

async function handleExpireDeadlines(request, env) {
  const auth = await requireUser(request, env, {
    roles: ["company", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  const isAdmin = auth.profile.role === "admin";
  const result = await expireDeadlineOpportunities(env, {
    companyId: isAdmin ? "" : auth.user.uid,
  });

  return json({
    ...result,
    scope: isAdmin ? "all" : "company",
  });
}

function shouldRunDeadlineReminderSweep(now = new Date()) {
  return now.getUTCHours() === 8 && now.getUTCMinutes() < 5;
}

function activeUserMap(users) {
  const result = new Map();
  for (const user of Array.isArray(users) ? users : []) {
    const id = trim(user?.id);
    if (id) {
      result.set(id, user);
    }
  }
  return result;
}

function addStudentRecipientId(result, value) {
  const id = trim(value);
  if (id) {
    result.add(id);
  }
}

function applicationNeedsDeadlineReminder(application) {
  return normalizeApplicationStatus(application?.status) === "pending";
}

function deadlineReminderRecipients(recipientIds, activeStudentsById) {
  return [...recipientIds]
    .map((id) => activeStudentsById.get(id))
    .filter(Boolean);
}

function emptyDeadlineReminderStats({ skipped = false, reason = "" } = {}) {
  return {
    skipped,
    reason,
    opportunitiesChecked: 0,
    scholarshipsChecked: 0,
    notificationDocsCreated: 0,
    pushSent: 0,
    missingTokens: 0,
    errors: [],
  };
}

function addDeadlineReminderResult(summary, result) {
  if (!result || typeof result !== "object") {
    return;
  }

  summary.notificationDocsCreated += positiveInt(
    result.notificationDocsCreated ?? result.created,
  ) || 0;
  summary.pushSent += positiveInt(result.pushSent ?? result.pushesSent) || 0;
  summary.missingTokens += positiveInt(result.missingTokens) || 0;
  if (Array.isArray(result.errors) && result.errors.length > 0) {
    summary.errors.push(...result.errors);
  }
}

async function notifyOpportunityDeadlineReminder(
  env,
  opportunityDoc,
  activeStudentsById,
  now,
) {
  const opportunityId = trim(opportunityDoc?.id);
  const opportunity = opportunityDoc?.data || {};
  const deadline = opportunityDeadlineDate(opportunity);
  const bucket = deadlineReminderBucket(deadline, now);

  if (
    !opportunityId ||
    !bucket ||
    opportunity.isHidden === true
  ) {
    return null;
  }

  const [savedRefs, applications] = await Promise.all([
    firestoreQuery(env, "savedOpportunities", [
      { field: "opportunityId", op: "EQUAL", value: opportunityId },
    ]).catch(() => []),
    firestoreQuery(env, "applications", [
      { field: "opportunityId", op: "EQUAL", value: opportunityId },
    ]).catch(() => []),
  ]);

  const recipientIds = new Set();
  for (const savedRef of savedRefs) {
    addStudentRecipientId(recipientIds, savedRef?.data?.studentId);
  }
  for (const application of applications) {
    if (applicationNeedsDeadlineReminder(application?.data)) {
      addStudentRecipientId(recipientIds, application?.data?.studentId);
    }
  }

  const recipients = deadlineReminderRecipients(
    recipientIds,
    activeStudentsById,
  );
  if (recipients.length === 0) {
    return null;
  }

  const title = trim(opportunity.title) || "Opportunity";
  return notifyRecipients(env, recipients, {
    title: "Opportunity deadline soon",
    message: `${title} closes ${deadlineRelativeLabel(deadline, now)}.`,
    type: "opportunity",
    targetId: opportunityId,
    eventKey: `deadline:${bucket}:opportunity:${opportunityId}`,
    logLabel: `[deadlineReminder:opportunity:${opportunityId}:${bucket}]`,
  });
}

async function notifyScholarshipDeadlineReminder(
  env,
  scholarshipDoc,
  activeStudentsById,
  now,
) {
  const scholarshipId = trim(scholarshipDoc?.id);
  const scholarship = scholarshipDoc?.data || {};
  const deadline = scholarshipDeadlineDate(scholarship);
  const bucket = deadlineReminderBucket(deadline, now);

  if (!scholarshipId || !bucket || scholarship.isHidden === true) {
    return null;
  }

  const savedRefs = await firestoreQuery(env, "savedScholarships", [
    { field: "scholarshipId", op: "EQUAL", value: scholarshipId },
  ]).catch(() => []);

  const recipientIds = new Set();
  for (const savedRef of savedRefs) {
    addStudentRecipientId(recipientIds, savedRef?.data?.studentId);
  }

  const recipients = deadlineReminderRecipients(
    recipientIds,
    activeStudentsById,
  );
  if (recipients.length === 0) {
    return null;
  }

  const title = trim(scholarship.title) || "Scholarship";
  return notifyRecipients(env, recipients, {
    title: "Scholarship deadline soon",
    message: `${title} closes ${deadlineRelativeLabel(deadline, now)}.`,
    type: "scholarship",
    targetId: scholarshipId,
    eventKey: `deadline:${bucket}:scholarship:${scholarshipId}`,
    logLabel: `[deadlineReminder:scholarship:${scholarshipId}:${bucket}]`,
  });
}

async function sendDeadlineReminders(env, { force = false } = {}) {
  const now = new Date();
  if (!force && !shouldRunDeadlineReminderSweep(now)) {
    return emptyDeadlineReminderStats({
      skipped: true,
      reason: "outside_reminder_window",
    });
  }

  const [students, opportunities, scholarships] = await Promise.all([
    getActiveUsersByRole(env, "student"),
    firestoreQuery(env, "opportunities", [
      { field: "status", op: "EQUAL", value: "open" },
    ]).catch(() => []),
    firestoreQuery(env, "scholarships", []).catch(() => []),
  ]);

  const activeStudentsById = activeUserMap(students);
  const summary = emptyDeadlineReminderStats();
  summary.opportunitiesChecked = opportunities.length;
  summary.scholarshipsChecked = scholarships.length;

  for (const opportunity of opportunities) {
    try {
      const result = await notifyOpportunityDeadlineReminder(
        env,
        opportunity,
        activeStudentsById,
        now,
      );
      addDeadlineReminderResult(summary, result);
    } catch (error) {
      summary.errors.push({
        type: "opportunity",
        id: trim(opportunity?.id),
        message: error?.message ?? "deadline_reminder_failed",
      });
    }
  }

  for (const scholarship of scholarships) {
    try {
      const result = await notifyScholarshipDeadlineReminder(
        env,
        scholarship,
        activeStudentsById,
        now,
      );
      addDeadlineReminderResult(summary, result);
    } catch (error) {
      summary.errors.push({
        type: "scholarship",
        id: trim(scholarship?.id),
        message: error?.message ?? "deadline_reminder_failed",
      });
    }
  }

  return summary;
}

async function handleSendDeadlineReminders(request, env) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  return json(await sendDeadlineReminders(env, { force: true }));
}

function encodeObjectKey(objectKey) {
  return String(objectKey)
    .split("/")
    .filter(Boolean)
    .map((segment) => encodeURIComponent(segment))
    .join("/");
}

function extractObjectKeyFromAccessPath(value) {
  const rawValue = trim(value);
  if (!rawValue) {
    return "";
  }

  const normalizedPath = rawValue.startsWith("file/") ? `/${rawValue}` : rawValue;
  if (!normalizedPath.startsWith("/file/")) {
    return "";
  }

  return normalizedPath
    .slice("/file/".length)
    .split("/")
    .filter(Boolean)
    .map((segment) => decodeURIComponent(segment))
    .join("/");
}

function extractObjectKeyFromUrl(value) {
  const rawValue = trim(value);
  if (!rawValue) {
    return "";
  }

  const directPathMatch = extractObjectKeyFromAccessPath(rawValue);
  if (directPathMatch) {
    return directPathMatch;
  }

  try {
    const url = new URL(rawValue);
    return extractObjectKeyFromAccessPath(url.pathname);
  } catch (_) {
    return "";
  }
}

function normalizeDocumentUrl(value) {
  const rawValue = trim(value);
  if (!rawValue || !/^https?:\/\//i.test(rawValue)) {
    return "";
  }

  return rawValue.replace(/^http:\/\//i, "https://");
}

function resolveStoredObjectKey(...candidates) {
  for (const candidate of candidates) {
    const rawValue = trim(candidate);
    if (!rawValue) {
      continue;
    }

    const derivedObjectKey = extractObjectKeyFromUrl(rawValue);
    if (derivedObjectKey) {
      return derivedObjectKey;
    }

    if (!/^https?:\/\//i.test(rawValue)) {
      return rawValue;
    }
  }

  return "";
}

function resolveDocumentFallbackUrl(...candidates) {
  for (const candidate of candidates) {
    const normalizedUrl = normalizeDocumentUrl(candidate);
    if (normalizedUrl) {
      return normalizedUrl;
    }
  }

  return "";
}

function normalizeDocumentMimeType(value, fileName = "") {
  const normalizedValue = trim(value).toLowerCase();
  if (normalizedValue && normalizedValue !== "application/octet-stream") {
    return normalizedValue;
  }

  const normalizedFileName = trim(fileName).toLowerCase();
  if (normalizedFileName.endsWith(".pdf")) {
    return "application/pdf";
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

  return normalizedValue;
}

function resolveCvVariant(rawValue) {
  return trim(rawValue).toLowerCase() === "built" ? "built" : "primary";
}

function resolveCvDocumentMetadata(cvData, variant) {
  const safeCvData = cvData && typeof cvData === "object" ? cvData : {};
  if (variant === "built") {
    const templateId = trim(safeCvData.templateId) || "builder";
    const fileName =
      trim(safeCvData.exportedPdfFileName) || `cv_${templateId}.pdf`;
    return {
      storagePath: resolveStoredObjectKey(
        safeCvData.exportedPdfPath,
        safeCvData.exportedPdfObjectKey,
        safeCvData.exportedPdfStoragePath,
        safeCvData.exportedPdfAccessPath,
        safeCvData.exportedPdfUrl,
      ),
      fallbackUrl: resolveDocumentFallbackUrl(
        safeCvData.exportedPdfAccessUrl,
        safeCvData.exportedPdfSignedUrl,
        safeCvData.exportedPdfUrl,
      ),
      fileName,
      mimeType: normalizeDocumentMimeType(
        safeCvData.exportedPdfMimeType || "application/pdf",
        fileName,
      ),
    };
  }

  const fileName = trim(safeCvData.uploadedFileName) || "primary_cv.pdf";
  return {
    storagePath: resolveStoredObjectKey(
      safeCvData.uploadedCvPath,
      safeCvData.uploadedCvObjectKey,
      safeCvData.uploadedCvStoragePath,
      safeCvData.uploadedCvAccessPath,
      safeCvData.uploadedCvUrl,
    ),
    fallbackUrl: resolveDocumentFallbackUrl(
      safeCvData.uploadedCvAccessUrl,
      safeCvData.uploadedCvSignedUrl,
      safeCvData.uploadedCvUrl,
    ),
    fileName,
    mimeType: normalizeDocumentMimeType(
      safeCvData.uploadedCvMimeType,
      fileName,
    ),
  };
}

function resolveCommercialRegisterMetadata(companyData) {
  const safeCompanyData =
    companyData && typeof companyData === "object" ? companyData : {};
  const fileName =
    trim(safeCompanyData.commercialRegisterFileName) ||
    "commercial_register.pdf";

  return {
    storagePath: resolveStoredObjectKey(
      safeCompanyData.commercialRegisterStoragePath,
      safeCompanyData.commercialRegisterObjectKey,
      safeCompanyData.commercialRegisterAccessPath,
      safeCompanyData.commercialRegisterUrl,
    ),
    fallbackUrl: resolveDocumentFallbackUrl(
      safeCompanyData.commercialRegisterAccessUrl,
      safeCompanyData.commercialRegisterSignedUrl,
      safeCompanyData.commercialRegisterUrl,
    ),
    fileName,
    mimeType: normalizeDocumentMimeType(
      safeCompanyData.commercialRegisterMimeType,
      fileName,
    ),
  };
}

function resolveChatAttachmentMetadata(messageData) {
  const safeMessageData =
    messageData && typeof messageData === "object" ? messageData : {};
  const fileName = trim(safeMessageData.fileName) || "attachment";

  return {
    storagePath: resolveStoredObjectKey(
      safeMessageData.attachmentStoragePath,
      safeMessageData.storagePath,
      safeMessageData.filePath,
      safeMessageData.attachmentUrl,
      safeMessageData.fileUrl,
    ),
    fallbackUrl: resolveDocumentFallbackUrl(
      safeMessageData.attachmentAccessUrl,
      safeMessageData.attachmentSignedUrl,
      safeMessageData.attachmentUrl,
      safeMessageData.fileUrl,
    ),
    fileName,
    mimeType: normalizeDocumentMimeType(safeMessageData.mimeType, fileName),
  };
}

function buildPublicUserProfile(userId, userData) {
  const safeUserData =
    userData && typeof userData === "object" ? userData : {};
  const photoType = trim(safeUserData.photoType);
  const avatarId = trim(safeUserData.avatarId);
  const role = trim(safeUserData.role);
  const isAdmin = role.toLowerCase() === "admin";

  return {
    uid: trim(userId),
    role,
    email: trim(safeUserData.email),
    phone: trim(safeUserData.phone),
    fullName: isAdmin ? PUBLIC_ADMIN_NAME : trim(safeUserData.fullName),
    companyName: trim(safeUserData.companyName),
    profileImage: trim(safeUserData.profileImage),
    logo: trim(safeUserData.logo),
    photoType: photoType || null,
    avatarId: avatarId || null,
    academicLevel: trim(safeUserData.academicLevel),
    university: trim(safeUserData.university),
    fieldOfStudy: trim(safeUserData.fieldOfStudy),
    bio: trim(safeUserData.bio),
    location: trim(safeUserData.location),
    sector: trim(safeUserData.sector),
    description: trim(safeUserData.description),
    website: trim(safeUserData.website),
    isOnline: safeUserData.isOnline === true,
    lastSeenAt: safeUserData.lastSeenAt || null,
    isActive: safeUserData.isActive !== false,
  };
}

function parseDocumentTimestamp(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  const parsed = Date.parse(trim(value));
  return Number.isFinite(parsed) ? parsed : 0;
}

function hasResolvedDocumentAccess(metadata) {
  return Boolean(trim(metadata?.storagePath) || trim(metadata?.fallbackUrl));
}

function selectBestCvDocument(candidates, variant, preferredCvId = "") {
  const normalizedPreferredCvId = trim(preferredCvId);
  if (!Array.isArray(candidates) || candidates.length === 0) {
    return null;
  }

  const rankedCandidates = [...candidates].sort((left, right) => {
    const leftMetadata = resolveCvDocumentMetadata(left?.data || {}, variant);
    const rightMetadata = resolveCvDocumentMetadata(right?.data || {}, variant);

    const leftPreferred =
      normalizedPreferredCvId && trim(left?.id) === normalizedPreferredCvId ? 1 : 0;
    const rightPreferred =
      normalizedPreferredCvId && trim(right?.id) === normalizedPreferredCvId ? 1 : 0;
    if (leftPreferred !== rightPreferred) {
      return rightPreferred - leftPreferred;
    }

    const leftHasDocument = hasResolvedDocumentAccess(leftMetadata) ? 1 : 0;
    const rightHasDocument = hasResolvedDocumentAccess(rightMetadata) ? 1 : 0;
    if (leftHasDocument !== rightHasDocument) {
      return rightHasDocument - leftHasDocument;
    }

    const leftUpdatedAt = parseDocumentTimestamp(left?.data?.updatedAt);
    const rightUpdatedAt = parseDocumentTimestamp(right?.data?.updatedAt);
    if (leftUpdatedAt !== rightUpdatedAt) {
      return rightUpdatedAt - leftUpdatedAt;
    }

    const leftCreatedAt = parseDocumentTimestamp(left?.data?.createdAt);
    const rightCreatedAt = parseDocumentTimestamp(right?.data?.createdAt);
    if (leftCreatedAt !== rightCreatedAt) {
      return rightCreatedAt - leftCreatedAt;
    }

    return 0;
  });

  return rankedCandidates[0] || null;
}

async function buildSignedStorageFileUrl(
  env,
  objectKey,
  { download = false, ttlSeconds = 600 } = {},
) {
  const storageApiBaseUrl = trim(env.STORAGE_API_BASE_URL).replace(/\/+$/, "");
  const secret = trim(env.FILE_ACCESS_SECRET);
  if (!storageApiBaseUrl || !secret) {
    throw new Error("Secure document access is not configured.");
  }

  const expiresAt = Math.floor(Date.now() / 1000) + ttlSeconds;
  const signature = await createFileAccessSignature({
    secret,
    objectKey,
    expiresAt,
  });
  const encodedObjectKey = encodeObjectKey(objectKey);
  const downloadSuffix = download ? "&download=1" : "";

  return `${storageApiBaseUrl}/file/${encodedObjectKey}?expires=${expiresAt}&signature=${signature}${downloadSuffix}`;
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

async function buildSecureDocumentResponse(env, metadata) {
  const storagePath = trim(metadata?.storagePath);
  const fallbackUrl = normalizeDocumentUrl(metadata?.fallbackUrl);
  if (!storagePath && !fallbackUrl) {
    return null;
  }

  return {
    storagePath,
    fileName: trim(metadata?.fileName),
    mimeType: trim(metadata?.mimeType),
    viewUrl: storagePath
      ? await buildSignedStorageFileUrl(env, storagePath)
      : fallbackUrl,
    downloadUrl: storagePath
      ? await buildSignedStorageFileUrl(env, storagePath, {
          download: true,
        })
      : fallbackUrl,
  };
}

async function loadCvDocumentForStudent(
  env,
  studentId,
  preferredCvId = "",
  variant = "primary",
) {
  const normalizedStudentId = trim(studentId);
  const normalizedCvId = trim(preferredCvId);
  const candidatesById = new Map();

  if (normalizedCvId) {
    const candidateCvDoc = await firestoreGet(env, "cvs", normalizedCvId);
    if (
      candidateCvDoc &&
      trim(candidateCvDoc.data?.studentId) === normalizedStudentId
    ) {
      candidatesById.set(candidateCvDoc.id, candidateCvDoc);
    }
  }

  if (normalizedStudentId) {
    const cvCandidates = await firestoreQuery(env, "cvs", [
      { field: "studentId", op: "EQUAL", value: normalizedStudentId },
    ]);
    for (const cvCandidate of cvCandidates) {
      if (trim(cvCandidate.id)) {
        candidatesById.set(cvCandidate.id, cvCandidate);
      }
    }
  }

  return selectBestCvDocument(
    [...candidatesById.values()],
    variant,
    normalizedCvId,
  );
}

async function handleGetApplicationCv(request, env, applicationId) {
  const auth = await requireUser(request, env, { roles: ["company", "admin"] });
  if (auth.error) {
    return auth.error;
  }

  if (!applicationId) {
    return err("An application ID is required.");
  }

  const applicationDoc = await firestoreGet(env, "applications", applicationId);
  if (!applicationDoc) {
    return err("Application not found.", 404);
  }

  const application = applicationDoc.data || {};
  if (
    auth.profile.role === "company" &&
    trim(application.companyId) !== auth.user.uid
  ) {
    return err("You can only access CVs for your own applications.", 403);
  }

  const applicationStudentId = trim(application.studentId);
  const applicationCvId = trim(application.cvId);
  const cvDoc = await loadCvDocumentForStudent(
    env,
    applicationStudentId,
    applicationCvId,
  );

  if (!cvDoc) {
    return err("CV not found for this application.", 404);
  }

  return json({
    cv: {
      ...cvDoc.data,
      id: cvDoc.id,
    },
  });
}

async function handleGetApplicationCvAccess(request, env, applicationId) {
  const auth = await requireUser(request, env, { roles: ["company", "admin"] });
  if (auth.error) {
    return auth.error;
  }

  if (!applicationId) {
    return err("An application ID is required.");
  }

  const applicationDoc = await firestoreGet(env, "applications", applicationId);
  if (!applicationDoc) {
    return err("Application not found.", 404);
  }

  const application = applicationDoc.data || {};
  if (
    auth.profile.role === "company" &&
    trim(application.companyId) !== auth.user.uid
  ) {
    return err("You can only access CVs for your own applications.", 403);
  }

  const variant = resolveCvVariant(
    new URL(request.url).searchParams.get("variant"),
  );
  const cvDoc = await loadCvDocumentForStudent(
    env,
    trim(application.studentId),
    trim(application.cvId),
    variant,
  );
  if (!cvDoc) {
    return err("CV not found for this application.", 404);
  }

  const document = await buildSecureDocumentResponse(
    env,
    resolveCvDocumentMetadata(cvDoc.data || {}, variant),
  );

  if (!document) {
    return err(
      variant === "built"
        ? "Built CV file not found."
        : "Primary CV file not found.",
      404,
    );
  }

  return json({ document });
}

async function handleGetUserCvAccess(request, env, userId) {
  const auth = await requireUser(request, env, { roles: ["student", "admin"] });
  if (auth.error) {
    return auth.error;
  }

  if (!userId) {
    return err("A user ID is required.");
  }

  if (auth.profile.role === "student" && auth.user.uid !== userId) {
    return err("You can only access your own CV documents.", 403);
  }

  const variant = resolveCvVariant(
    new URL(request.url).searchParams.get("variant"),
  );
  const cvDoc = await loadCvDocumentForStudent(env, userId, "", variant);
  if (!cvDoc) {
    return err("CV not found for this user.", 404);
  }

  const document = await buildSecureDocumentResponse(
    env,
    resolveCvDocumentMetadata(cvDoc.data || {}, variant),
  );

  if (!document) {
    return err(
      variant === "built"
        ? "Built CV file not found."
        : "Primary CV file not found.",
      404,
    );
  }

  return json({ document });
}

async function handleGetPublicUserProfile(request, env, userId) {
  const auth = await requireUser(request, env, {
    roles: ["student", "company", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  if (!userId) {
    return err("A user ID is required.");
  }

  const userDoc = await firestoreGet(env, "users", userId);
  if (!userDoc) {
    return err("User not found.", 404);
  }

  return json({
    user: buildPublicUserProfile(userId, userDoc.data || {}),
  });
}

async function handleSearchChatContacts(request, env) {
  const auth = await requireUser(request, env, {
    roles: ["student", "company"],
  });
  if (auth.error) {
    return auth.error;
  }

  const url = new URL(request.url);
  const role = trim(url.searchParams.get("role")).toLowerCase();
  const query = trim(url.searchParams.get("query")).toLowerCase();
  const authRole = trim(auth.profile?.role).toLowerCase();

  if (role !== "student" && role !== "company") {
    return err("A valid role is required.");
  }

  if (
    (authRole === "student" && role !== "company") ||
    (authRole === "company" && role !== "student")
  ) {
    return err("You can only search eligible chat contacts.", 403);
  }

  const applicationDocs =
    authRole === "student"
      ? await firestoreQuery(env, "applications", [
          { field: "studentId", op: "EQUAL", value: auth.user.uid },
        ])
      : await firestoreQuery(env, "applications", [
          { field: "companyId", op: "EQUAL", value: auth.user.uid },
        ]);

  const eligibleApplicationsByUserId = new Map();
  for (const applicationDoc of applicationDocs) {
    const application = applicationDoc.data || {};
    const status = normalizeApplicationStatus(application.status);
    const targetUserId =
      authRole === "student"
        ? trim(application.companyId)
        : trim(application.studentId);

    if (!targetUserId || targetUserId === auth.user.uid) {
      continue;
    }
    if (authRole === "student" && status !== "accepted") {
      continue;
    }
    if (!eligibleApplicationsByUserId.has(targetUserId)) {
      eligibleApplicationsByUserId.set(targetUserId, {
        id: trim(application.id) || applicationDoc.id,
        status,
        opportunityId: trim(application.opportunityId),
      });
    }
  }

  if (eligibleApplicationsByUserId.size === 0) {
    return json({ users: [] });
  }

  const users = await firestoreQuery(env, "users", [
    { field: "role", op: "EQUAL", value: role },
    { field: "isActive", op: "EQUAL", value: true },
  ]);

  const filteredUsers = users
    .filter((userDoc) => trim(userDoc.id) !== auth.user.uid)
    .filter((userDoc) => eligibleApplicationsByUserId.has(trim(userDoc.id)))
    .map((userDoc) => {
      const profile = buildPublicUserProfile(userDoc.id, userDoc.data || {});
      const application = eligibleApplicationsByUserId.get(trim(userDoc.id));
      return {
        ...profile,
        applicationId: application?.id || "",
        applicationStatus: application?.status || "",
        opportunityId: application?.opportunityId || "",
      };
    })
    .filter((user) => {
      if (!query) {
        return true;
      }

      const haystack = [
        trim(user.companyName),
        trim(user.fullName),
        trim(user.sector),
        trim(user.university),
        trim(user.fieldOfStudy),
        trim(user.location),
      ]
        .join(" ")
        .toLowerCase();

      return haystack.includes(query);
    })
    .sort((left, right) =>
      displayNameForUser(left).localeCompare(displayNameForUser(right)),
    )
    .slice(0, 40);

  return json({ users: filteredUsers });
}

async function handleGetChatAttachmentAccess(
  request,
  env,
  conversationId,
  messageId,
) {
  const auth = await requireUser(request, env, {
    roles: ["student", "company", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  if (!conversationId || !messageId) {
    return err("conversationId and messageId are required.");
  }

  const conversationDoc = await firestoreGet(env, "conversations", conversationId);
  if (!conversationDoc) {
    return err("Conversation not found.", 404);
  }

  const conversation = conversationDoc.data || {};
  const isParticipant =
    auth.profile.role === "admin" ||
    trim(conversation.studentId) === auth.user.uid ||
    trim(conversation.companyId) === auth.user.uid;
  if (!isParticipant) {
    return err("You are not a participant in this conversation.", 403);
  }

  const messageDoc = await firestoreGet(
    env,
    `conversations/${conversationId}/messages`,
    messageId,
  );
  if (!messageDoc) {
    return err("Message not found.", 404);
  }

  const document = await buildSecureDocumentResponse(
    env,
    resolveChatAttachmentMetadata(messageDoc.data || {}),
  );
  if (!document) {
    return err("Attachment not found.", 404);
  }

  return json({ document });
}

async function handleGetCompanyCommercialRegisterAccess(
  request,
  env,
  companyId,
) {
  const auth = await requireUser(request, env, { roles: ["company", "admin"] });
  if (auth.error) {
    return auth.error;
  }

  if (!companyId) {
    return err("A company ID is required.");
  }

  if (auth.profile.role === "company" && auth.user.uid !== companyId) {
    return err(
      "You can only access commercial register documents for your company account.",
      403,
    );
  }

  const companyDoc = await firestoreGet(env, "users", companyId);
  if (!companyDoc || trim(companyDoc.data?.role) !== "company") {
    return err("Company not found.", 404);
  }

  const document = await buildSecureDocumentResponse(
    env,
    resolveCommercialRegisterMetadata(companyDoc.data || {}),
  );
  if (!document) {
    return err("Commercial Register document not found.", 404);
  }

  return json({ document });
}

async function handleNotifyOpportunity(request, env) {
  const auth = await requireUser(request, env, { roles: ["company", "admin"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const opportunityId = trim(body.opportunityId);
  if (!opportunityId) {
    return err("opportunityId is required.");
  }

  const opportunityDoc = await firestoreGet(
    env,
    "opportunities",
    opportunityId,
  );
  if (!opportunityDoc) {
    return err("Opportunity not found.", 404);
  }

  const opportunity = opportunityDoc.data || {};
  if (
    auth.profile.role === "company" &&
    trim(opportunity.companyId) !== auth.user.uid
  ) {
    return err("You can only notify for your own opportunities.", 403);
  }

  if (trim(opportunity.status) && trim(opportunity.status) !== "open") {
    return json({
      created: 0,
      pushSent: 0,
      duplicatesSkipped: 0,
      missingTokens: 0,
      invalidTokens: 0,
      skipped: true,
      reason: "opportunity_not_open",
    });
  }

  const opportunityType = normalizeOpportunityType(opportunity.type);
  if (opportunityType !== "sponsoring") {
    return json({
      created: 0,
      pushSent: 0,
      duplicatesSkipped: 0,
      missingTokens: 0,
      invalidTokens: 0,
      skipped: true,
      reason: "opportunity_type_not_notifiable",
      opportunityType,
    });
  }

  const title = trim(opportunity.title) || "New Opportunity";
  const companyName = trim(opportunity.companyName) || "A company";
  const actorTokens = collectRecipientTokens(auth.profile);

  const students = await getActiveUsersByRole(env, "student");
  const result = await notifyRecipients(env, students, {
    title: `New ${opportunityTypeLabel(opportunityType)}: ${title}`,
    message: `${companyName} posted a new sponsoring opportunity.`,
    type: "opportunity",
    targetId: opportunityId,
    eventKey: `opportunity-sponsoring:${opportunityId}`,
    actorUserId: auth.user.uid,
    excludeUserIds: [trim(opportunity.companyId)],
    excludeTokens: actorTokens,
    logLabel: `[notifyOpportunity:${opportunityId}]`,
  });

  return json(result);
}

async function handleRegisterNotificationToken(request, env) {
  const auth = await requireUser(request, env, {
    roles: ["student", "company", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const token = trim(body.token);
  const platform = normalizeFcmPlatform(body.platform);

  if (!token) {
    return err("token is required.");
  }

  const [primaryMatches, legacyMatches] = await Promise.all([
    firestoreQuery(env, "users", [
      { field: "fcmToken", op: "EQUAL", value: token },
    ]).catch(() => []),
    firestoreQuery(env, "users", [
      { field: "fcmTokens", op: "ARRAY_CONTAINS", value: token },
    ]).catch(() => []),
  ]);

  const now = new Date();
  const duplicateMatches = new Map();
  for (const match of [...primaryMatches, ...legacyMatches]) {
    const userId = trim(match?.id);
    if (!userId || userId === auth.user.uid) {
      continue;
    }
    duplicateMatches.set(userId, {
      id: userId,
      data: match?.data && typeof match.data === "object" ? match.data : {},
    });
  }

  const writes = [
    {
      update: {
        path: `users/${auth.user.uid}`,
        data: {
          fcmToken: token,
          fcmTokenUpdatedAt: now,
          fcmTokenPlatform: platform,
        },
        mask: ["fcmToken", "fcmTokenUpdatedAt", "fcmTokenPlatform"],
      },
    },
  ];

  let duplicatesCleared = 0;
  for (const duplicate of duplicateMatches.values()) {
    const nextData = {
      fcmTokenUpdatedAt: now,
    };
    const mask = ["fcmTokenUpdatedAt"];
    let shouldWrite = false;

    if (trim(duplicate.data?.fcmToken) === token) {
      nextData.fcmToken = "";
      nextData.fcmTokenPlatform = "";
      mask.push("fcmToken", "fcmTokenPlatform");
      shouldWrite = true;
    }

    if (Array.isArray(duplicate.data?.fcmTokens)) {
      const filteredTokens = duplicate.data.fcmTokens.filter((value) => {
        const candidate =
          typeof value === "string"
            ? trim(value)
            : value && typeof value === "object"
              ? trim(value.token)
              : "";
        return candidate && candidate !== token;
      });

      if (filteredTokens.length !== duplicate.data.fcmTokens.length) {
        nextData.fcmTokens = filteredTokens;
        mask.push("fcmTokens");
        shouldWrite = true;
      }
    }

    if (!shouldWrite) {
      continue;
    }

    duplicatesCleared += 1;
    writes.push({
      update: {
        path: `users/${duplicate.id}`,
        data: nextData,
        mask,
      },
    });
  }

  await firestoreBatchWrite(env, writes);

  return json({
    userId: auth.user.uid,
    tokenRegistered: true,
    duplicatesCleared,
    platform,
  });
}

async function handleNotifyScholarship(request, env) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const scholarshipId = trim(body.scholarshipId);
  if (!scholarshipId) {
    return err("scholarshipId is required.");
  }

  const scholarshipDoc = await firestoreGet(env, "scholarships", scholarshipId);
  if (!scholarshipDoc) {
    return err("Scholarship not found.", 404);
  }

  const scholarship = scholarshipDoc.data || {};
  const title = trim(scholarship.title) || "New Scholarship";

  const students = await getActiveUsersByRole(env, "student");
  const result = await notifyRecipients(env, students, {
    title: `New Scholarship: ${title}`,
    message: `A new scholarship has been posted: ${title}.`,
    type: "scholarship",
    targetId: scholarshipId,
    eventKey: `scholarship:${scholarshipId}`,
    actorUserId: auth.user.uid,
    logLabel: `[notifyScholarship:${scholarshipId}]`,
  });

  return json(result);
}

async function handleNotifyApplicationSubmitted(request, env) {
  const auth = await requireUser(request, env, { roles: ["student"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const applicationId = trim(body.applicationId);
  if (!applicationId) {
    return err("applicationId is required.");
  }

  const applicationDoc = await firestoreGet(env, "applications", applicationId);
  if (!applicationDoc) {
    return err("Application not found.", 404);
  }

  const application = applicationDoc.data || {};
  if (trim(application.studentId) !== auth.user.uid) {
    return err("You can only notify for your own application.", 403);
  }

  const opportunityId = trim(application.opportunityId);
  const opportunityDoc = opportunityId
    ? await firestoreGet(env, "opportunities", opportunityId)
    : null;
  const opportunity = opportunityDoc?.data || {};
  const companyId = trim(opportunity.companyId) || trim(application.companyId);

  if (!companyId) {
    return err("The application does not have a valid company recipient.", 400);
  }

  const companyDoc = await firestoreGet(env, "users", companyId);
  if (!companyDoc) {
    return err("The company recipient could not be resolved.", 404);
  }

  const studentName =
    trim(application.studentName) || displayNameForUser(auth.profile);
  const opportunityTitle = trim(opportunity.title) || "your opportunity";
  const actorTokens = collectRecipientTokens(auth.profile);

  const result = await notifyRecipients(env, [companyDoc], {
    title: "New Application",
    message: `${studentName} applied to ${opportunityTitle}.`,
    type: "application",
    targetId: applicationId,
    eventKey: `application-submitted:${applicationId}`,
    actorUserId: auth.user.uid,
    excludeTokens: actorTokens,
    logLabel: `[notifyApplicationSubmitted:${applicationId}]`,
  });

  return json(result);
}

async function handleNotifyApplicationStatusChanged(request, env) {
  const auth = await requireUser(request, env, { roles: ["company", "admin"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const applicationId = trim(body.applicationId);
  if (!applicationId) {
    return err("applicationId is required.");
  }

  const applicationDoc = await firestoreGet(env, "applications", applicationId);
  if (!applicationDoc) {
    return err("Application not found.", 404);
  }

  const application = applicationDoc.data || {};
  if (
    auth.profile.role === "company" &&
    trim(application.companyId) !== auth.user.uid
  ) {
    return err("You can only notify for your own application decisions.", 403);
  }

  const status = normalizeApplicationStatus(application.status);
  if (status !== "accepted" && status !== "rejected") {
    return json({
      created: 0,
      pushSent: 0,
      duplicatesSkipped: 0,
      missingTokens: 0,
      invalidTokens: 0,
      skipped: true,
      reason: "application_status_not_notifiable",
    });
  }

  const studentId = trim(application.studentId);
  if (!studentId) {
    return err("The application does not have a valid student recipient.", 400);
  }

  const studentDoc = await firestoreGet(env, "users", studentId);
  if (!studentDoc) {
    return err("The student recipient could not be resolved.", 404);
  }

  const opportunityTitle = trim(
    (await firestoreGet(env, "opportunities", trim(application.opportunityId)))
      ?.data?.title,
  );
  const companyName =
    auth.profile.role === "company"
      ? displayNameForUser(auth.profile)
      : displayNameForUser(
          (await firestoreGet(env, "users", trim(application.companyId)))
            ?.data || {},
        );
  const statusLabel = status === "accepted" ? "Approved" : "Rejected";
  const notificationType = status === "rejected" ? "rejected" : "application";
  const actorTokens = collectRecipientTokens(auth.profile);
  const pendingNotificationsRead = await markNotificationsReadByEventKey(
    env,
    `application-submitted:${applicationId}`,
  );

  const result = await notifyRecipients(env, [studentDoc], {
    title: `Application ${statusLabel}`,
    message: opportunityTitle
      ? `Your application to ${opportunityTitle} was ${status === "accepted" ? "approved" : "rejected"} by ${companyName}.`
      : `Your application was ${status === "accepted" ? "approved" : "rejected"} by ${companyName}.`,
    type: notificationType,
    targetId: applicationId,
    route: `/notifications/application/${encodeURIComponent(applicationId)}`,
    eventKey: `application-status:${applicationId}:${status}`,
    actorUserId: auth.user.uid,
    excludeTokens: actorTokens,
    logLabel: `[notifyApplicationStatusChanged:${applicationId}:${status}]`,
  });

  return json({
    ...result,
    pendingNotificationsMarkedRead: pendingNotificationsRead.markedRead,
  });
}

async function handleNotifyCompanyRegistration(request, env) {
  const auth = await requireUser(request, env, { roles: ["company"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const companyId = trim(body.companyId) || auth.user.uid;
  if (!companyId) {
    return err("companyId is required.");
  }
  if (companyId !== auth.user.uid) {
    return err(
      "You can only notify for your own company registration.",
      403,
    );
  }

  const companyDoc = await firestoreGet(env, "users", companyId);
  if (!companyDoc) {
    return err("Company not found.", 404);
  }

  const company = companyDoc.data || {};
  if (trim(company.role) !== "company") {
    return err("Only company accounts can trigger this notification.", 400);
  }

  const companyName =
    trim(company.companyName) || displayNameForUser(company) || "New company";
  const admins = await getActiveUsersByRole(env, "admin");
  const actorTokens = collectRecipientTokens(auth.profile);

  const result = await notifyRecipients(env, admins, {
    title: "New Company Review",
    message: `${companyName} registered and is waiting for approval.`,
    type: "company_review",
    targetId: companyId,
    eventKey: `company-registration:${companyId}`,
    actorUserId: auth.user.uid,
    excludeUserIds: [auth.user.uid],
    excludeTokens: actorTokens,
    logLabel: `[notifyCompanyRegistration:${companyId}]`,
  });

  return json(result);
}

async function handleNotifyCompanyApprovalStatusChanged(request, env) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const companyId = trim(body.companyId);
  if (!companyId) {
    return err("companyId is required.");
  }

  const companyDoc = await firestoreGet(env, "users", companyId);
  if (!companyDoc) {
    return err("Company not found.", 404);
  }

  const company = companyDoc.data || {};
  if (trim(company.role) !== "company") {
    return err("Only company accounts can receive this notification.", 400);
  }

  const status = normalizeCompanyApprovalStatus(company.approvalStatus);
  if (status !== "approved" && status !== "rejected") {
    return json({
      created: 0,
      pushSent: 0,
      duplicatesSkipped: 0,
      missingTokens: 0,
      invalidTokens: 0,
      skipped: true,
      reason: "company_status_not_notifiable",
      status,
    });
  }

  const approved = status === "approved";
  const pendingNotificationsRead = await markNotificationsReadByEventKey(
    env,
    `company-registration:${companyId}`,
  );
  const result = await notifyRecipients(env, [companyDoc], {
    title: approved ? "Company Account Approved" : "Company Account Rejected",
    message: approved
      ? "Your company account has been approved. You can now access the company workspace."
      : "Your company registration was rejected. Please contact support if you think this is a mistake.",
    type: "company_status",
    targetId: companyId,
    route: `/notifications/company-status/${encodeURIComponent(companyId)}`,
    eventKey: `company-approval:${companyId}:${status}`,
    actorUserId: auth.user.uid,
    excludeUserIds: [auth.user.uid],
    excludeTokens: collectRecipientTokens(auth.profile),
    includeInactiveRecipients: true,
    logLabel: `[notifyCompanyApproval:${companyId}:${status}]`,
  });

  return json({
    ...result,
    pendingNotificationsMarkedRead: pendingNotificationsRead.markedRead,
  });
}

async function handleNotifyProjectIdeaSubmitted(request, env) {
  const auth = await requireUser(request, env, { roles: ["student"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const ideaId = trim(body.ideaId);
  if (!ideaId) {
    return err("ideaId is required.");
  }

  const ideaDoc = await firestoreGet(env, "projectIdeas", ideaId);
  if (!ideaDoc) {
    return err("Project idea not found.", 404);
  }

  const idea = ideaDoc.data || {};
  if (trim(idea.submittedBy) !== auth.user.uid) {
    return err(
      "You can only notify for your own project idea submission.",
      403,
    );
  }

  const admins = await getActiveUsersByRole(env, "admin");
  const ideaTitle = trim(idea.title) || "Untitled idea";
  const actorTokens = collectRecipientTokens(auth.profile);

  const result = await notifyRecipients(env, admins, {
    title: "New Project Idea",
    message: `A new idea "${ideaTitle}" needs review.`,
    type: "project_idea",
    targetId: ideaId,
    eventKey: `project-idea-submitted:${ideaId}`,
    actorUserId: auth.user.uid,
    excludeUserIds: [auth.user.uid],
    excludeTokens: actorTokens,
    logLabel: `[notifyProjectIdeaSubmitted:${ideaId}]`,
  });

  return json(result);
}

async function handleSubmitProjectIdea(request, env) {
  const auth = await requireUser(request, env, { roles: ["student"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const title = normalizeIdeaValue(body.title);
  const description = normalizeIdeaValue(body.description);
  const domain = normalizeIdeaValue(body.domain);
  const level = normalizeIdeaValue(body.level, { lowerCase: true });
  const tools = normalizeIdeaValue(body.tools);
  const originalLanguage = normalizeIdeaValue(body.originalLanguage, {
    lowerCase: true,
  });
  const tagline = normalizeIdeaValue(body.tagline);
  const shortDescription =
    normalizeIdeaValue(body.shortDescription) || tagline || description;
  const category = normalizeIdeaValue(body.category) || domain;
  const tags = normalizeIdeaList(body.tags);
  const stage = normalizeIdeaValue(body.stage) || "Concept";
  const skillsNeeded = normalizeIdeaList(body.skillsNeeded);
  const teamNeeded = normalizeIdeaList(body.teamNeeded);
  const targetAudience = normalizeIdeaValue(body.targetAudience);
  const problemStatement = normalizeIdeaValue(body.problemStatement);
  const solution = normalizeIdeaValue(body.solution);
  const resourcesNeeded = normalizeIdeaValue(body.resourcesNeeded);
  const benefits = normalizeIdeaValue(body.benefits);
  const imageUrl = normalizeIdeaValue(body.imageUrl);
  const attachmentUrl = normalizeIdeaValue(body.attachmentUrl);
  const isPublic =
    body.isPublic === false || String(body.isPublic).toLowerCase() === "false"
      ? false
      : true;

  if (!title) {
    return err("A project idea title is required.");
  }
  if (!description) {
    return err("A project idea description is required.");
  }
  if (!domain) {
    return err("A project idea domain is required.");
  }
  if (!["bac", "licence", "master", "doctorat"].includes(level)) {
    return err("A valid project idea level is required.");
  }

  const { id: ideaId, dedupeKey } = await stableProjectIdeaIdentity({
    submittedBy: auth.user.uid,
    title,
    description,
    domain,
    level,
    tools,
    stage,
    skillsNeeded,
    teamNeeded,
  });

  const ideaData = {
    id: ideaId,
    title,
    description,
    domain,
    level,
    tools,
    originalLanguage,
    tagline,
    shortDescription,
    category,
    tags,
    stage,
    skillsNeeded,
    teamNeeded,
    targetAudience,
    problemStatement,
    solution,
    resourcesNeeded,
    benefits,
    imageUrl,
    attachmentUrl,
    isPublic,
    status: "pending",
    submittedBy: auth.user.uid,
    submittedByName: displayNameForUser(auth.profile),
    authorAvatar: trim(auth.profile?.profileImage),
    authorPhotoType: trim(auth.profile?.photoType),
    authorAvatarId: trim(auth.profile?.avatarId),
    createdAt: new Date(),
    updatedAt: new Date(),
    dedupeKey,
  };

  let ideaCreated = false;
  const writeResults = await firestoreBatchWrite(env, [
    {
      update: {
        path: `projectIdeas/${ideaId}`,
        data: ideaData,
        currentDocument: { exists: false },
      },
    },
  ]);
  const createResult = writeResults[0] || {
    ok: false,
    code: 0,
    message: "unknown_error",
  };

  if (createResult.ok) {
    ideaCreated = true;
  } else if (!isDuplicateWriteError(createResult.code)) {
    return err("Project idea submission failed. Please try again.", 500);
  }

  const ideaDoc = ideaCreated
    ? { id: ideaId, data: ideaData }
    : await firestoreGet(env, "projectIdeas", ideaId);
  if (!ideaDoc) {
    return err("Project idea submission could not be verified.", 500);
  }

  const admins = await getActiveUsersByRole(env, "admin");
  const actorTokens = collectRecipientTokens(auth.profile);
  const ideaTitle = trim(ideaDoc.data?.title) || title || "Untitled idea";

  const notifyResult = await notifyRecipients(env, admins, {
    title: "New Project Idea",
    message: `A new idea "${ideaTitle}" needs review.`,
    type: "project_idea",
    targetId: ideaId,
    eventKey: `project-idea-submitted:${ideaId}`,
    actorUserId: auth.user.uid,
    excludeUserIds: [auth.user.uid],
    excludeTokens: actorTokens,
    logLabel: `[submitProjectIdea:${ideaId}]`,
  });

  return json({
    id: ideaId,
    ideaCreated,
    alreadySubmitted: !ideaCreated,
    notification: notifyResult,
  });
}

async function handleGetProjectIdeaEngagement(request, env) {
  const auth = await requireUser(request, env, {
    roles: ["student", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  const url = new URL(request.url);
  const ideaIds = uniqueTrimmedStrings(
    trim(url.searchParams.get("ideaIds"))
      .split(",")
      .map((value) => trim(value)),
  );

  if (ideaIds.length === 0) {
    return json(buildIdeaEngagementSnapshot([], auth.user.uid));
  }

  const accessibleIdeaIds = await resolveAccessibleIdeaIds(env, ideaIds, auth);
  if (accessibleIdeaIds.length === 0) {
    return json(buildIdeaEngagementSnapshot([], auth.user.uid));
  }

  const interactionDocs = await listIdeaInteractionDocs(env, accessibleIdeaIds);
  return json(buildIdeaEngagementSnapshot(interactionDocs, auth.user.uid));
}

async function handleGetSavedProjectIdeas(request, env) {
  const auth = await requireUser(request, env, {
    roles: ["student", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  const interactionDocs = await firestoreQuery(env, "projectIdeaInteractions", [
    { field: "userId", op: "EQUAL", value: auth.user.uid },
  ]);

  const saveDocs = interactionDocs.filter((doc) => {
    const data = doc?.data && typeof doc.data === "object" ? doc.data : {};
    return normalizeIdeaInteractionType(data.type) === "save";
  });

  const ideaDocs = await Promise.all(
    saveDocs.map((doc) => {
      const ideaId = trim(doc?.data?.ideaId);
      return ideaId ? firestoreGet(env, "projectIdeas", ideaId) : null;
    }),
  );

  const savedItems = saveDocs
    .map((doc, index) => {
      const data = doc?.data && typeof doc.data === "object" ? doc.data : {};
      const ideaId = trim(data.ideaId);
      const ideaDoc = ideaDocs[index];

      if (!ideaId || !ideaDoc) {
        return null;
      }

      if (
        !canAccessProjectIdea(
          ideaDoc.data || {},
          auth.user.uid,
          auth.profile?.role,
        )
      ) {
        return null;
      }

      return {
        id: trim(doc.id),
        ideaId,
        createdAt: data.createdAt || null,
      };
    })
    .filter(Boolean)
    .sort(
      (left, right) =>
        parseDocumentTimestamp(right.createdAt) -
        parseDocumentTimestamp(left.createdAt),
    );

  return json({ savedItems });
}

function resolveProjectIdeaImageMetadata(ideaData) {
  const safeIdeaData =
    ideaData && typeof ideaData === "object" ? ideaData : {};
  const storagePath = resolveStoredObjectKey(
    safeIdeaData.imageStoragePath,
    safeIdeaData.imageObjectKey,
    safeIdeaData.imageAccessPath,
    safeIdeaData.imageUrl,
  );
  const fallbackUrl = resolveDocumentFallbackUrl(
    safeIdeaData.imageSignedUrl,
    safeIdeaData.imageAccessUrl,
    safeIdeaData.imageUrl,
  );
  const objectKeyFromUrl = extractObjectKeyFromUrl(safeIdeaData.imageUrl);
  const fileName =
    trim(safeIdeaData.imageFileName) ||
    trim(storagePath).split("/").filter(Boolean).pop() ||
    trim(objectKeyFromUrl).split("/").filter(Boolean).pop() ||
    "idea_cover.jpg";

  return {
    storagePath,
    fallbackUrl,
    fileName,
    mimeType: normalizeDocumentMimeType(safeIdeaData.imageMimeType, fileName),
  };
}

async function handleGetProjectIdeaImageAccess(request, env, ideaId) {
  const auth = await requireUser(request, env, {
    roles: ["student", "company", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  if (!ideaId) {
    return err("A project idea ID is required.");
  }

  const ideaDoc = await firestoreGet(env, "projectIdeas", ideaId);
  if (!ideaDoc) {
    return err("Project idea not found.", 404);
  }

  if (
    !canAccessProjectIdea(ideaDoc.data || {}, auth.user.uid, auth.profile?.role)
  ) {
    return err("You do not have permission to access this idea image.", 403);
  }

  const document = await buildSecureDocumentResponse(
    env,
    resolveProjectIdeaImageMetadata(ideaDoc.data || {}),
  );
  if (!document || !trim(document.viewUrl)) {
    return err("Project idea image not found.", 404);
  }

  return json({ document });
}

async function handleSetProjectIdeaInteraction(request, env) {
  const auth = await requireUser(request, env, {
    roles: ["student", "admin"],
  });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const ideaId = trim(body.ideaId);
  const type = normalizeIdeaInteractionType(body.type);
  const enabled =
    body.enabled === false || String(body.enabled).toLowerCase() === "false"
      ? false
      : true;

  if (!ideaId) {
    return err("ideaId is required.");
  }
  if (!type) {
    return err("A valid project idea interaction type is required.");
  }

  const ideaDoc = await firestoreGet(env, "projectIdeas", ideaId);
  if (!ideaDoc) {
    return err("Project idea not found.", 404);
  }

  if (
    !canAccessProjectIdea(ideaDoc.data || {}, auth.user.uid, auth.profile?.role)
  ) {
    return err("You do not have permission to interact with this idea.", 403);
  }

  const interactionId = buildProjectIdeaInteractionId({
    ideaId,
    userId: auth.user.uid,
    type,
  });

  if (enabled) {
    await firestoreSet(env, "projectIdeaInteractions", interactionId, {
      id: interactionId,
      ideaId,
      userId: auth.user.uid,
      type,
      createdAt: new Date(),
    });
  } else {
    await firestoreDelete(env, "projectIdeaInteractions", interactionId);
  }

  return json({
    id: interactionId,
    ideaId,
    type,
    enabled,
  });
}

async function handleNotifyIdeaStatusChanged(request, env) {
  const auth = await requireUser(request, env, { roles: ["admin"] });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const ideaId = trim(body.ideaId);
  if (!ideaId) {
    return err("ideaId is required.");
  }

  const ideaDoc = await firestoreGet(env, "projectIdeas", ideaId);
  if (!ideaDoc) {
    return err("Project idea not found.", 404);
  }

  const idea = ideaDoc.data || {};
  const status = trim(idea.status);
  if (status !== "approved" && status !== "rejected") {
    return json({
      created: 0,
      pushSent: 0,
      duplicatesSkipped: 0,
      missingTokens: 0,
      invalidTokens: 0,
      skipped: true,
      reason: "idea_status_not_notifiable",
    });
  }

  const ownerId = trim(idea.submittedBy);
  if (!ownerId) {
    return err("The project idea does not have a valid owner.", 400);
  }

  const ownerDoc = await firestoreGet(env, "users", ownerId);
  if (!ownerDoc) {
    return err("The project idea owner could not be resolved.", 404);
  }

  const statusLabel = status === "approved" ? "Approved" : "Rejected";
  const ideaTitle = trim(idea.title) || "your idea";
  const actorTokens = collectRecipientTokens(auth.profile);
  const pendingNotificationsRead = await markNotificationsReadByEventKey(
    env,
    `project-idea-submitted:${ideaId}`,
  );

  const result = await notifyRecipients(env, [ownerDoc], {
    title: `Project Idea ${statusLabel}`,
    message: `Your idea "${ideaTitle}" has been ${status}.`,
    type: "project_idea",
    targetId: ideaId,
    eventKey: `project-idea-status:${ideaId}:${status}`,
    actorUserId: auth.user.uid,
    excludeUserIds: [auth.user.uid],
    excludeTokens: actorTokens,
    logLabel: `[notifyIdeaStatusChanged:${ideaId}:${status}]`,
  });

  return json({
    ...result,
    pendingNotificationsMarkedRead: pendingNotificationsRead.markedRead,
  });
}

async function handleNotifyChatMessage(request, env) {
  const auth = await requireUser(request, env, {
    roles: ["student", "company"],
  });
  if (auth.error) {
    return auth.error;
  }

  const body = await request.json();
  const conversationId = trim(body.conversationId);
  const messageId = trim(body.messageId);
  const messageText = truncateMessage(body.message || "");

  if (!conversationId) {
    return err("conversationId is required.");
  }
  if (!messageId) {
    return err("messageId is required.");
  }

  const conversationDoc = await firestoreGet(
    env,
    "conversations",
    conversationId,
  );
  if (!conversationDoc) {
    return err("Conversation not found.", 404);
  }

  const conversation = conversationDoc.data || {};
  const studentId = trim(conversation.studentId);
  const companyId = trim(conversation.companyId);
  const isStudentSender = auth.user.uid === studentId;
  const isCompanySender = auth.user.uid === companyId;

  if (!isStudentSender && !isCompanySender) {
    return err("You are not a participant in this conversation.", 403);
  }

  const recipientId = isStudentSender ? companyId : studentId;
  if (!recipientId || recipientId === auth.user.uid) {
    return json({
      created: 0,
      pushSent: 0,
      duplicatesSkipped: 0,
      missingTokens: 0,
      invalidTokens: 0,
      skipped: true,
      reason: "self_notification_skipped",
    });
  }

  if (
    Array.isArray(conversation.mutedBy) &&
    conversation.mutedBy.map((value) => trim(value)).includes(recipientId)
  ) {
    return json({
      created: 0,
      pushSent: 0,
      duplicatesSkipped: 0,
      missingTokens: 0,
      invalidTokens: 0,
      skipped: true,
      reason: "conversation_muted",
    });
  }

  const recipientDoc = await firestoreGet(env, "users", recipientId);
  if (!recipientDoc) {
    return err("The chat recipient could not be resolved.", 404);
  }

  const senderName = isStudentSender
    ? trim(conversation.studentName) || displayNameForUser(auth.profile)
    : trim(conversation.companyName) || displayNameForUser(auth.profile);

  const result = await notifyRecipients(env, [recipientDoc], {
    title: `New message from ${senderName}`,
    message: messageText || "You received a new message.",
    type: "chat",
    conversationId,
    eventKey: `chat:${messageId}`,
    actorUserId: auth.user.uid,
    logLabel: `[notifyChatMessage:${messageId}]`,
  });

  return json(result);
}

// ── AI Message Processing (Groq) ─────────────────────────────────────

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.3-70b-versatile";
const AI_MAX_TEXT_LENGTH = 2000;

const AI_SYSTEM_PROMPTS = {
  formal: [
    "You are a message assistant. Rewrite the following message to be professional, polite, and concise.",
    "Keep the original meaning. Do NOT invent any experience, qualifications, or facts.",
    "Return ONLY the rewritten message, nothing else.",
  ].join(" "),
  correct: [
    "You are a grammar and spelling assistant. Fix grammar, spelling, and clarity in the following message.",
    "Keep the same language. Do NOT change the meaning or add new information.",
    "Return ONLY the corrected message, nothing else.",
  ].join(" "),
  translate: [
    "You are a translation assistant. Translate the following message to TARGET_LANGUAGE.",
    "Keep it natural, professional, and accurate. Preserve the original meaning.",
    "Return ONLY the translated message, nothing else.",
  ].join(" "),
};

async function handleAiMessage(request, env) {
  const apiKey = env.GROQ_API_KEY;
  if (!apiKey) {
    return err("AI service not configured", 500);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON body");
  }

  const task = trim(body.task).toLowerCase();
  const text = trim(body.text);
  const targetLanguage = trim(body.targetLanguage);

  if (!["formal", "correct", "translate"].includes(task)) {
    return err("Invalid task. Must be: formal, correct, or translate");
  }

  if (!text) {
    return err("Text is required");
  }

  if (text.length > AI_MAX_TEXT_LENGTH) {
    return err(`Text exceeds maximum length of ${AI_MAX_TEXT_LENGTH} characters`);
  }

  if (task === "translate" && !targetLanguage) {
    return err("targetLanguage is required for translate task");
  }

  let systemPrompt = AI_SYSTEM_PROMPTS[task];
  if (task === "translate") {
    systemPrompt = systemPrompt.replace("TARGET_LANGUAGE", targetLanguage);
  }

  try {
    const groqResponse = await fetch(GROQ_API_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: text },
        ],
        temperature: 0.3,
        max_tokens: 1024,
      }),
    });

    if (!groqResponse.ok) {
      const errorBody = await groqResponse.text();
      console.error("[aiMessage] Groq API error:", groqResponse.status, errorBody);
      return err("AI processing failed", 502);
    }

    const groqData = await groqResponse.json();
    const result = groqData?.choices?.[0]?.message?.content;

    if (!result) {
      return err("AI returned empty result", 502);
    }

    return json({ success: true, result: result.trim() });
  } catch (error) {
    console.error("[aiMessage] Error:", error?.message ?? error);
    return err("AI processing failed", 500);
  }
}

function matchRoute(method, path) {
  if (method === "GET" && path === "/api/health") {
    return { handler: "health" };
  }
  if (method === "POST" && path === "/api/auth/password-reset") {
    return { handler: "passwordReset" };
  }
  if (method === "POST" && path === "/api/project-ideas/submit") {
    return { handler: "submitProjectIdea" };
  }
  if (method === "GET" && path === "/api/project-ideas/engagement") {
    return { handler: "getProjectIdeaEngagement" };
  }
  if (method === "GET" && path === "/api/project-ideas/saved") {
    return { handler: "getSavedProjectIdeas" };
  }
  const projectIdeaImageAccessRoute = path.match(
    /^\/api\/project-ideas\/([^/]+)\/image\/access$/,
  );
  if (method === "GET" && projectIdeaImageAccessRoute) {
    return {
      handler: "getProjectIdeaImageAccess",
      id: decodeURIComponent(projectIdeaImageAccessRoute[1]),
    };
  }
  if (method === "POST" && path === "/api/project-ideas/interactions") {
    return { handler: "setProjectIdeaInteraction" };
  }
  if (method === "POST" && path === "/api/search/google-books") {
    return { handler: "searchBooks" };
  }
  if (method === "POST" && path === "/api/search/youtube") {
    return { handler: "searchYoutube" };
  }
  if (method === "POST" && path === "/api/trainings/import/google-book") {
    return { handler: "importBook" };
  }
  if (method === "POST" && path === "/api/trainings/import/youtube-video") {
    return { handler: "importYoutubeVideo" };
  }
  if (method === "POST" && path === "/api/notifications/register-token") {
    return { handler: "registerNotificationToken" };
  }
  if (method === "POST" && path === "/api/deadlines/expire") {
    return { handler: "expireDeadlines" };
  }
  if (method === "POST" && path === "/api/deadlines/reminders") {
    return { handler: "sendDeadlineReminders" };
  }
  if (method === "POST" && path === "/api/notify/opportunity") {
    return { handler: "notifyOpportunity" };
  }
  if (method === "POST" && path === "/api/notify/scholarship") {
    return { handler: "notifyScholarship" };
  }
  if (method === "POST" && path === "/api/notify/company-registration") {
    return { handler: "notifyCompanyRegistration" };
  }
  if (method === "POST" && path === "/api/notify/company-approval-status") {
    return { handler: "notifyCompanyApprovalStatusChanged" };
  }
  if (method === "POST" && path === "/api/notify/application-submitted") {
    return { handler: "notifyApplicationSubmitted" };
  }
  if (method === "POST" && path === "/api/notify/application-status-changed") {
    return { handler: "notifyApplicationStatusChanged" };
  }
  if (method === "POST" && path === "/api/notify/project-idea-submitted") {
    return { handler: "notifyProjectIdeaSubmitted" };
  }
  if (method === "POST" && path === "/api/notify/idea-status-changed") {
    return { handler: "notifyIdeaStatusChanged" };
  }
  if (method === "POST" && path === "/api/notify/chat-message") {
    return { handler: "notifyChatMessage" };
  }
  if (method === "GET" && path === "/api/chat/contacts") {
    return { handler: "searchChatContacts" };
  }
  if (method === "POST" && path === "/api/ai/message") {
    return { handler: "aiMessage" };
  }

  const applicationCvRoute = path.match(/^\/api\/applications\/([^/]+)\/cv$/);
  if (method === "GET" && applicationCvRoute) {
    return {
      handler: "getApplicationCv",
      id: decodeURIComponent(applicationCvRoute[1]),
    };
  }

  const applicationCvAccessRoute = path.match(
    /^\/api\/applications\/([^/]+)\/cv\/access$/,
  );
  if (method === "GET" && applicationCvAccessRoute) {
    return {
      handler: "getApplicationCvAccess",
      id: decodeURIComponent(applicationCvAccessRoute[1]),
    };
  }

  const userCvAccessRoute = path.match(/^\/api\/users\/([^/]+)\/cv\/access$/);
  if (method === "GET" && userCvAccessRoute) {
    return {
      handler: "getUserCvAccess",
      id: decodeURIComponent(userCvAccessRoute[1]),
    };
  }

  const publicUserProfileRoute = path.match(
    /^\/api\/users\/([^/]+)\/public-profile$/,
  );
  if (method === "GET" && publicUserProfileRoute) {
    return {
      handler: "getPublicUserProfile",
      id: decodeURIComponent(publicUserProfileRoute[1]),
    };
  }

  const chatAttachmentRoute = path.match(
    /^\/api\/conversations\/([^/]+)\/messages\/([^/]+)\/attachment\/access$/,
  );
  if (method === "GET" && chatAttachmentRoute) {
    return {
      handler: "getChatAttachmentAccess",
      conversationId: decodeURIComponent(chatAttachmentRoute[1]),
      messageId: decodeURIComponent(chatAttachmentRoute[2]),
    };
  }

  const companyCommercialRegisterRoute = path.match(
    /^\/api\/companies\/([^/]+)\/commercial-register\/access$/,
  );
  if (method === "GET" && companyCommercialRegisterRoute) {
    return {
      handler: "getCompanyCommercialRegisterAccess",
      id: decodeURIComponent(companyCommercialRegisterRoute[1]),
    };
  }

  const companyOpportunityRoute = path.match(
    /^\/api\/company\/opportunities\/([^/]+)$/,
  );
  if (method === "DELETE" && companyOpportunityRoute) {
    return {
      handler: "companyDeleteOpportunity",
      id: decodeURIComponent(companyOpportunityRoute[1]),
    };
  }

  const featuredRoute = path.match(/^\/api\/trainings\/([^/]+)\/featured$/);
  if (method === "POST" && featuredRoute) {
    return {
      handler: "setTrainingFeatured",
      id: decodeURIComponent(featuredRoute[1]),
    };
  }

  const deleteRoute = path.match(/^\/api\/trainings\/([^/]+)$/);
  if (method === "DELETE" && deleteRoute) {
    return {
      handler: "deleteTraining",
      id: decodeURIComponent(deleteRoute[1]),
    };
  }

  return null;
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return withCors(new Response(null, { status: 204 }), request, env);
    }

    const route = matchRoute(request.method, new URL(request.url).pathname);
    if (!route) {
      return withCors(err("Not found", 404), request, env);
    }

    try {
      let response;

      switch (route.handler) {
        case "health":
          response = handleHealth();
          break;
        case "passwordReset":
          response = await handlePasswordReset(request, env);
          break;
        case "submitProjectIdea":
          response = await handleSubmitProjectIdea(request, env);
          break;
        case "getProjectIdeaEngagement":
          response = await handleGetProjectIdeaEngagement(request, env);
          break;
        case "getSavedProjectIdeas":
          response = await handleGetSavedProjectIdeas(request, env);
          break;
        case "getProjectIdeaImageAccess":
          response = await handleGetProjectIdeaImageAccess(
            request,
            env,
            route.id,
          );
          break;
        case "setProjectIdeaInteraction":
          response = await handleSetProjectIdeaInteraction(request, env);
          break;
        case "searchBooks":
          response = await handleSearchBooks(request, env);
          break;
        case "searchYoutube":
          response = await handleSearchYoutube(request, env);
          break;
        case "importBook":
          response = await handleImportBook(request, env);
          break;
        case "importYoutubeVideo":
          response = await handleImportYoutubeVideo(request, env);
          break;
        case "registerNotificationToken":
          response = await handleRegisterNotificationToken(request, env);
          break;
        case "expireDeadlines":
          response = await handleExpireDeadlines(request, env);
          break;
        case "sendDeadlineReminders":
          response = await handleSendDeadlineReminders(request, env);
          break;
        case "deleteTraining":
          response = await handleDeleteTraining(request, env, route.id);
          break;
        case "setTrainingFeatured":
          response = await handleSetTrainingFeatured(request, env, route.id);
          break;
        case "notifyOpportunity":
          response = await handleNotifyOpportunity(request, env);
          break;
        case "notifyScholarship":
          response = await handleNotifyScholarship(request, env);
          break;
        case "notifyCompanyRegistration":
          response = await handleNotifyCompanyRegistration(request, env);
          break;
        case "notifyCompanyApprovalStatusChanged":
          response = await handleNotifyCompanyApprovalStatusChanged(
            request,
            env,
          );
          break;
        case "notifyApplicationSubmitted":
          response = await handleNotifyApplicationSubmitted(request, env);
          break;
        case "notifyApplicationStatusChanged":
          response = await handleNotifyApplicationStatusChanged(request, env);
          break;
        case "notifyProjectIdeaSubmitted":
          response = await handleNotifyProjectIdeaSubmitted(request, env);
          break;
        case "notifyIdeaStatusChanged":
          response = await handleNotifyIdeaStatusChanged(request, env);
          break;
        case "notifyChatMessage":
          response = await handleNotifyChatMessage(request, env);
          break;
        case "searchChatContacts":
          response = await handleSearchChatContacts(request, env);
          break;
        case "aiMessage":
          response = await handleAiMessage(request, env);
          break;
        case "getApplicationCv":
          response = await handleGetApplicationCv(request, env, route.id);
          break;
        case "getApplicationCvAccess":
          response = await handleGetApplicationCvAccess(request, env, route.id);
          break;
        case "getUserCvAccess":
          response = await handleGetUserCvAccess(request, env, route.id);
          break;
        case "getPublicUserProfile":
          response = await handleGetPublicUserProfile(request, env, route.id);
          break;
        case "getChatAttachmentAccess":
          response = await handleGetChatAttachmentAccess(
            request,
            env,
            route.conversationId,
            route.messageId,
          );
          break;
        case "getCompanyCommercialRegisterAccess":
          response = await handleGetCompanyCommercialRegisterAccess(
            request,
            env,
            route.id,
          );
          break;
        case "companyDeleteOpportunity":
          response = await handleCompanyDeleteOpportunity(
            request,
            env,
            route.id,
          );
          break;
        default:
          response = err("Not found", 404);
          break;
      }

      return withCors(response, request, env);
    } catch (error) {
      console.error(
        `Unhandled worker error [${route.handler}]:`,
        error?.message ?? error,
        error?.stack ?? "",
      );
      return withCors(
        err(
          `Internal server error [${route.handler}]: ${error?.message ?? "unknown"}`,
          500,
        ),
        request,
        env,
      );
    }
  },
  async scheduled(event, env, ctx) {
    ctx.waitUntil(
      Promise.all([
        expireDeadlineOpportunities(env),
        sendDeadlineReminders(env),
      ]),
    );
  },
};
