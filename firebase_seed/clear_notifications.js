const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function loadServiceAccount() {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    return JSON.parse(inlineJson);
  }

  const configuredPath =
      process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localPath = path.join(__dirname, 'service-account.local.json');
  const candidatePath = configuredPath || localPath;

  if (!fs.existsSync(candidatePath)) {
    throw new Error(
      [
        'Missing Firebase Admin credentials.',
        'Set FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT_PATH,',
        'or GOOGLE_APPLICATION_CREDENTIALS, or place a local file at',
        `"${localPath}".`,
      ].join(' '),
    );
  }

  return JSON.parse(fs.readFileSync(candidatePath, 'utf8'));
}

function readArg(prefix) {
  const match = process.argv.find((arg) => arg.startsWith(prefix));
  if (!match) {
    return null;
  }

  return match.slice(prefix.length).trim() || null;
}

function parseBatchSize() {
  const rawValue = readArg('--batch-size=');
  if (rawValue == null) {
    return 400;
  }

  const parsed = Number.parseInt(rawValue, 10);
  if (!Number.isFinite(parsed) || parsed <= 0 || parsed > 450) {
    throw new Error(
      'Invalid --batch-size value. Use a number between 1 and 450.',
    );
  }

  return parsed;
}

async function clearNotifications() {
  admin.initializeApp({
    credential: admin.credential.cert(loadServiceAccount()),
  });

  const db = admin.firestore();
  const userId = readArg('--user-id=');
  const batchSize = parseBatchSize();

  let deletedCount = 0;

  while (true) {
    let query = db.collection('notifications').limit(batchSize);
    if (userId != null) {
      query = query.where('userId', '==', userId).limit(batchSize);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
    }

    await batch.commit();
    deletedCount += snapshot.size;
    console.log(`Deleted ${deletedCount} notification document(s)...`);

    if (snapshot.size < batchSize) {
      break;
    }
  }

  const scopeLabel =
      userId == null ? 'all users' : `user "${userId}"`;
  console.log(
    `Finished deleting ${deletedCount} notification document(s) for ${scopeLabel}.`,
  );
}

clearNotifications().catch((error) => {
  console.error('Failed to clear notifications:', error);
  process.exit(1);
});
