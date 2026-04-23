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

// ── SVG icon library ─────────────────────────────────────────────────────────

const ICONS = {
  check: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <path d="M22 11.08V12a10 10 0 11-5.93-9.14" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/>
    <path d="M22 4L12 14.01l-3-3" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`,

  xCircle: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="1.75"/>
    <path d="M15 9l-6 6M9 9l6 6" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/>
  </svg>`,

  info: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="1.75"/>
    <path d="M12 16v-4M12 8h.01" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/>
  </svg>`,

  mail: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <rect x="2" y="4" width="20" height="16" rx="2" stroke="currentColor" stroke-width="1.75"/>
    <path d="M2 7l10 7 10-7" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/>
  </svg>`,

  key: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <circle cx="8" cy="15" r="5" stroke="currentColor" stroke-width="1.75"/>
    <path d="M21 3l-9.5 9.5M15 9l2 2" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/>
  </svg>`,

  eyeShow: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.75"/>
  </svg>`,

  eyeHide: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
    <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19M1 1l22 22" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`,
};

// ── DOM refs ──────────────────────────────────────────────────────────────────

const el = {
  flashBanner:  document.getElementById("flashBanner"),
  networkBanner:document.getElementById("networkBanner"),
  pageContent:  document.getElementById("pageContent"),
  pageEyebrow:  document.getElementById("pageEyebrow"),
  pageSubtitle: document.getElementById("pageSubtitle"),
  pageTitle:    document.getElementById("pageTitle"),
  statusChip:   document.getElementById("statusChip"),
};

const params = readActionParams();
let auth;

window.addEventListener("online",  updateNetworkBanner);
window.addEventListener("offline", updateNetworkBanner);

void bootstrap();

// ── Bootstrap ─────────────────────────────────────────────────────────────────

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
      actions: [createCloseAction()],
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
      actions: [createCloseAction()],
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
      actions: [createCloseAction()],
    });
    return;
  }

  switch (params.mode) {
    case "resetPassword":         await handleResetPassword();        return;
    case "verifyEmail":           await handleVerifyEmail();          return;
    case "verifyAndChangeEmail":  await handleVerifyAndChangeEmail(); return;
    case "recoverEmail":          await handleRecoverEmail();         return;
    default:
      renderStateCard({
        tone: "error",
        eyebrow: "Unsupported action",
        chip: "Not available",
        title: "This action is not supported",
        subtitle: "Supported: resetPassword, verifyEmail, verifyAndChangeEmail, recoverEmail.",
        body: "Return to FutureGate to request a new link.",
        actions: [createCloseAction()],
      });
  }
}

// ── Flow handlers ─────────────────────────────────────────────────────────────

async function handleResetPassword() {
  setPageMeta({ eyebrow: "Password reset", chip: "Reset password", title: "Reset your password", subtitle: "Choose a new password." });
  clearFlash();
  renderLoading("Checking link", "Please wait a moment.");

  try {
    const email = await verifyPasswordResetCode(auth, params.oobCode);
    renderResetPasswordForm(email);
  } catch (error) {
    renderTerminalError("resetPassword", error);
  }
}

async function handleVerifyEmail() {
  setPageMeta({ eyebrow: "Email verification", chip: "Verify email", title: "Verifying your email", subtitle: "Please wait a moment." });
  clearFlash();
  renderLoading("Verifying email", "Please wait a moment.");

  try {
    await applyActionCode(auth, params.oobCode);
    renderStateCard({
      tone: "success",
      eyebrow: "Email verified",
      chip: "Done",
      title: "Email verified",
      subtitle: "Your email address is now confirmed.",
      body: "You can close this tab and return to FutureGate.",
      actions: [createCloseAction()],
    });
  } catch (error) {
    renderTerminalError("verifyEmail", error);
  }
}

async function handleVerifyAndChangeEmail() {
  setPageMeta({ eyebrow: "Email change", chip: "Verify new email", title: "Confirming your new email", subtitle: "Please wait a moment." });
  clearFlash();
  renderLoading("Checking link", "Please wait a moment.");

  try {
    const info = await checkActionCode(auth, params.oobCode);
    const details = extractVerifyAndChangeEmailDetails(info);
    renderLoading("Updating email", "Please wait a moment.");
    await applyActionCode(auth, params.oobCode);
    renderVerifyAndChangeEmailSuccess(details);
  } catch (error) {
    renderTerminalError("verifyAndChangeEmail", error);
  }
}

