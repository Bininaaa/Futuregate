/**
 * FutureGate custom Firebase email action handler.
 *
 * Manual setup:
 * 1. Paste your Firebase Web app config into ./firebase-config.js.
 * 2. In Firebase Console > Authentication > Templates, use this custom action URL:
 *    https://futuregate.tech/auth/action
 * 3. This page is intentionally self-contained and does not redirect users into the website.
 */
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import {
  applyActionCode,
  checkActionCode,
  confirmPasswordReset,
  getAuth,
  verifyPasswordResetCode,
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import {
  buildFirebaseConfig,
  hasUsableFirebaseConfig,
} from "./firebase-config.js";

const elements = {
  flashBanner: document.getElementById("flashBanner"),
  networkBanner: document.getElementById("networkBanner"),
  pageContent: document.getElementById("pageContent"),
  pageEyebrow: document.getElementById("pageEyebrow"),
  pageSubtitle: document.getElementById("pageSubtitle"),
  pageTitle: document.getElementById("pageTitle"),
  statusChip: document.getElementById("statusChip"),
};

const params = readActionParams();

let auth;

window.addEventListener("online", updateNetworkBanner);
window.addEventListener("offline", updateNetworkBanner);

void bootstrap();

async function bootstrap() {
  applyDocumentLanguage(params.lang);
  updateNetworkBanner();

  if (!params.mode || !params.oobCode) {
    renderStateCard({
      tone: "error",
      eyebrow: "Invalid link",
      chip: "Unavailable",
      title: "This link is incomplete",
      subtitle: "The required action details are missing.",
      body: "Open the latest FutureGate email and try again.",
      actions: [createClosePageAction()],
    });
    return;
  }

  if (!hasUsableFirebaseConfig(params.apiKey)) {
    renderStateCard({
      tone: "error",
      eyebrow: "Configuration required",
      chip: "Setup needed",
      title: "Firebase config is missing",
      subtitle: "Add your Firebase Web config before deploying this page.",
      body: "This handler needs a valid apiKey from config or from the action link.",
      actions: [createClosePageAction()],
    });
    return;
  }

  try {
    const app = initializeApp(buildFirebaseConfig(params.apiKey));
    auth = getAuth(app);
    auth.languageCode = normalizeLang(params.lang);
  } catch (error) {
    renderStateCard({
      tone: "error",
      eyebrow: "Configuration issue",
      chip: "Setup needed",
      title: "This page could not start",
      subtitle: "Review firebase-config.js and deploy again.",
      body: getUnexpectedErrorMessage(error),
      actions: [createClosePageAction()],
    });
    return;
  }

  switch (params.mode) {
    case "resetPassword":
      await handleResetPassword();
      return;
    case "verifyEmail":
      await handleVerifyEmail();
      return;
    case "verifyAndChangeEmail":
      await handleVerifyAndChangeEmail();
      return;
    case "recoverEmail":
      await handleRecoverEmail();
      return;
    default:
      renderStateCard({
        tone: "error",
        eyebrow: "Unsupported action",
        chip: "Not available",
        title: "This action is not supported here",
        subtitle:
          "Supported modes are resetPassword, verifyEmail, verifyAndChangeEmail, and recoverEmail.",
        body: "Return to FutureGate if you need a new email.",
        actions: [createClosePageAction()],
      });
  }
}

async function handleResetPassword() {
  setPageCopy({
    eyebrow: "Password reset",
    chip: "Reset password",
    title: "Reset your password",
    subtitle: "Choose a new password.",
  });
  clearFlashBanner();
  renderLoadingState(
    "Checking link",
    "Please wait a moment."
  );

  try {
    const email = await verifyPasswordResetCode(auth, params.oobCode);
    renderResetPasswordForm(email);
  } catch (error) {
    renderTerminalError("resetPassword", error);
  }
}

async function handleVerifyEmail() {
  setPageCopy({
    eyebrow: "Email verification",
    chip: "Verify email",
    title: "Verifying your email",
    subtitle: "Please wait a moment.",
  });
  clearFlashBanner();
  renderLoadingState(
    "Verifying email",
    "Please wait a moment."
  );

  try {
    await applyActionCode(auth, params.oobCode);
    renderStateCard({
      tone: "success",
      eyebrow: "Email verified",
      chip: "Done",
      title: "Your email is verified",
      subtitle: "This email is now confirmed for your FutureGate account.",
      body: "You can close this page.",
      actions: [createClosePageAction()],
    });
  } catch (error) {
    renderTerminalError("verifyEmail", error);
  }
}

async function handleVerifyAndChangeEmail() {
  setPageCopy({
    eyebrow: "Email change",
    chip: "Verify new email",
    title: "Confirming your new email",
    subtitle: "Please wait a moment.",
  });
  clearFlashBanner();
  renderLoadingState(
    "Checking link",
    "Please wait a moment."
  );

  try {
    const info = await checkActionCode(auth, params.oobCode);
    const details = extractVerifyAndChangeEmailDetails(info);

    renderLoadingState(
      "Updating email",
      "Please wait a moment."
    );

    await applyActionCode(auth, params.oobCode);

    renderVerifyAndChangeEmailSuccess(details);
  } catch (error) {
    renderTerminalError("verifyAndChangeEmail", error);
  }
}

async function handleRecoverEmail() {
  setPageCopy({
    eyebrow: "Email recovery",
    chip: "Recover email",
    title: "Restore your previous email",
    subtitle: "Confirm this request.",
  });
  clearFlashBanner();
  renderLoadingState(
    "Checking link",
    "Please wait a moment."
  );

  try {
    const info = await checkActionCode(auth, params.oobCode);
    renderRecoverEmailForm(extractRecoverEmailDetails(info));
  } catch (error) {
    renderTerminalError("recoverEmail", error);
  }
}

function renderResetPasswordForm(email) {
  setPageCopy({
    eyebrow: "Password reset",
    chip: "Reset password",
    title: "Reset your password",
    subtitle: "Choose a new password with at least 8 characters.",
  });

  elements.pageContent.innerHTML = [
    '<section class="form-panel">',
    '  <div class="form-stack">',
    '    <div class="detail-card">',
    '      <span class="detail-label">Email</span>',
    '      <span class="detail-value" id="resetEmailValue"></span>',
    "    </div>",
    '  </div>',
    '  <form class="auth-form" id="resetPasswordForm" novalidate>',
    '    <fieldset id="resetPasswordFieldset">',
    '      <div class="field-group">',
    '        <label class="field-label" for="newPassword">New password</label>',
    '        <div class="input-shell">',
    '          <input class="text-input" id="newPassword" name="newPassword" type="password" minlength="8" autocomplete="new-password" required aria-describedby="newPasswordHint newPasswordError">',
    '          <button class="input-toggle" type="button" data-toggle-password="newPassword" aria-controls="newPassword" aria-pressed="false">Show</button>',
    "        </div>",
    '        <p class="field-hint" id="newPasswordHint">Minimum 8 characters.</p>',
    '        <p class="field-error hidden" id="newPasswordError">Use at least 8 characters.</p>',
    "      </div>",
    '      <div class="field-group">',
    '        <label class="field-label" for="confirmPassword">Confirm password</label>',
    '        <div class="input-shell">',
    '          <input class="text-input" id="confirmPassword" name="confirmPassword" type="password" minlength="8" autocomplete="new-password" required aria-describedby="confirmPasswordError">',
    '          <button class="input-toggle" type="button" data-toggle-password="confirmPassword" aria-controls="confirmPassword" aria-pressed="false">Show</button>',
    "        </div>",
    '        <p class="field-error hidden" id="confirmPasswordError">Passwords must match.</p>',
    "      </div>",
    '      <p class="validation-text" id="resetValidation">Use at least 8 characters.</p>',
    '      <div class="action-row">',
    '        <button class="button button-primary" id="resetSubmitButton" type="submit" disabled>Update password</button>',
    '        <button class="button button-secondary" id="resetCloseButton" type="button">Close</button>',
    "      </div>",
    "    </fieldset>",
    "  </form>",
    "</section>",
  ].join("");

  elements.pageContent.setAttribute("aria-busy", "false");

  const emailValue = document.getElementById("resetEmailValue");
  const form = document.getElementById("resetPasswordForm");
  const fieldset = document.getElementById("resetPasswordFieldset");
  const passwordInput = document.getElementById("newPassword");
  const confirmInput = document.getElementById("confirmPassword");
  const passwordError = document.getElementById("newPasswordError");
  const confirmError = document.getElementById("confirmPasswordError");
  const validation = document.getElementById("resetValidation");
  const submitButton = document.getElementById("resetSubmitButton");
  const closeButton = document.getElementById("resetCloseButton");

  let isSubmitting = false;

  emailValue.textContent = email || "FutureGate account";
  attachPasswordToggles();
  closeButton.addEventListener("click", attemptClosePage);

  const syncFormState = () => {
    const password = passwordInput.value;
    const confirmation = confirmInput.value;
    const passwordTooShort = password.length > 0 && password.length < 8;
    const confirmationMismatch =
      confirmation.length > 0 && password.length >= 8 && password !== confirmation;
    const ready = password.length >= 8 && password === confirmation && confirmation.length >= 8;

    passwordInput.setAttribute("aria-invalid", passwordTooShort ? "true" : "false");
    confirmInput.setAttribute("aria-invalid", confirmationMismatch ? "true" : "false");
    passwordError.classList.toggle("hidden", !passwordTooShort);
    confirmError.classList.toggle("hidden", !confirmationMismatch);

    validation.classList.remove("is-ready", "is-error");
    if (passwordTooShort) {
      validation.textContent = "Use at least 8 characters for your new password.";
      validation.classList.add("is-error");
    } else if (confirmationMismatch) {
      validation.textContent = "Passwords must match before you can continue.";
      validation.classList.add("is-error");
    } else if (ready) {
      validation.textContent = "Password looks good.";
      validation.classList.add("is-ready");
    } else {
      validation.textContent = "Use at least 8 characters.";
    }

    submitButton.disabled = isSubmitting || !ready;
  };

  passwordInput.addEventListener("input", syncFormState);
  confirmInput.addEventListener("input", syncFormState);

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    syncFormState();

    if (submitButton.disabled) {
      return;
    }

    clearFlashBanner();
    isSubmitting = true;
    fieldset.disabled = true;
    submitButton.disabled = true;
    submitButton.textContent = "Updating...";

    try {
      await confirmPasswordReset(auth, params.oobCode, passwordInput.value);
      renderStateCard({
        tone: "success",
        eyebrow: "Password updated",
        chip: "Done",
        title: "Your password was updated",
        subtitle: "Your new password is now active.",
        body: "You can close this page.",
        actions: [createClosePageAction()],
      });
    } catch (error) {
      if (isTerminalCodeError(error)) {
        renderTerminalError("resetPassword", error);
        return;
      }

      const copy = getErrorCopy("resetPassword", error, "apply");
      showFlashBanner("error", copy.title, copy.body);
      fieldset.disabled = false;
      isSubmitting = false;
      submitButton.textContent = "Update password";
      syncFormState();
    }
  });

  syncFormState();
}

