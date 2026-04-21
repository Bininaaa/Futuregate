/**
 * FutureGate Firebase config for the custom email action page.
 *
 * This page does not redirect users into the website after completing an action.
 * It stays self-contained and only powers the Firebase email action workflow.
 */

const firebaseConfig = {
  apiKey: "AIzaSyDcQlwKznxxnom_W5nIhC4uT1HyxSAOqHk",
  authDomain: "futuregate.tech",
  projectId: "avenirdz-7305d",
  appId: "1:620923930909:web:5583407a1c39bdcae9f9f4",
};

function isPlaceholder(value) {
  return typeof value !== "string" || value.trim() === "" || value.startsWith("YOUR_");
}

function setIfRealValue(target, key, value) {
  if (!isPlaceholder(value)) {
    target[key] = value.trim();
  }
}

function buildFirebaseConfig(apiKeyFromQuery) {
  const config = {
    authDomain: firebaseConfig.authDomain,
  };

  const resolvedApiKey = isPlaceholder(apiKeyFromQuery)
    ? firebaseConfig.apiKey
    : apiKeyFromQuery;

  setIfRealValue(config, "apiKey", resolvedApiKey);
  setIfRealValue(config, "projectId", firebaseConfig.projectId);
  setIfRealValue(config, "appId", firebaseConfig.appId);

  return config;
}

function hasUsableFirebaseConfig(apiKeyFromQuery) {
  return !isPlaceholder(apiKeyFromQuery) || !isPlaceholder(firebaseConfig.apiKey);
}

export {
  buildFirebaseConfig,
  firebaseConfig,
  hasUsableFirebaseConfig,
};
