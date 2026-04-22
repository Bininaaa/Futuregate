# Cloudflare Worker Notification Architecture

## Runtime status

Notification delivery no longer depends on Firebase Functions. The deployed runtime is now:

- Firebase Auth for user sign-in and ID tokens
- Firestore for primary app data and in-app notification documents
- Cloudflare Worker for protected backend routes, recipient resolution, and FCM HTTP v1 push sends

The old `functions/` directory has been removed from the repository.

## Worker-owned routes

The Worker now handles:

- `POST /api/search/google-books`
- `POST /api/search/youtube`
- `POST /api/trainings/import/google-book`
- `POST /api/trainings/import/youtube-video`
- `POST /api/trainings/:id/featured`
- `DELETE /api/trainings/:id`
- `POST /api/notify/opportunity`
- `POST /api/notify/scholarship`
- `POST /api/notify/application-submitted`
- `POST /api/notify/application-status-changed`
- `POST /api/notify/project-idea-submitted`
- `POST /api/notify/idea-status-changed`
- `POST /api/notify/chat-message`

## Notification flow pattern

For Worker-owned notification events the app or admin UI now follows the same pattern:

1. Write the business record to Firestore.
2. Call the protected Worker endpoint with the saved document id.
3. Let the Worker validate the caller, resolve recipients, write in-app notification documents, send FCM push, de-duplicate by event key, and clear invalid tokens.

## Scholarship flow

Scholarships are no longer expected to be created manually in Firebase Console.

- Admin web now includes a scholarship creation form.
- After a scholarship document is saved, the page calls `POST /api/notify/scholarship`.
- Existing scholarship records can be backfilled with the list-level `Notify` action.
- Duplicate sends are avoided by the Worker event key for each scholarship document.

## Deploy steps

1. Deploy the Cloudflare Worker.
2. Deploy Firestore rules and indexes as usual.
3. Deploy Firebase Hosting targets:
   `npm run deploy:hosting:root` for `futuregate.tech`
   `npm run deploy:hosting:admin` for the admin site
4. Do not deploy Firebase Functions.