async function handleRecoverEmail() {
  setPageMeta({ eyebrow: "Email recovery", chip: "Recover email", title: "Restore your previous email", subtitle: "Confirm this request." });
  clearFlash();
  renderLoading("Checking link", "Please wait a moment.");

  try {
    const info = await checkActionCode(auth, params.oobCode);
    renderRecoverEmailForm(extractRecoverEmailDetails(info));
  } catch (error) {
    renderTerminalError("recoverEmail", error);
  }
}

// ── Form renderers ────────────────────────────────────────────────────────────

function renderResetPasswordForm(email) {
  setPageMeta({
    eyebrow: "Password reset",
    chip: "Reset password",
    title: "Reset your password",
    subtitle: "Choose a strong password with at least 8 characters.",
  });

  el.pageContent.innerHTML = `
    <div class="form-panel">
      <div class="form-stack">
        <div class="detail-card">
          <span class="detail-label">Resetting password for</span>
          <span class="detail-value" id="resetEmailValue"></span>
        </div>
      </div>
      <form class="form-stack" id="resetPasswordForm" novalidate>
        <fieldset id="resetPasswordFieldset" style="margin:0;padding:0;border:0;min-width:0;display:grid;gap:12px;">
          <div class="field-group">
            <label class="field-label" for="newPassword">New password</label>
            <div class="input-shell">
              <input class="text-input" id="newPassword" name="newPassword" type="password"
                minlength="8" autocomplete="new-password" required
                aria-describedby="newPasswordHint newPasswordError"
                placeholder="Min. 8 characters">
              <button class="input-toggle" type="button"
                data-toggle-password="newPassword"
                aria-controls="newPassword"
                aria-label="Show password"
                aria-pressed="false">
                ${ICONS.eyeShow}
              </button>
            </div>
            <p class="field-hint" id="newPasswordHint">Use at least 8 characters.</p>
            <p class="field-error hidden" id="newPasswordError">Password must be at least 8 characters.</p>
          </div>

          <div class="field-group">
            <label class="field-label" for="confirmPassword">Confirm password</label>
            <div class="input-shell">
              <input class="text-input" id="confirmPassword" name="confirmPassword" type="password"
                minlength="8" autocomplete="new-password" required
                aria-describedby="confirmPasswordError"
                placeholder="Re-enter your password">
              <button class="input-toggle" type="button"
                data-toggle-password="confirmPassword"
                aria-controls="confirmPassword"
                aria-label="Show password"
                aria-pressed="false">
                ${ICONS.eyeShow}
              </button>
            </div>
            <p class="field-error hidden" id="confirmPasswordError">Passwords do not match.</p>
          </div>

          <div class="field-group">
            <div class="strength-row" id="strengthRow" aria-live="polite" aria-atomic="true">
              <div class="strength-bar" id="strengthBar">
                <div class="strength-seg"></div>
                <div class="strength-seg"></div>
                <div class="strength-seg"></div>
                <div class="strength-seg"></div>
              </div>
              <span class="strength-label" id="strengthLabel"></span>
            </div>
          </div>

          <p class="validation-text" id="resetValidation">Use at least 8 characters.</p>

          <div class="action-row">
            <button class="button button-primary" id="resetSubmitButton" type="submit" disabled>
              Update password
            </button>
            <button class="button button-secondary" id="resetCloseButton" type="button">
              Close
            </button>
          </div>
        </fieldset>
      </form>
    </div>
  `;

  el.pageContent.setAttribute("aria-busy", "false");

  const emailValue    = document.getElementById("resetEmailValue");
  const form          = document.getElementById("resetPasswordForm");
  const fieldset      = document.getElementById("resetPasswordFieldset");
  const passwordInput = document.getElementById("newPassword");
  const confirmInput  = document.getElementById("confirmPassword");
  const passwordError = document.getElementById("newPasswordError");
  const confirmError  = document.getElementById("confirmPasswordError");
  const validation    = document.getElementById("resetValidation");
  const submitButton  = document.getElementById("resetSubmitButton");
  const closeButton   = document.getElementById("resetCloseButton");
  const strengthBar   = document.getElementById("strengthBar");
  const strengthLabel = document.getElementById("strengthLabel");

  let isSubmitting = false;

  emailValue.textContent = email || "FutureGate account";
  attachPasswordToggles();
  closeButton.addEventListener("click", attemptClose);

  const syncFormState = () => {
    const password     = passwordInput.value;
    const confirmation = confirmInput.value;
    const tooShort     = password.length > 0 && password.length < 8;
    const mismatch     = confirmation.length > 0 && password.length >= 8 && password !== confirmation;
    const ready        = password.length >= 8 && password === confirmation && confirmation.length >= 8;

    passwordInput.setAttribute("aria-invalid", tooShort ? "true" : "false");
    confirmInput.setAttribute("aria-invalid",  mismatch ? "true"  : "false");
    passwordError.classList.toggle("hidden", !tooShort);
    confirmError.classList.toggle("hidden",  !mismatch);

    // strength
    const strength = password.length > 0 ? calcPasswordStrength(password) : 0;
    strengthBar.className = `strength-bar${strength > 0 ? ` strength-${strength}` : ""}`;
    const strengthLabels = ["", "Weak", "Fair", "Good", "Strong"];
    strengthLabel.textContent = strengthLabels[strength] || "";

    validation.classList.remove("is-ready", "is-error");
    if (tooShort) {
      validation.textContent = "Use at least 8 characters.";
      validation.classList.add("is-error");
    } else if (mismatch) {
      validation.textContent = "Passwords must match.";
      validation.classList.add("is-error");
    } else if (ready) {
      validation.textContent = "Looks good — ready to update.";
      validation.classList.add("is-ready");
    } else {
      validation.textContent = "Use at least 8 characters.";
    }

    submitButton.disabled = isSubmitting || !ready;
  };

  passwordInput.addEventListener("input", syncFormState);
  confirmInput.addEventListener("input",  syncFormState);

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    syncFormState();
    if (submitButton.disabled) return;

    clearFlash();
    isSubmitting = true;
    fieldset.disabled      = true;
    submitButton.disabled  = true;
    submitButton.textContent = "Updating…";

    try {
      await confirmPasswordReset(auth, params.oobCode, passwordInput.value);
      renderStateCard({
        tone: "success",
        eyebrow: "Password updated",
        chip: "Done",
        title: "Password updated",
        subtitle: "Your new password is active.",
        body: "You can close this tab and sign in with your new password.",
        actions: [createCloseAction()],
      });
    } catch (error) {
      if (isTerminalError(error)) {
        renderTerminalError("resetPassword", error);
        return;
      }
      const copy = getErrorCopy("resetPassword", error, "apply");
      showFlash("error", copy.title, copy.body);
      fieldset.disabled    = false;
      isSubmitting         = false;
      submitButton.textContent = "Update password";
      syncFormState();
    }
  });

  syncFormState();
}