function renderVerifyAndChangeEmailSuccess(details) {
  setPageCopy({
    eyebrow: "Email change",
    chip: "Done",
    title: "Your email was updated",
    subtitle: details.updatedEmail
      ? "Your new email is now active."
      : "This email update is complete.",
  });

  elements.pageContent.innerHTML = [
    '<section class="form-panel">',
    '  <div class="form-stack">',
    '    <p class="form-copy">Your account can now use this email.</p>',
    '    <div class="detail-grid">',
    '      <div class="detail-card">',
    '        <span class="detail-label">New email</span>',
    '        <span class="detail-value" id="updatedEmailValue"></span>',
    "      </div>",
    '      <div class="detail-card" id="previousEmailCard">',
    '        <span class="detail-label">Previous email</span>',
    '        <span class="detail-value" id="previousEmailValue"></span>',
    "      </div>",
    "    </div>",
    '    <div class="action-row">',
    '      <button class="button button-primary" id="verifyAndChangeEmailClose" type="button">Close</button>',
    "    </div>",
    "  </div>",
    "</section>",
  ].join("");

  elements.pageContent.setAttribute("aria-busy", "false");

  const updatedEmailValue = document.getElementById("updatedEmailValue");
  const previousEmailCard = document.getElementById("previousEmailCard");
  const previousEmailValue = document.getElementById("previousEmailValue");
  const closeButton = document.getElementById("verifyAndChangeEmailClose");

  updatedEmailValue.textContent = details.updatedEmail || "Verified FutureGate email";

  if (details.previousEmail) {
    previousEmailValue.textContent = details.previousEmail;
  } else {
    previousEmailCard.classList.add("hidden");
  }

  closeButton.addEventListener("click", attemptClosePage);
}

