import {
  auth,
  db,
  onAuthStateChanged,
  doc,
  getDoc,
  collection,
  query,
  where,
  onSnapshot,
} from './firebase-config.js';

let unreadNotificationsUnsubscribe = null;
let chromeInitialized = false;
let authListenerStarted = false;
let pageshowListenerStarted = false;
let verifiedAdminSession = null;
let workspaceNavigationId = 0;
const AUTH_STATE_TIMEOUT_MS = 12000;

const THEME_STORAGE_KEY = 'futuregate-admin-theme';
const SIDEBAR_STORAGE_KEY = 'futuregate-admin-sidebar-collapsed';
const WORKSPACE_ROUTE_NAMES = new Set([
  '',
  'index',
  'users',
  'moderation',
  'activity',
  'notifications',
  'idea-editor',
  'opp-editor',
  'scholarship-editor',
  'scolarship-editor',
  'cv-viewer',
]);

function resolveInitialTheme() {
  try {
    const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
    if (stored === 'dark' || stored === 'light') {
      return stored;
    }
  } catch (error) {
    console.warn('Theme preference could not be read:', error);
  }

  return window.matchMedia('(prefers-color-scheme: dark)').matches
    ? 'dark'
    : 'light';
}

function updateThemeControls(theme) {
  const nextLabel = theme === 'dark' ? 'Dark' : 'Light';

  document.querySelectorAll('[data-theme-toggle]').forEach((button) => {
    button.setAttribute('aria-pressed', theme === 'dark' ? 'true' : 'false');
  });

  document.querySelectorAll('[data-theme-label]').forEach((label) => {
    label.textContent = nextLabel;
  });
}

function applyTheme(theme) {
  const safeTheme = theme === 'dark' ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', safeTheme);
  updateThemeControls(safeTheme);
}

function persistTheme(theme) {
  try {
    window.localStorage.setItem(THEME_STORAGE_KEY, theme);
  } catch (error) {
    console.warn('Theme preference could not be saved:', error);
  }
}

function toggleTheme() {
  const currentTheme =
    document.documentElement.getAttribute('data-theme') === 'dark'
      ? 'dark'
      : 'light';
  const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';
  persistTheme(nextTheme);
  applyTheme(nextTheme);
}

function readSidebarCollapsedPreference() {
  try {
    return window.localStorage.getItem(SIDEBAR_STORAGE_KEY) === 'true';
  } catch (error) {
    console.warn('Sidebar preference could not be read:', error);
    return false;
  }
}

function persistSidebarCollapsedPreference(isCollapsed) {
  try {
    window.localStorage.setItem(SIDEBAR_STORAGE_KEY, isCollapsed ? 'true' : 'false');
  } catch (error) {
    console.warn('Sidebar preference could not be saved:', error);
  }
}

function updateSidebarCollapseControls(isCollapsed) {
  const label = isCollapsed ? 'Expand sidebar' : 'Collapse sidebar';
  const icon = isCollapsed ? 'panel-left-open' : 'panel-left-close';

  document.querySelectorAll('[data-sidebar-collapse-toggle]').forEach((button) => {
    button.setAttribute('aria-label', label);
    button.setAttribute('aria-pressed', isCollapsed ? 'true' : 'false');
    button.setAttribute('title', label);
    button.innerHTML = `<i data-lucide="${icon}"></i>`;
  });

  if (window.lucide) window.lucide.createIcons();
}

function applySidebarCollapsed(isCollapsed) {
  const layout = document.querySelector('.layout');
  if (layout) {
    layout.classList.toggle('sidebar-collapsed', Boolean(isCollapsed));
  }
  updateSidebarCollapseControls(Boolean(isCollapsed));
}

function toggleSidebarCollapsed() {
  const layout = document.querySelector('.layout');
  const nextState = !layout?.classList.contains('sidebar-collapsed');
  persistSidebarCollapsedPreference(nextState);
  applySidebarCollapsed(nextState);
}