function renderVerifyAndChangeEmailSuccess(details) {
  setPageMeta({
    eyebrow: "Email change",
    chip: "Done",
    title: "Email updated",
    subtitle: details.updatedEmail ? "Your new email is now active." : "This email update is complete.",
  });

  el.pageContent.innerHTML = `
    <div class="form-panel">
      <div class="form-stack">
        <p class="form-copy">Your account can now sign in with this email address.</p>
        <div class="detail-grid">
          <div class="detail-card">
            <span class="detail-label">New email</span>
            <span class="detail-value" id="updatedEmailValue"></span>
          </div>
          <div class="detail-card" id="previousEmailCard">
            <span class="detail-label">Previous email</span>
            <span class="detail-value" id="previousEmailValue"></span>
          </div>
        </div>
        <div class="action-row">
          <button class="button button-primary" id="verifyAndChangeEmailClose" type="button">Close tab</button>
        </div>
      </div>
    </div>
  `;

  el.pageContent.setAttribute("aria-busy", "false");

  const updatedEmailValue  = document.getElementById("updatedEmailValue");
  const previousEmailCard  = document.getElementById("previousEmailCard");
  const previousEmailValue = document.getElementById("previousEmailValue");
  const closeButton        = document.getElementById("verifyAndChangeEmailClose");

  updatedEmailValue.textContent = details.updatedEmail || "Verified FutureGate email";

  if (details.previousEmail) {
    previousEmailValue.textContent = details.previousEmail;
  } else {
    previousEmailCard.classList.add("hidden");
  }

  closeButton.addEventListener("click", attemptClose);
}