function renderRecoverEmailForm(details) {
  setPageCopy({
    eyebrow: "Email recovery",
    chip: "Recover email",
    title: "Restore your previous email",
    subtitle: "Confirm this request if you want to undo the email change.",
  });

  elements.pageContent.innerHTML = [
    '<section class="form-panel">',
    '  <div class="form-stack">',
    '    <p class="form-copy">If you did not request the change, restore your previous email.</p>',
    '    <div class="detail-grid">',
    '      <div class="detail-card">',
    '        <span class="detail-label">Restore to</span>',
    '        <span class="detail-value" id="recoverEmailValue"></span>',
    "      </div>",
    '      <div class="detail-card" id="currentEmailCard">',
    '        <span class="detail-label">Current email</span>',
    '        <span class="detail-value" id="currentEmailValue"></span>',
    "      </div>",
    "    </div>",
    "  </div>",
    '  <form class="auth-form" id="recoverEmailForm" novalidate>',
    '    <fieldset id="recoverEmailFieldset">',
    '      <div class="action-row">',
    '        <button class="button button-primary" id="recoverEmailSubmit" type="submit">Restore previous email</button>',
    '        <button class="button button-secondary" id="recoverEmailClose" type="button">Close</button>',
    "      </div>",
    "    </fieldset>",
    "  </form>",
    "</section>",
  ].join("");

  elements.pageContent.setAttribute("aria-busy", "false");

  const restoredEmail = document.getElementById("recoverEmailValue");
  const currentEmail = document.getElementById("currentEmailValue");
  const currentEmailCard = document.getElementById("currentEmailCard");
  const form = document.getElementById("recoverEmailForm");
  const fieldset = document.getElementById("recoverEmailFieldset");
  const submitButton = document.getElementById("recoverEmailSubmit");
  const closeButton = document.getElementById("recoverEmailClose");

  restoredEmail.textContent = details.restoredEmail || "Your previous email address";
  closeButton.addEventListener("click", attemptClosePage);

  if (details.currentEmail) {
    currentEmail.textContent = details.currentEmail;
  } else {
    currentEmailCard.classList.add("hidden");
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    clearFlashBanner();
    fieldset.disabled = true;
    submitButton.disabled = true;
    submitButton.textContent = "Restoring...";

    try {
      await applyActionCode(auth, params.oobCode);
      renderStateCard({
        tone: "success",
        eyebrow: "Email restored",
        chip: "Done",
        title: "Your previous email was restored",
        subtitle: "The email change has been reversed.",
        body: "If this was not you, reset your password after you sign in again.",
        actions: [createClosePageAction()],
      });
    } catch (error) {
      if (isTerminalCodeError(error)) {
        renderTerminalError("recoverEmail", error);
        return;
      }

      const copy = getErrorCopy("recoverEmail", error, "apply");
      showFlashBanner("error", copy.title, copy.body);
      fieldset.disabled = false;
      submitButton.disabled = false;
      submitButton.textContent = "Restore previous email";
    }
  });
}

