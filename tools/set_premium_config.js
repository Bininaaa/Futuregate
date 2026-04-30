const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const DOCUMENT_PATH = 'appConfig/premiumConfig';
const PREMIUM_CONFIG = {
  premiumPassPrice: 1500,
  premiumCurrency: 'DZD',
  premiumPassDurationDays: 180,
  freeSavedItemsLimit: 10,
  premiumSavedItemsLimit: -1,
  earlyAccessDefaultDelayHours: 48,
  premiumEnabled: true,
  earlyAccessEnabled: true,
  premiumPlan: 'semester',
  paymentMode: 'test',
};

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function loadExpectedProjectId() {
  const firebasercPath = path.join(__dirname, '..', '.firebaserc');
  const googleServicesPath = path.join(
    __dirname,
    '..',
    'android',
    'app',
    'google-services.json',
  );

  const firebasercProjectId = readJson(firebasercPath).projects?.default;
  const googleServicesProjectId =
    readJson(googleServicesPath).project_info?.project_id;

  if (!firebasercProjectId) {
    throw new Error('Missing default project in .firebaserc.');
  }

  if (googleServicesProjectId && googleServicesProjectId !== firebasercProjectId) {
    throw new Error(
      [
        'Firebase project mismatch:',
        `.firebaserc has ${firebasercProjectId},`,
        `but google-services.json has ${googleServicesProjectId}.`,
      ].join(' '),
    );
  }

  return firebasercProjectId;
}

function loadServiceAccount(expectedProjectId) {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    const parsed = JSON.parse(inlineJson);
    assertCredentialProject(parsed, expectedProjectId);
    return parsed;
  }

  const configuredPath =
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localPath = path.join(
    __dirname,
    '..',
    'firebase_seed',
    'service-account.local.json',
  );
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

  const parsed = readJson(candidatePath);
  assertCredentialProject(parsed, expectedProjectId);
  return parsed;
}

function assertCredentialProject(serviceAccount, expectedProjectId) {
  if (serviceAccount.project_id !== expectedProjectId) {
    throw new Error(
      [
        'Firebase Admin credential project mismatch:',
        `expected ${expectedProjectId},`,
        `got ${serviceAccount.project_id || 'unknown'}.`,
      ].join(' '),
    );
  }
}

function orderedDocumentData(data) {
  const ordered = {};

  for (const key of Object.keys(PREMIUM_CONFIG)) {
    if (Object.prototype.hasOwnProperty.call(data, key)) {
      ordered[key] = data[key];
    }
  }

  for (const key of Object.keys(data).sort()) {
    if (!Object.prototype.hasOwnProperty.call(ordered, key)) {
      ordered[key] = data[key];
    }
  }

  return ordered;
}

async function main() {
  const projectId = loadExpectedProjectId();
  const serviceAccount = loadServiceAccount(projectId);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId,
  });

  const db = admin.firestore();
  const docRef = db.doc(DOCUMENT_PATH);
  const before = await docRef.get();

  await docRef.set(PREMIUM_CONFIG, { merge: true });

  const after = await docRef.get();
  const finalData = after.exists ? after.data() : {};

  console.log(
    JSON.stringify(
      {
        method: 'Firebase Admin SDK',
        projectId,
        path: DOCUMENT_PATH,
        action: before.exists ? 'updated' : 'created',
        merge: true,
        values: orderedDocumentData(finalData),
      },
      null,
      2,
    ),
  );

  await admin.app().delete();
}

main().catch(async (error) => {
  console.error(error.message || error);
  if (admin.apps.length > 0) {
    await admin.app().delete();
  }
  process.exit(1);
});