function renderRecoverEmailForm(details) {
  setPageMeta({
    eyebrow: "Email recovery",
    chip: "Recover email",
    title: "Restore your email",
    subtitle: "Confirm this request to undo the email change.",
  });

  el.pageContent.innerHTML = `
    <div class="form-panel">
      <div class="form-stack">
        <p class="form-copy">If you did not request this change, restore your previous email address below.</p>
        <div class="detail-grid">
          <div class="detail-card">
            <span class="detail-label">Restore to</span>
            <span class="detail-value" id="recoverEmailValue"></span>
          </div>
          <div class="detail-card" id="currentEmailCard">
            <span class="detail-label">Current email</span>
            <span class="detail-value" id="currentEmailValue"></span>
          </div>
        </div>
      </div>
      <form class="form-stack" id="recoverEmailForm" novalidate style="margin-top:2px;">
        <fieldset id="recoverEmailFieldset" style="margin:0;padding:0;border:0;min-width:0;">
          <div class="action-row">
            <button class="button button-primary"   id="recoverEmailSubmit" type="submit">Restore previous email</button>
            <button class="button button-secondary" id="recoverEmailClose"  type="button">Close</button>
          </div>
        </fieldset>
      </form>
    </div>
  `;

  el.pageContent.setAttribute("aria-busy", "false");

  const restoredEmailEl    = document.getElementById("recoverEmailValue");
  const currentEmailEl     = document.getElementById("currentEmailValue");
  const currentEmailCard   = document.getElementById("currentEmailCard");
  const form               = document.getElementById("recoverEmailForm");
  const fieldset           = document.getElementById("recoverEmailFieldset");
  const submitButton       = document.getElementById("recoverEmailSubmit");
  const closeButton        = document.getElementById("recoverEmailClose");

  restoredEmailEl.textContent = details.restoredEmail || "Your previous email address";
  closeButton.addEventListener("click", attemptClose);

  if (details.currentEmail) {
    currentEmailEl.textContent = details.currentEmail;
  } else {
    currentEmailCard.classList.add("hidden");
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    clearFlash();
    fieldset.disabled      = true;
    submitButton.disabled  = true;
    submitButton.textContent = "Restoring…";

    try {
      await applyActionCode(auth, params.oobCode);
      renderStateCard({
        tone: "success",
        eyebrow: "Email restored",
        chip: "Done",
        title: "Email restored",
        subtitle: "The email change has been reversed.",
        body: "If this was not you, reset your password after signing in.",
        actions: [createCloseAction()],
      });
    } catch (error) {
      if (isTerminalError(error)) {
        renderTerminalError("recoverEmail", error);
        return;
      }
      const copy = getErrorCopy("recoverEmail", error, "apply");
      showFlash("error", copy.title, copy.body);
      fieldset.disabled        = false;
      submitButton.disabled    = false;
      submitButton.textContent = "Restore previous email";
    }
  });
}

// ── State renderers ───────────────────────────────────────────────────────────

function renderTerminalError(flow, error) {
  const copy = getErrorCopy(flow, error, "verify");
  renderStateCard({
    tone: "error",
    eyebrow:   copy.eyebrow,
    chip:      copy.chip,
    title:     copy.title,
    subtitle:  copy.subtitle,
    body:      copy.body,
    listItems: copy.listItems,
    actions:   copy.actions,
  });
}

function renderStateCard({ tone, eyebrow, chip, title, subtitle, body, listItems = [], actions = [] }) {
  setPageMeta({ eyebrow, chip, title, subtitle });
  clearFlash();

  const listHtml = listItems.length > 0
    ? `<ul class="state-list">${listItems.map(i => `<li>${i}</li>`).join("")}</ul>`
    : "";

  el.pageContent.innerHTML = `
    <div class="state-card state-${tone}">
      <span class="state-icon">${getToneIcon(tone)}</span>
      <div class="state-body">
        <p id="stateBody"></p>
        ${listHtml}
        ${actions.length > 0 ? `<div class="state-actions action-row" id="stateActions"></div>` : ""}
      </div>
    </div>
  `;

  el.pageContent.setAttribute("aria-busy", "false");
  document.getElementById("stateBody").textContent = body;

  if (actions.length > 0) {
    const row = document.getElementById("stateActions");
    actions.forEach((action) => {
      const btn = document.createElement(action.href ? "a" : "button");
      btn.className = `button button-${action.variant || "secondary"}`;
      btn.textContent = action.label;
      if (action.href) {
        btn.href = action.href;
      } else {
        btn.type = "button";
        btn.addEventListener("click", action.onClick);
      }
      row.appendChild(btn);
    });
  }
}