function renderTerminalError(flow, error) {
  const copy = getErrorCopy(flow, error, "verify");

  renderStateCard({
    tone: "error",
    eyebrow: copy.eyebrow,
    chip: copy.chip,
    title: copy.title,
    subtitle: copy.subtitle,
    body: copy.body,
    listItems: copy.listItems,
    actions: copy.actions,
  });
}

function renderStateCard({
  tone,
  eyebrow,
  chip,
  title,
  subtitle,
  body,
  listItems = [],
  actions = [],
}) {
  setPageCopy({ eyebrow, chip, title, subtitle });
  clearFlashBanner();

  elements.pageContent.innerHTML = [
    `<section class="state-card state-${tone}">`,
    `  <div class="state-icon" aria-hidden="true">${getToneBadge(tone)}</div>`,
    '  <div class="state-stack">',
    "    <p></p>",
    "  </div>",
    listItems.length > 0 ? '  <ul class="state-list" id="stateList"></ul>' : "",
    actions.length > 0 ? '  <div class="action-row" id="stateActions"></div>' : "",
    "</section>",
  ].join("");

  elements.pageContent.setAttribute("aria-busy", "false");

  const paragraph = elements.pageContent.querySelector(".state-stack p");
  paragraph.textContent = body;

  if (listItems.length > 0) {
    const list = document.getElementById("stateList");
    listItems.forEach((item) => {
      const listItem = document.createElement("li");
      listItem.textContent = item;
      list.appendChild(listItem);
    });
  }

  if (actions.length > 0) {
    const actionRow = document.getElementById("stateActions");
    actions.forEach((action) => {
      const actionElement = document.createElement(action.href ? "a" : "button");
      actionElement.className = `button button-${action.variant || "secondary"}`;
      actionElement.textContent = action.label;

      if (action.href) {
        actionElement.href = action.href;
      } else {
        actionElement.type = "button";
        actionElement.addEventListener("click", action.onClick);
      }

      actionRow.appendChild(actionElement);
    });
  }
}

