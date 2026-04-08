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

function stopUnreadNotificationsWatcher() {
  if (typeof unreadNotificationsUnsubscribe === 'function') {
    unreadNotificationsUnsubscribe();
    unreadNotificationsUnsubscribe = null;
  }
}

function resetToGatedState() {
  const layout = document.querySelector('.layout');
  const gate = document.getElementById('auth-gate');
  if (layout) layout.classList.remove('auth-ready');
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
      return { icon: 'OK', title: 'Success' };
    case 'error':
      return { icon: '!', title: 'Something went wrong' };
    case 'warning':
      return { icon: '!', title: 'Attention needed' };
    case 'neutral':
      return { icon: '...', title: 'Update' };
    case 'info':
    default:
      return { icon: 'i', title: 'Notice' };
  }
}

function feedbackCardHtml(message, options = {}) {
  const normalizedType = normalizeFeedbackType(options.type);
  const meta = feedbackMeta(normalizedType);
  const title = String(options.title || meta.title || '').trim();
  const icon = String(options.icon || meta.icon || '').trim();

  return `
    <div class="feedback-card is-${normalizedType}">
      <div class="feedback-card-icon" aria-hidden="true">${esc(icon)}</div>
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
  const icon = String(options.icon || feedbackMeta(normalizedType).icon || '...').trim();

  return `
    <div class="empty-state">
      <div class="icon" aria-hidden="true">${esc(icon)}</div>
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
      <div class="toast-icon" aria-hidden="true">${esc(meta.icon)}</div>
      <div class="toast-copy">
        <div class="toast-title">${esc(meta.title)}</div>
        <div class="toast-message">${esc(message)}</div>
      </div>
    </div>
  `;

  toast._showTimer = window.setTimeout(() => {
    toast.classList.add('show');
  }, 10);
  toast._hideTimer = window.setTimeout(() => {
    toast.classList.remove('show');
  }, 3600);
}

function formatTimestamp(ts) {
  if (!ts) return '';
  const date = ts.toDate ? ts.toDate() : new Date(ts.seconds * 1000);
  const now = new Date();
  const diff = now - date;
  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago';
  if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago';
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function roleColor(role) {
  switch (role) {
    case 'student': return '#2196F3';
    case 'company': return '#009688';
    case 'admin': return '#FF8C00';
    default: return '#777';
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