function renderLoading(title, message) {
  el.pageContent.innerHTML = `
    <div class="state-card state-loading">
      <span class="state-icon" aria-hidden="true"><span class="spinner"></span></span>
      <div class="state-body">
        <h2>${title}</h2>
        <p>${message}</p>
      </div>
    </div>
  `;
  el.pageContent.setAttribute("aria-busy", "true");
}

// ── UI helpers ────────────────────────────────────────────────────────────────

function createCloseAction(label = "Close tab", variant = "primary") {
  return { label, variant, onClick: attemptClose };
}

function setPageMeta({ eyebrow, chip, title, subtitle }) {
  el.pageEyebrow.textContent  = eyebrow;
  el.statusChip.textContent   = chip;
  el.pageTitle.textContent    = title;
  el.pageSubtitle.textContent = subtitle;
  document.title = `${title} | FutureGate`;
}

function attemptClose() {
  window.close();
  window.setTimeout(() => {
    showFlash("info", "You can close this tab", "The action is complete — this browser kept the tab open.");
  }, 150);
}

function showFlash(tone, title, message) {
  el.flashBanner.className = `alert alert-${tone}`;
  el.flashBanner.innerHTML = `<div><strong></strong><p></p></div>`;
  el.flashBanner.querySelector("strong").textContent = title;
  el.flashBanner.querySelector("p").textContent      = message;
}

function clearFlash() {
  el.flashBanner.className   = "alert hidden";
  el.flashBanner.textContent = "";
}

function updateNetworkBanner() {
  if (navigator.onLine) {
    el.networkBanner.className   = "alert hidden";
    el.networkBanner.textContent = "";
    return;
  }
  el.networkBanner.className = "alert alert-warning";
  el.networkBanner.innerHTML = `<div><strong>You are offline</strong><p>Reconnect to continue.</p></div>`;
}

function attachPasswordToggles() {
  document.querySelectorAll("[data-toggle-password]").forEach((button) => {
    button.addEventListener("click", () => {
      const inputId = button.getAttribute("data-toggle-password");
      const input   = document.getElementById(inputId);
      const showing = input.type === "text";
      input.type = showing ? "password" : "text";
      button.innerHTML     = showing ? ICONS.eyeShow : ICONS.eyeHide;
      button.setAttribute("aria-label",   showing ? "Show password" : "Hide password");
      button.setAttribute("aria-pressed", showing ? "false" : "true");
    });
  });
}

function getToneIcon(tone) {
  switch (tone) {
    case "success": return ICONS.check;
    case "error":   return ICONS.xCircle;
    default:        return ICONS.info;
  }
}

// ── Password strength ─────────────────────────────────────────────────────────