function setNavOpen(isOpen) {
  const layout = document.querySelector('.layout');
  if (!layout) {
    return;
  }

  layout.classList.toggle('nav-open', Boolean(isOpen));
  document.querySelectorAll('[data-mobile-nav-toggle]').forEach((button) => {
    button.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
  });
}

function closeNavIfMobile() {
  if (window.innerWidth < 1024) {
    setNavOpen(false);
  }
}

function routeFileName(url) {
  return url.pathname.split('/').pop() || '';
}

function routeName(url) {
  const fileName = routeFileName(url).toLowerCase();
  return fileName.endsWith('.html') ? fileName.slice(0, -5) : fileName;
}

function routeDirectory(url) {
  const index = url.pathname.lastIndexOf('/');
  return index >= 0 ? url.pathname.slice(0, index + 1) : '/';
}

function isWorkspaceRouteUrl(url) {
  const currentUrl = new URL(window.location.href);
  return (
    url.origin === currentUrl.origin &&
    routeDirectory(url) === routeDirectory(currentUrl) &&
    WORKSPACE_ROUTE_NAMES.has(routeName(url))
  );
}

function shouldHandleWorkspaceNavigation(event, anchor) {
  if (!anchor || event.defaultPrevented || event.button !== 0) return false;
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return false;
  if (anchor.hasAttribute('download') || anchor.hasAttribute('data-router-ignore')) return false;

  const target = (anchor.getAttribute('target') || '').trim().toLowerCase();
  if (target && target !== '_self') return false;

  const href = anchor.getAttribute('href');
  if (!href || href.startsWith('#')) return false;

  const url = new URL(href, window.location.href);
  return isWorkspaceRouteUrl(url);
}

function setWorkspaceRouteLoading() {
  const layout = document.querySelector('.layout');
  const loading = document.getElementById('loading');
  const content = document.getElementById('page-content');

  layout?.classList.add('workspace-navigating', 'auth-ready');
  if (content) {
    content.style.display = 'none';
    content.innerHTML = '';
  }
  if (loading) {
    loading.innerHTML = '<div class="spinner"></div>';
    loading.style.display = 'flex';
  }
}

function clearRouteFragments() {
  document.querySelectorAll('[data-route-fragment], body > .modal-backdrop').forEach((element) => {
    element.remove();
  });
  document.querySelectorAll('script[data-workspace-route-script]').forEach((script) => {
    script.remove();
  });
  document.body.style.overflow = '';
}

function importRouteFragments(nextDoc) {
  const fragments = Array.from(nextDoc.body.children).filter((element) => {
    if (element.matches('script')) return false;
    if (element.id === 'auth-gate' || element.id === 'shell') return false;
    return true;
  });

  fragments.forEach((fragment) => {
    const imported = document.importNode(fragment, true);
    imported.setAttribute('data-route-fragment', '');
    document.body.appendChild(imported);
  });
}

function scriptAssetKey(url) {
  const normalized = new URL(url, window.location.href);
  normalized.hash = '';
  return normalized.href;
}

function hasScriptAsset(url) {
  const key = scriptAssetKey(url);
  return Array.from(document.scripts).some((script) => {
    if (!script.src || script.dataset.workspaceRouteScript === 'true') return false;
    return scriptAssetKey(script.src) === key;
  });
}

function loadScriptAsset(url, sourceScript) {
  return new Promise((resolve, reject) => {
    if (hasScriptAsset(url)) {
      resolve();
      return;
    }

    const script = document.createElement('script');
    sourceScript.getAttributeNames().forEach((name) => {
      if (name !== 'src') script.setAttribute(name, sourceScript.getAttribute(name));
    });
    script.src = url;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error(`Could not load ${url}`));
    document.head.appendChild(script);
  });
}

async function loadRouteHeadScripts(nextDoc, targetUrl) {
  const scripts = Array.from(nextDoc.head.querySelectorAll('script[src]'));
  for (const sourceScript of scripts) {
    const src = new URL(sourceScript.getAttribute('src'), targetUrl).href;
    if (src.endsWith('/js/theme-init.js')) continue;
    await loadScriptAsset(src, sourceScript);
  }
}

