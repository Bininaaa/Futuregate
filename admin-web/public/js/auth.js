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

const THEME_STORAGE_KEY = 'futuregate-admin-theme';

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

function initializeChrome() {
  applyTheme(resolveInitialTheme());

  if (chromeInitialized) {
    return;
  }

  chromeInitialized = true;

  document.addEventListener('click', (event) => {
    if (event.target.closest('[data-theme-toggle]')) {
      toggleTheme();
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

function checkAuth(callback) {
  const layout = document.querySelector('.layout');
  const gate = document.getElementById('auth-gate');

  initializeChrome();
  resetToGatedState();

  window.addEventListener('pageshow', (e) => {
    if (e.persisted) {
      resetToGatedState();
      const currentUser = auth.currentUser;
      if (!currentUser) {
        window.location.href = '/login.html';
      } else {
        getDoc(doc(db, 'users', currentUser.uid)).then((userDoc) => {
          if (
            !userDoc.exists() ||
            userDoc.data().role !== 'admin' ||
            userDoc.data().isActive === false
          ) {
            stopUnreadNotificationsWatcher();
            auth.signOut().then(() => {
              window.location.href = '/login.html';
            });
          } else {
            const userData = userDoc.data();
            setupSidebar(userData, currentUser);
            startUnreadNotificationsWatcher(currentUser.uid);
            if (gate) gate.classList.add('hidden');
            if (layout) layout.classList.add('auth-ready');
          }
        }).catch(() => {
          stopUnreadNotificationsWatcher();
          window.location.href = '/login.html';
        });
      }
    }
  });

  onAuthStateChanged(auth, async (user) => {
    if (!user) {
      stopUnreadNotificationsWatcher();
      window.location.href = '/login.html';
      return;
    }
    try {
      const userDoc = await getDoc(doc(db, 'users', user.uid));
      if (
        !userDoc.exists() ||
        userDoc.data().role !== 'admin' ||
        userDoc.data().isActive === false
      ) {
        stopUnreadNotificationsWatcher();
        await auth.signOut();
        window.location.href = '/login.html';
        return;
      }
      const userData = userDoc.data();
      setupSidebar(userData, user);
      startUnreadNotificationsWatcher(user.uid);
      if (gate) gate.classList.add('hidden');
      if (layout) layout.classList.add('auth-ready');
      if (callback) callback(user, userData);
    } catch (e) {
      console.error('Auth check error:', e);
      stopUnreadNotificationsWatcher();
      window.location.href = '/login.html';
    }
  });
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
      window.location.href = '/login.html';
    };
  }

  const currentPage = window.location.pathname.split('/').pop() || 'index.html';
  document.querySelectorAll('.nav-item').forEach(item => {
    const href = item.getAttribute('href');
    if (href === currentPage || (currentPage === '' && href === 'index.html')) {
      item.classList.add('active');
    }
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