function calcPasswordStrength(pw) {
  let score = 0;
  if (pw.length >= 8)  score++;
  if (pw.length >= 12) score++;
  if (/[A-Z]/.test(pw)) score++;
  if (/[0-9]/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  return Math.min(4, score);
}

// ── URL params ────────────────────────────────────────────────────────────────

function readActionParams() {
  const sp = new URLSearchParams(window.location.search);
  return {
    apiKey:      safeString(sp.get("apiKey")),
    continueUrl: safeString(sp.get("continueUrl")),
    lang:        safeString(sp.get("lang")) || "en",
    mode:        normalizeMode(sp.get("mode")),
    oobCode:     safeString(sp.get("oobCode")),
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
  switch (mode.toLowerCase()) {
    case "resetpassword":           return "resetPassword";
    case "verifyemail":             return "verifyEmail";
    case "verifyandchangeemail":
    case "verifybeforechangeemail": return "verifyAndChangeEmail";
    case "recoveremail":            return "recoverEmail";
    default:                        return mode;
  }
}

// ── Data extractors ───────────────────────────────────────────────────────────

function extractVerifyAndChangeEmailDetails(info) {
  const data = info && info.data ? info.data : {};
  return {
    updatedEmail:  safeString(data.email),
    previousEmail: safeString(data.previousEmail || data.fromEmail),
  };
}

function extractRecoverEmailDetails(info) {
  const data          = info && info.data ? info.data : {};
  const email         = safeString(data.email);
  const previousEmail = safeString(data.previousEmail);
  const fromEmail     = safeString(data.fromEmail);

  if (email && previousEmail && email !== previousEmail) {
    return { restoredEmail: email, currentEmail: previousEmail };
  }
  return {
    restoredEmail: email || previousEmail || fromEmail,
    currentEmail:  email && fromEmail && email !== fromEmail ? fromEmail : "",
  };
}

// ── Error copy ────────────────────────────────────────────────────────────────

function getErrorCopy(flow, error, stage) {
  const code          = error && typeof error.code === "string" ? error.code : "";
  const isInvalid     = code === "auth/invalid-action-code" || code === "auth/expired-action-code";
  const isNetwork     = code === "auth/network-request-failed";
  const isTooMany     = code === "auth/too-many-requests";

  if (flow === "resetPassword" && code === "auth/weak-password" && stage === "apply") {
    return { title: "Choose a stronger password", body: "Use at least 8 characters, then try again." };
  }

  if (isNetwork) {
    return {
      eyebrow: "Offline", chip: "Network error",
      title: "Connection required",
      subtitle: "Reconnect and try this link again.",
      body: "If it still fails, request a new link from FutureGate.",
      listItems: getRecoveryList(flow),
      actions: [createCloseAction()],
    };
  }

  if (isInvalid) {
    return {
      eyebrow: "Link expired", chip: "No longer valid",
      title: getExpiredTitle(flow),
      subtitle: "This link may be expired, already used, or replaced by a newer one.",
      body: "Request a new link and use the latest email.",
      listItems: getRecoveryList(flow),
      actions: [createCloseAction()],
    };
  }

  if (isTooMany) {
    return {
      eyebrow: "Please wait", chip: "Too many requests",
      title: "Try again in a moment",
      subtitle: "Too many account actions were requested too quickly.",
      body: "Wait a bit, then request a new link if needed.",
      listItems: getRecoveryList(flow),
      actions: [createCloseAction()],
    };
  }

  const flowMessages = {
    verifyEmail: {
      eyebrow: "Verification failed", chip: "Unable to verify",
      title: "This verification link failed",
      subtitle: "Request a new verification email from FutureGate.",
      body: "Then open only the latest email you receive.",
    },
    verifyAndChangeEmail: {
      eyebrow: "Email change failed", chip: "Unable to confirm",
      title: "This email change link failed",
      subtitle: "Request a new email change confirmation from FutureGate.",
      body: "If this was not you, use the recovery message sent to your previous email.",
    },
    recoverEmail: {
      eyebrow: "Recovery failed", chip: "Unable to restore",
      title: "This email recovery link failed",
      subtitle: "Request a new recovery link from FutureGate if needed.",
      body: "If this was not you, reset your password after signing in.",
    },
  };

  if (flowMessages[flow]) {
    return { ...flowMessages[flow], listItems: getRecoveryList(flow), actions: [createCloseAction()] };
  }

  return {
    eyebrow: "Something went wrong", chip: "Action unavailable",
    title: "This action could not be completed",
    subtitle: "Try again with the latest email link or request a new one.",
    body: getUnexpectedErrorMessage(error),
    listItems: getRecoveryList(flow),
    actions: [createCloseAction()],
  };
}

function getRecoveryList(flow) {
  const lists = {
    verifyEmail:          ["Request a new verification email.", "Open only the most recent email."],
    recoverEmail:         ["Request a new recovery email if needed.", "Reset your password if this change was not yours."],
    verifyAndChangeEmail: ["Request a new email change confirmation.", "Use the recovery email if this was not you."],
  };
  return lists[flow] || ["Request a new password reset email.", "Open only the most recent email."];
}

function getExpiredTitle(flow) {
  const titles = {
    verifyEmail:          "This verification link is no longer valid",
    verifyAndChangeEmail: "This email change link is no longer valid",
    recoverEmail:         "This email recovery link is no longer valid",
  };
  return titles[flow] || "This password reset link is no longer valid";
}

function isTerminalError(error) {
  return error && (
    error.code === "auth/invalid-action-code" ||
    error.code === "auth/expired-action-code"
  );
}

function getUnexpectedErrorMessage(error) {
  if (error && typeof error.message === "string" && error.message.trim() !== "") {
    return error.message;
  }
  return "An unexpected error occurred while communicating with Firebase.";
}