function executeRouteScripts(nextDoc, targetUrl) {
  const scripts = Array.from(nextDoc.body.querySelectorAll('script'));
  scripts.forEach((sourceScript, index) => {
    const script = document.createElement('script');
    sourceScript.getAttributeNames().forEach((name) => {
      if (name !== 'src') script.setAttribute(name, sourceScript.getAttribute(name));
    });
    script.dataset.workspaceRouteScript = 'true';

    const src = sourceScript.getAttribute('src');
    if (src) {
      const scriptUrl = new URL(src, targetUrl);
      if ((sourceScript.type || '').toLowerCase() === 'module') {
        scriptUrl.searchParams.set('workspaceNav', `${Date.now()}-${workspaceNavigationId}-${index}`);
      }
      script.src = scriptUrl.href;
    } else {
      script.textContent = sourceScript.textContent;
    }

    document.body.appendChild(script);
  });
}

async function navigateWorkspace(target, options = {}) {
  const targetUrl = new URL(target, window.location.href);
  if (!isWorkspaceRouteUrl(targetUrl)) return false;

  const currentUrl = new URL(window.location.href);
  if (!options.fromPopState && targetUrl.href === currentUrl.href) {
    closeNavIfMobile();
    return true;
  }

  const navigationId = ++workspaceNavigationId;
  closeNavIfMobile();
  setWorkspaceRouteLoading();

  try {
    const response = await fetch(targetUrl.href, {
      headers: { 'X-Requested-With': 'FutureGate-Workspace' },
    });
    if (!response.ok) throw new Error(`Navigation failed: ${response.status}`);

    const html = await response.text();
    if (navigationId !== workspaceNavigationId) return true;

    const nextDoc = new DOMParser().parseFromString(html, 'text/html');
    await loadRouteHeadScripts(nextDoc, targetUrl);
    if (navigationId !== workspaceNavigationId) return true;

    if (!options.fromPopState) {
      const method = options.replace ? 'replaceState' : 'pushState';
      window.history[method]({ futuregateWorkspace: true }, '', targetUrl.href);
    }

    document.title = nextDoc.title || document.title;
    document.body.dataset.page = nextDoc.body.dataset.page || '';
    document.getElementById('auth-gate')?.classList.add('hidden');
    clearRouteFragments();
    importRouteFragments(nextDoc);
    window.scrollTo(0, 0);
    executeRouteScripts(nextDoc, targetUrl);
    return true;
  } catch (error) {
    console.warn('Workspace navigation fell back to a full page load:', error);
    window.location.href = targetUrl.href;
    return false;
  }
}

function initializeWorkspaceRouter() {
  window.FutureGateWorkspace = {
    ...(window.FutureGateWorkspace || {}),
    navigate: navigateWorkspace,
  };

  const currentUrl = new URL(window.location.href);
  if (isWorkspaceRouteUrl(currentUrl)) {
    const currentState = window.history.state || {};
    if (!currentState.futuregateWorkspace) {
      window.history.replaceState({ ...currentState, futuregateWorkspace: true }, '', currentUrl.href);
    }
  }

  window.addEventListener('popstate', () => {
    const url = new URL(window.location.href);
    if (isWorkspaceRouteUrl(url)) {
      navigateWorkspace(url.href, { fromPopState: true });
    } else {
      window.location.reload();
    }
  });
}