function renderLoadingState(title, message) {
  elements.pageContent.innerHTML = [
    '<section class="state-card state-loading">',
    '  <div class="state-icon" aria-hidden="true"><span class="spinner"></span></div>',
    '  <div class="state-stack">',
    `    <h2>${title}</h2>`,
    `    <p>${message}</p>`,
    "  </div>",
    "</section>",
  ].join("");
  elements.pageContent.setAttribute("aria-busy", "true");
}

function createClosePageAction(label = "Close", variant = "primary") {
  return {
    label,
    variant,
    onClick: attemptClosePage,
  };
}

function setPageCopy({ eyebrow, chip, title, subtitle }) {
  elements.pageEyebrow.textContent = eyebrow;
  elements.statusChip.textContent = chip;
  elements.pageTitle.textContent = title;
  elements.pageSubtitle.textContent = subtitle;
  document.title = `${title} | FutureGate`;
}

function attemptClosePage() {
  window.close();

  window.setTimeout(() => {
    showFlashBanner(
      "info",
      "You can close this tab",
      "This browser kept the tab open, but the action is complete."
    );
  }, 150);
}

function showFlashBanner(tone, title, message) {
  elements.flashBanner.className = `banner banner-${tone}`;
  elements.flashBanner.innerHTML = "<strong></strong><p></p>";
  elements.flashBanner.querySelector("strong").textContent = title;
  elements.flashBanner.querySelector("p").textContent = message;
}

function clearFlashBanner() {
  elements.flashBanner.className = "banner hidden";
  elements.flashBanner.textContent = "";
}

function updateNetworkBanner() {
  if (navigator.onLine) {
    elements.networkBanner.className = "banner banner-info hidden";
    elements.networkBanner.textContent = "";
    return;
  }

  elements.networkBanner.className = "banner banner-info";
  elements.networkBanner.innerHTML = "<strong></strong><p></p>";
  elements.networkBanner.querySelector("strong").textContent = "You are offline";
  elements.networkBanner.querySelector("p").textContent =
    "Reconnect to continue.";
}

function attachPasswordToggles() {
  document.querySelectorAll("[data-toggle-password]").forEach((button) => {
    button.addEventListener("click", () => {
      const inputId = button.getAttribute("data-toggle-password");
      const input = document.getElementById(inputId);
      const showing = input.type === "text";
      input.type = showing ? "password" : "text";
      button.textContent = showing ? "Show" : "Hide";
      button.setAttribute("aria-pressed", showing ? "false" : "true");
    });
  });
}

function readActionParams() {
  const searchParams = new URLSearchParams(window.location.search);

  return {
    apiKey: safeString(searchParams.get("apiKey")),
    continueUrl: safeString(searchParams.get("continueUrl")),
    lang: safeString(searchParams.get("lang")) || "en",
    mode: normalizeMode(searchParams.get("mode")),
    oobCode: safeString(searchParams.get("oobCode")),
  };
}

function applyDocumentLanguage(lang) {
  document.documentElement.lang = normalizeLang(lang);
}

function normalizeLang(lang) {
  return /^[a-z]{2,3}(?:-[a-z]{2,4})?$/i.test(lang || "") ? lang : "en";
}

function safeString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeMode(value) {
  const mode = safeString(value);
  const compactMode = mode.toLowerCase();

  switch (compactMode) {
    case "resetpassword":
      return "resetPassword";
    case "verifyemail":
      return "verifyEmail";
    case "verifyandchangeemail":
    case "verifybeforechangeemail":
      return "verifyAndChangeEmail";
    case "recoveremail":
      return "recoverEmail";
    default:
      return mode;
  }
}

function extractVerifyAndChangeEmailDetails(info) {
  const data = info && info.data ? info.data : {};
  const email = safeString(data.email);
  const previousEmail = safeString(data.previousEmail || data.fromEmail);

  return {
    updatedEmail: email,
    previousEmail,
  };
}

function extractRecoverEmailDetails(info) {
  const data = info && info.data ? info.data : {};
  const email = safeString(data.email);
  const previousEmail = safeString(data.previousEmail);
  const fromEmail = safeString(data.fromEmail);

  if (email && previousEmail && email !== previousEmail) {
    return {
      restoredEmail: email,
      currentEmail: previousEmail,
    };
  }

  return {
    restoredEmail: email || previousEmail || fromEmail,
    currentEmail: email && fromEmail && email !== fromEmail ? fromEmail : "",
  };
}

