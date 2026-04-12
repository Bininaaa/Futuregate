const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const CONFIRMATION = 'DELETE_ALL_CONVERSATIONS';
const BATCH_LIMIT = 450;

function loadServiceAccount() {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    return JSON.parse(inlineJson);
  }

  const configuredPath =
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localPath = path.join(__dirname, '..', 'firebase_seed', 'service-account.local.json');
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

function readConfirmation(args) {
  const confirmIndex = args.indexOf('--confirm');
  if (confirmIndex === -1) {
    return '';
  }
  return args[confirmIndex + 1] || '';
}

function chunk(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

async function deleteRefs(db, refs, dryRun) {
  if (dryRun || refs.length === 0) {
    return;
  }

  for (const refsChunk of chunk(refs, BATCH_LIMIT)) {
    const batch = db.batch();
    for (const ref of refsChunk) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--help') || args.includes('-h')) {
    console.log('Usage: node tools/delete_all_conversations.js [--confirm DELETE_ALL_CONVERSATIONS]');
    console.log('Runs as a dry-run unless the exact confirmation flag is provided.');
    return;
  }

  const dryRun = readConfirmation(args) !== CONFIRMATION;

  admin.initializeApp({
    credential: admin.credential.cert(loadServiceAccount()),
  });

  const db = admin.firestore();
  const conversationsSnapshot = await db.collection('conversations').get();
  let messageCount = 0;
  let conversationCount = 0;

  for (const conversationDoc of conversationsSnapshot.docs) {
    conversationCount += 1;

    const messagesSnapshot = await conversationDoc.ref
      .collection('messages')
      .get();
    messageCount += messagesSnapshot.size;

    await deleteRefs(
      db,
      messagesSnapshot.docs.map((doc) => doc.ref),
      dryRun,
    );
    await deleteRefs(db, [conversationDoc.ref], dryRun);
  }

  const mode = dryRun ? 'Dry run' : 'Deleted';
  console.log(`${mode}: ${conversationCount} conversations`);
  console.log(`${mode}: ${messageCount} messages`);

  if (dryRun) {
    console.log(
      `No data was deleted. Re-run with --confirm ${CONFIRMATION} to delete all conversations and messages.`,
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