function initializeChrome() {
  applyTheme(resolveInitialTheme());
  applySidebarCollapsed(readSidebarCollapsedPreference());

  if (chromeInitialized) {
    return;
  }

  chromeInitialized = true;
  initializeWorkspaceRouter();

  document.addEventListener('click', (event) => {
    if (event.target.closest('[data-theme-toggle]')) {
      toggleTheme();
      return;
    }

    if (event.target.closest('[data-sidebar-collapse-toggle]')) {
      toggleSidebarCollapsed();
      return;
    }

    if (event.target.closest('[data-mobile-nav-toggle]')) {
      const layout = document.querySelector('.layout');
      setNavOpen(!layout?.classList.contains('nav-open'));
      return;
    }

    if (event.target.closest('[data-shell-backdrop]')) {
      setNavOpen(false);
      return;
    }

    const workspaceLink = event.target.closest('a[href]');
    if (shouldHandleWorkspaceNavigation(event, workspaceLink)) {
      event.preventDefault();
      navigateWorkspace(workspaceLink.href);
      return;
    }

    if (event.target.closest('.nav-item')) {
      closeNavIfMobile();
    }
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      setNavOpen(false);
    }
  });

  window.addEventListener('resize', () => {
    if (window.innerWidth >= 1024) {
      setNavOpen(false);
    }
  });
}

function stopUnreadNotificationsWatcher() {
  if (typeof unreadNotificationsUnsubscribe === 'function') {
    unreadNotificationsUnsubscribe();
    unreadNotificationsUnsubscribe = null;
  }
}

function resetToGatedState() {
  const layout = document.querySelector('.layout');
  const gate = document.getElementById('auth-gate');
  if (layout) layout.classList.remove('auth-ready', 'nav-open');
  if (gate) gate.classList.remove('hidden');
}

function redirectToLogin() {
  window.location.replace('/login');
}

function updateNotificationBadges(count) {
  const badges = document.querySelectorAll('[data-notification-badge]');
  const safeCount = Number.isFinite(count) ? Math.max(0, count) : 0;

  badges.forEach((badge) => {
    if (safeCount > 0) {
      badge.textContent = safeCount > 99 ? '99+' : String(safeCount);
      badge.hidden = false;
    } else {
      badge.textContent = '0';
      badge.hidden = true;
    }
  });
}

function startUnreadNotificationsWatcher(userId) {
  stopUnreadNotificationsWatcher();
  updateNotificationBadges(0);

  if (!userId || document.querySelectorAll('[data-notification-badge]').length === 0) {
    return;
  }

  unreadNotificationsUnsubscribe = onSnapshot(
    query(
      collection(db, 'notifications'),
      where('userId', '==', userId),
    ),
    (snapshot) => {
      const unreadCount = snapshot.docs.reduce((count, item) => (
        item.data()?.isRead === true ? count : count + 1
      ), 0);
      updateNotificationBadges(unreadCount);
    },
    (error) => {
      console.warn('Unread notification badge watcher failed:', error);
    },
  );
}

async function validateAdminUser(user) {
  const userDoc = await getDoc(doc(db, 'users', user.uid));
  if (
    !userDoc.exists() ||
    userDoc.data().role !== 'admin' ||
    userDoc.data().isActive === false
  ) {
    throw new Error('Current user is not an active admin.');
  }
  return userDoc.data();
}

function applyAuthenticatedSession(user, userData) {
  const layout = document.querySelector('.layout');
  const gate = document.getElementById('auth-gate');

  verifiedAdminSession = { user, userData };
  setupSidebar(userData, user);
  startUnreadNotificationsWatcher(user.uid);
  applySidebarCollapsed(readSidebarCollapsedPreference());

  if (gate) gate.classList.add('hidden');
  if (layout) layout.classList.add('auth-ready');
}

function runAuthCallback(callback, user, userData) {
  if (typeof callback !== 'function') return;
  Promise.resolve()
    .then(() => callback(user, userData))
    .catch((error) => {
      console.error('Admin page callback failed:', error);
    });
}

function waitForAuthState(timeoutMs = AUTH_STATE_TIMEOUT_MS) {
  if (auth.currentUser) {
    return Promise.resolve(auth.currentUser);
  }

  return new Promise((resolve) => {
    let settled = false;
    let unsubscribe = null;

    function finish(user) {
      if (settled) return;
      settled = true;
      window.clearTimeout(timer);
      if (typeof unsubscribe === 'function') {
        unsubscribe();
      }
      resolve(user || null);
    }

    const timer = window.setTimeout(() => {
      finish(auth.currentUser || null);
    }, timeoutMs);

    unsubscribe = onAuthStateChanged(auth, finish);
    if (settled && typeof unsubscribe === 'function') {
      unsubscribe();
    }
  });
}