function getErrorCopy(flow, error, stage) {
  const code = error && typeof error.code === "string" ? error.code : "";
  const invalidAction = code === "auth/invalid-action-code" || code === "auth/expired-action-code";
  const networkIssue = code === "auth/network-request-failed";
  const tooManyRequests = code === "auth/too-many-requests";

  if (flow === "resetPassword" && code === "auth/weak-password" && stage === "apply") {
    return {
      title: "Choose a stronger password",
      body: "Use at least 8 characters, then submit the form again.",
    };
  }

  if (networkIssue) {
    return {
      eyebrow: "Offline",
      chip: "Network issue",
      title: "Connection required",
      subtitle: "Reconnect and try this link again.",
      body: "If it still fails, request a new email from FutureGate.",
      listItems: getRecoveryList(flow),
      actions: [createClosePageAction()],
    };
  }

  if (invalidAction) {
    return {
      eyebrow: "Link expired",
      chip: "No longer valid",
      title: getExpiredTitle(flow),
      subtitle: "This link may be expired, used already, or replaced by a newer one.",
      body: "Request a new email and use the latest link.",
      listItems: getRecoveryList(flow),
      actions: [createClosePageAction()],
    };
  }

  if (tooManyRequests) {
    return {
      eyebrow: "Please wait",
      chip: "Too many requests",
      title: "Please try again in a moment",
      subtitle: "Too many account actions were requested too quickly.",
      body: "Wait a bit, then request a new email if needed.",
      listItems: getRecoveryList(flow),
      actions: [createClosePageAction()],
    };
  }

  if (flow === "verifyEmail") {
    return {
      eyebrow: "Verification unavailable",
      chip: "Unable to verify",
      title: "This verification link could not be completed",
      subtitle: "Request a new verification email from FutureGate.",
      body: "Then open the latest email you receive.",
      listItems: getRecoveryList(flow),
      actions: [createClosePageAction()],
    };
  }

  if (flow === "verifyAndChangeEmail") {
    return {
      eyebrow: "Email change unavailable",
      chip: "Unable to confirm new email",
      title: "This email change link could not be completed",
      subtitle: "Request a new email change confirmation from FutureGate.",
      body: "If this was not you, use the recovery message sent to your previous email.",
      listItems: getRecoveryList(flow),
      actions: [createClosePageAction()],
    };
  }

  if (flow === "recoverEmail") {
    return {
      eyebrow: "Recovery unavailable",
      chip: "Unable to restore email",
      title: "This email recovery link could not be completed",
      subtitle: "Request a new recovery email from FutureGate if needed.",
      body: "If this was not you, reset your password after you sign in again.",
      listItems: getRecoveryList(flow),
      actions: [createClosePageAction()],
    };
  }

  return {
    eyebrow: "Something went wrong",
    chip: "Action unavailable",
    title: "This action could not be completed",
    subtitle: "Try again with the latest email link or request a new one.",
    body: getUnexpectedErrorMessage(error),
    listItems: getRecoveryList(flow),
    actions: [createClosePageAction()],
  };
}

function getRecoveryList(flow) {
  if (flow === "verifyEmail") {
    return [
      "Request a new verification email.",
      "Open only the latest email.",
    ];
  }

  if (flow === "recoverEmail") {
    return [
      "Request a new recovery email if needed.",
      "Reset your password if this change was not yours.",
    ];
  }

  if (flow === "verifyAndChangeEmail") {
    return [
      "Request a new email change confirmation.",
      "Use the recovery email if this change was not yours.",
    ];
  }

  return [
    "Request a new password reset email.",
    "Open only the latest email.",
  ];
}

function getExpiredTitle(flow) {
  if (flow === "verifyEmail") {
    return "This verification link is no longer valid";
  }

  if (flow === "verifyAndChangeEmail") {
    return "This email change link is no longer valid";
  }

  if (flow === "recoverEmail") {
    return "This email recovery link is no longer valid";
  }

  return "This password reset link is no longer valid";
}

function isTerminalCodeError(error) {
  return error && (
    error.code === "auth/invalid-action-code" ||
    error.code === "auth/expired-action-code"
  );
}

function getToneBadge(tone) {
  switch (tone) {
    case "success":
      return "OK";
    case "error":
      return "!";
    default:
      return "...";
  }
}

function getUnexpectedErrorMessage(error) {
  if (error && typeof error.message === "string" && error.message.trim() !== "") {
    return error.message;
  }

  return "An unexpected error occurred while FutureGate was talking to Firebase.";
}
