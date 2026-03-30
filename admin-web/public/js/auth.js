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

function showToast(message, type) {
  let toast = document.getElementById('toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast';
    toast.className = 'toast';
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.className = 'toast ' + type;
  setTimeout(() => toast.classList.add('show'), 10);
  setTimeout(() => toast.classList.remove('show'), 3000);
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

export { checkAuth, showToast, formatTimestamp, roleColor, esc, stopUnreadNotificationsWatcher, updateNotificationBadges };