async function rejectInvalidSession() {
  verifiedAdminSession = null;
  stopUnreadNotificationsWatcher();
  await auth.signOut().catch(() => {});
  redirectToLogin();
}

function ensurePageshowListener() {
  if (pageshowListenerStarted) return;
  pageshowListenerStarted = true;

  window.addEventListener('pageshow', (event) => {
    if (!event.persisted) return;

    const currentUser = auth.currentUser;
    if (!currentUser) {
      window.setTimeout(() => {
        if (!auth.currentUser) redirectToLogin();
      }, 300);
      return;
    }

    validateAdminUser(currentUser)
      .then((userData) => applyAuthenticatedSession(currentUser, userData))
      .catch((error) => {
        console.error('Auth restore error:', error);
        rejectInvalidSession();
      });
  });
}

function startAuthListener() {
  if (authListenerStarted) return;
  authListenerStarted = true;

  onAuthStateChanged(auth, async (user) => {
    if (!user) {
      verifiedAdminSession = null;
      stopUnreadNotificationsWatcher();
      redirectToLogin();
      return;
    }

    try {
      const userData = await validateAdminUser(user);
      applyAuthenticatedSession(user, userData);
    } catch (error) {
      console.error('Auth check error:', error);
      rejectInvalidSession();
    }
  });
}

async function checkAuth(callback) {
  initializeChrome();
  ensurePageshowListener();

  if (
    verifiedAdminSession &&
    auth.currentUser &&
    verifiedAdminSession.user.uid === auth.currentUser.uid
  ) {
    applyAuthenticatedSession(verifiedAdminSession.user, verifiedAdminSession.userData);
    runAuthCallback(callback, verifiedAdminSession.user, verifiedAdminSession.userData);
    return;
  }

  resetToGatedState();
  startAuthListener();

  const user = await waitForAuthState();
  if (!user) {
    redirectToLogin();
    return;
  }

  try {
    const userData = await validateAdminUser(user);
    applyAuthenticatedSession(user, userData);
    runAuthCallback(callback, user, userData);
  } catch (error) {
    console.error('Auth check error:', error);
    rejectInvalidSession();
  }
}

function setupSidebar(userData, user) {
  const nameEl = document.getElementById('admin-name');
  const emailEl = document.getElementById('admin-email');
  const avatarEl = document.getElementById('admin-avatar');
  if (nameEl) nameEl.textContent = userData.fullName || 'Admin';
  if (emailEl) emailEl.textContent = user.email || '';
  if (avatarEl) avatarEl.textContent = (userData.fullName || 'A')[0].toUpperCase();

  const logoutBtn = document.getElementById('btn-logout');
  if (logoutBtn) {
    logoutBtn.onclick = async () => {
      stopUnreadNotificationsWatcher();
      await auth.signOut();
      redirectToLogin();
    };
  }

  const currentPage = routeName(new URL(window.location.href)) || 'index';
  document.querySelectorAll('.nav-item').forEach(item => {
    const href = item.getAttribute('href') || '';
    const hrefPage = routeName(new URL(href, window.location.href)) || 'index';
    const isActive = hrefPage === currentPage;
    item.classList.toggle('active', isActive);
    if (isActive) item.setAttribute('aria-current', 'page');
    else item.removeAttribute('aria-current');
  });
}

function normalizeFeedbackType(type) {
  const normalized = String(type || '').trim().toLowerCase();
  if (['success', 'error', 'warning', 'info', 'neutral'].includes(normalized)) {
    return normalized;
  }
  return 'info';
}

