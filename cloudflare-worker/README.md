# FutureGate Cloudflare Worker Backend

Cloudflare Worker backend that replaces the Firebase Functions runtime paths for search, training admin actions, and notification orchestration.

## Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/health` | none | Health check |
| `POST` | `/api/auth/password-reset` | none | Sends a reset email only when the account has email/password sign-in linked |
| `POST` | `/api/search/google-books` | signed-in user | Google Books proxy |
| `POST` | `/api/search/youtube` | signed-in user | YouTube proxy |
| `POST` | `/api/trainings/import/google-book` | admin | Import Google Book and notify students |
| `POST` | `/api/trainings/import/youtube-video` | admin | Import YouTube video and notify students |
| `POST` | `/api/trainings/:id/featured` | admin | Toggle training featured status |
| `DELETE` | `/api/trainings/:id` | admin | Delete training and saved references |
| `POST` | `/api/deadlines/expire` | company or admin | Close expired opportunities; companies only affect their own posts |
| `POST` | `/api/notify/opportunity` | company or admin | Notify students about a new sponsoring opportunity |
| `POST` | `/api/notify/scholarship` | admin | Notify students about a new scholarship |
| `POST` | `/api/notify/application-submitted` | student | Notify the company after an application is created |
| `POST` | `/api/notify/application-status-changed` | company or admin | Notify the student after accept/reject |
| `POST` | `/api/notify/project-idea-submitted` | student | Notify admins about a new project idea |
| `POST` | `/api/notify/idea-status-changed` | admin | Notify the idea owner after moderation |
| `POST` | `/api/notify/chat-message` | student or company | Notify the other conversation participant |

## Required secrets

Set these with Wrangler:

```bash
wrangler secret put GOOGLE_BOOKS_API_KEY
wrangler secret put YOUTUBE_API_KEY
wrangler secret put FIREBASE_PROJECT_ID
wrangler secret put FIREBASE_SERVICE_ACCOUNT_KEY
wrangler secret put FIREBASE_WEB_API_KEY
wrangler secret put ALLOWED_ORIGINS
```

Chargily return pages should be real URLs, not Wrangler commands. In PowerShell:

```powershell
"https://payment.futuregate.tech/success" | npx wrangler secret put FUTUREGATE_SUCCESS_URL
"https://payment.futuregate.tech/failed" | npx wrangler secret put FUTUREGATE_FAILURE_URL
"https://avenirdz-api.yasserabh13.workers.dev/api/webhooks/chargily" | npx wrangler secret put CHARGILY_WEBHOOK_URL
```

When Wrangler prompts interactively, paste only the URL value for the secret.

`FIREBASE_SERVICE_ACCOUNT_KEY` is the full Firebase service-account JSON string. The Worker uses it for Firestore REST access, FCM HTTP v1 sends, and admin Identity Platform lookups.

`FIREBASE_WEB_API_KEY` should be the public Firebase Web API key from the same project. The Worker uses it for `accounts:createAuthUri` so it can detect whether an email has `password`, `google.com`, or both sign-in methods before sending reset emails.

## Local development

```bash
cd cloudflare-worker
npm install
npm run dev
```

## Deploy

```bash
cd cloudflare-worker
npm run deploy
```

After deploy, keep the Worker base URL aligned in:

- `lib/utils/constants.dart`
- `admin-web/public/js/google-books-config.js`

Scholarship notifications are now expected to be triggered from the admin website after a scholarship document is created. Existing scholarship documents can also be re-sent through the admin moderation list without creating duplicates because the Worker de-duplicates by event key.

## What the Worker does for notifications

For Worker-owned notification events it:

- validates the Firebase ID token
- checks role/ownership against Firestore
- resolves recipients from Firestore
- writes in-app notification documents
- sends device push through FCM HTTP v1
- de-duplicates by event key
- excludes the acting user and their registered device tokens from self-notifications
- clears invalid FCM tokens on failure
