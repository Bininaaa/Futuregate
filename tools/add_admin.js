const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const admin = require('firebase-admin');

function loadServiceAccount() {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    return JSON.parse(inlineJson);
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

  return JSON.parse(fs.readFileSync(candidatePath, 'utf8'));
}

function parseArgs(argv) {
  const parsed = {};

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith('--')) {
      continue;
    }

    const normalized = token.slice(2);
    const [rawKey, inlineValue] = normalized.split('=');
    const key = rawKey.trim();
    const nextToken = argv[index + 1];
    const hasSeparatedValue =
      inlineValue == null && nextToken != null && !nextToken.startsWith('--');

    if (inlineValue != null) {
      parsed[key] = inlineValue.trim();
      continue;
    }

    if (hasSeparatedValue) {
      parsed[key] = nextToken.trim();
      index += 1;
      continue;
    }

    parsed[key] = 'true';
  }

  return parsed;
}

function requireArg(args, key) {
  const value = (args[key] || '').trim();
  if (!value) {
    throw new Error(`Missing required argument --${key}.`);
  }
  return value;
}

function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

function defaultDisplayNameForEmail(email) {
  const localPart = email.split('@')[0] || 'Admin';
  return localPart
    .split(/[._-]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function generateTemporaryPassword() {
  return `FG!${crypto.randomBytes(9).toString('base64url')}9a`;
}

function safeTrim(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function pickFirstUserDoc(snapshot) {
  if (snapshot.empty) {
    return null;
  }

  if (snapshot.docs.length > 1) {
    throw new Error(
      `Multiple Firestore users found for ${snapshot.docs[0].data().email}. Resolve duplicates before continuing.`,
    );
  }

  return snapshot.docs[0];
}

async function findAuthUserByEmail(auth, email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    if (
      error.code === 'auth/user-not-found' ||
      error.errorInfo?.code === 'auth/user-not-found'
    ) {
      return null;
    }
    throw error;
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const email = normalizeEmail(requireArg(args, 'email'));
  const providedName = safeTrim(args.name);
  const displayName = providedName || defaultDisplayNameForEmail(email);
  const requestedAdminLevel = safeTrim(args.level) || 'admin';
  const requestedUid = safeTrim(args.uid);

  admin.initializeApp({
    credential: admin.credential.cert(loadServiceAccount()),
  });

  const auth = admin.auth();
  const db = admin.firestore();

  const authUser = await findAuthUserByEmail(auth, email);
  const firestoreQuery = await db
    .collection('users')
    .where('email', '==', email)
    .limit(2)
    .get();
  const firestoreDoc = pickFirstUserDoc(firestoreQuery);
  const firestoreData = firestoreDoc?.data() || null;

  const targetUid =
    requestedUid ||
    authUser?.uid ||
    safeTrim(firestoreData?.uid) ||
    firestoreDoc?.id ||
    '';

  let finalAuthUser = authUser;
  let temporaryPassword = '';

  if (finalAuthUser == null) {
    temporaryPassword = safeTrim(args.password) || generateTemporaryPassword();
    finalAuthUser = await auth.createUser({
      uid: targetUid || undefined,
      email,
      password: temporaryPassword,
      displayName,
      emailVerified: false,
    });
  } else {
    const updates = {};
    if (displayName && finalAuthUser.displayName !== displayName) {
      updates.displayName = displayName;
    }
    if (safeTrim(args.password)) {
      updates.password = safeTrim(args.password);
      temporaryPassword = updates.password;
    }
    if (Object.keys(updates).length > 0) {
      finalAuthUser = await auth.updateUser(finalAuthUser.uid, updates);
    }
  }

  if (firestoreDoc && firestoreDoc.id !== finalAuthUser.uid) {
    throw new Error(
      [
        `Firestore user for ${email} exists at users/${firestoreDoc.id},`,
        `but Firebase Auth uses UID ${finalAuthUser.uid}.`,
        'Resolve the mismatch before continuing.',
      ].join(' '),
    );
  }

  const userRef = db.collection('users').doc(finalAuthUser.uid);
  const existingSnapshot = await userRef.get();
  const existingData = existingSnapshot.exists ? existingSnapshot.data() : {};

  await userRef.set(
    {
      uid: finalAuthUser.uid,
      email,
      fullName: displayName,
      role: 'admin',
      adminLevel: requestedAdminLevel,
      isActive: true,
      provider: safeTrim(existingData?.provider) || 'email',
      phone: safeTrim(existingData?.phone),
      location: safeTrim(existingData?.location),
      profileImage: safeTrim(existingData?.profileImage),
      academicLevel: safeTrim(existingData?.academicLevel),
      university: safeTrim(existingData?.university),
      fieldOfStudy: safeTrim(existingData?.fieldOfStudy),
      bio: safeTrim(existingData?.bio),
      companyName: safeTrim(existingData?.companyName),
      sector: safeTrim(existingData?.sector),
      description: safeTrim(existingData?.description),
      website: safeTrim(existingData?.website),
      logo: safeTrim(existingData?.logo),
      researchTopic: safeTrim(existingData?.researchTopic),
      laboratory: safeTrim(existingData?.laboratory),
      supervisor: safeTrim(existingData?.supervisor),
      researchDomain: safeTrim(existingData?.researchDomain),
      createdAt:
        existingData?.createdAt || admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log('');
  console.log('Admin upsert completed successfully.');
  console.log(`Email: ${email}`);
  console.log(`UID: ${finalAuthUser.uid}`);
  console.log(`Display name: ${displayName}`);
  console.log(`Admin level: ${requestedAdminLevel}`);
  console.log(`Firestore document: users/${finalAuthUser.uid}`);

  if (temporaryPassword) {
    console.log(`Temporary password: ${temporaryPassword}`);
  } else {
    console.log('Password: unchanged');
  }

  await admin.app().delete();
}

main().catch(async (error) => {
  console.error(error.message || error);
  if (admin.apps.length > 0) {
    await admin.app().delete();
  }
  process.exit(1);
});