function feedbackMeta(type) {
  switch (normalizeFeedbackType(type)) {
    case 'success':
      return { icon: '<i data-lucide="check-circle-2"></i>', title: 'Success', html: true };
    case 'error':
      return { icon: '<i data-lucide="alert-octagon"></i>', title: 'Something went wrong', html: true };
    case 'warning':
      return { icon: '<i data-lucide="alert-triangle"></i>', title: 'Attention needed', html: true };
    case 'neutral':
      return { icon: '<i data-lucide="info"></i>', title: 'Update', html: true };
    case 'info':
    default:
      return { icon: '<i data-lucide="info"></i>', title: 'Notice', html: true };
  }
}

function feedbackCardHtml(message, options = {}) {
  const normalizedType = normalizeFeedbackType(options.type);
  const meta = feedbackMeta(normalizedType);
  const title = String(options.title || meta.title || '').trim();
  const iconHtml = options.icon
    ? `<i data-lucide="${esc(options.icon)}"></i>`
    : meta.icon;

  return `
    <div class="feedback-card is-${normalizedType}">
      <div class="feedback-card-icon" aria-hidden="true">${iconHtml}</div>
      <div class="feedback-card-copy">
        ${title ? `<div class="feedback-card-title">${esc(title)}</div>` : ''}
        <p>${esc(message)}</p>
      </div>
    </div>
  `;
}

function emptyStateHtml(message, options = {}) {
  const normalizedType = normalizeFeedbackType(options.type || 'neutral');
  const title = String(options.title || '').trim();
  const iconName = options.icon || 'inbox';
  const iconHtml = `<i data-lucide="${esc(iconName)}"></i>`;

  return `
    <div class="empty-state">
      <div class="icon" aria-hidden="true">${iconHtml}</div>
      <div class="title">${esc(title || 'Nothing to show yet')}</div>
      <p>${esc(message)}</p>
    </div>
  `;
}

function showToast(message, type) {
  const normalizedType = normalizeFeedbackType(type);
  const meta = feedbackMeta(normalizedType);
  let toast = document.getElementById('toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast';
    toast.className = 'toast';
    toast.setAttribute('role', 'status');
    toast.setAttribute('aria-live', 'polite');
    document.body.appendChild(toast);
  }

  window.clearTimeout(toast._showTimer);
  window.clearTimeout(toast._hideTimer);

  toast.classList.remove('show');
  toast.className = `toast is-${normalizedType}`;
  toast.innerHTML = `
    <div class="toast-content">
      <div class="toast-icon" aria-hidden="true">${meta.icon}</div>
      <div class="toast-copy">
        <div class="toast-title">${esc(meta.title)}</div>
        <div class="toast-message">${esc(message)}</div>
      </div>
    </div>
  `;
  if (window.lucide) window.lucide.createIcons();

  toast._showTimer = window.setTimeout(() => {
    toast.classList.add('show');
  }, 10);
  toast._hideTimer = window.setTimeout(() => {
    toast.classList.remove('show');
  }, 3600);
}

function formatTimestamp(ts) {
  if (!ts) return '';
  let date = null;
  if (ts instanceof Date) {
    date = ts;
  } else if (typeof ts.toDate === 'function') {
    date = ts.toDate();
  } else if (typeof ts.seconds === 'number') {
    date = new Date(ts.seconds * 1000);
  } else if (typeof ts === 'number') {
    date = new Date(ts);
  } else if (typeof ts === 'string') {
    const parsed = Date.parse(ts);
    if (!Number.isNaN(parsed)) date = new Date(parsed);
  }
  if (!date || Number.isNaN(date.getTime())) return '';
  const now = new Date();
  const diff = now - date;
  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago';
  if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago';
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function roleColor(role) {
  switch (role) {
    case 'student': return '#2563EB';
    case 'company': return '#14B8A6';
    case 'admin': return '#F59E0B';
    default: return '#64748B';
  }
}

function esc(str) {
  if (!str) return '';
  const d = document.createElement('div');
  d.textContent = String(str);
  return d.innerHTML;
}

export {
  checkAuth,
  emptyStateHtml,
  esc,
  feedbackCardHtml,
  formatTimestamp,
  roleColor,
  showToast,
  stopUnreadNotificationsWatcher,
  updateNotificationBadges,
};
