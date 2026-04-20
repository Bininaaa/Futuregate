// Renders the shared admin shell (sidebar + workspace header)
// Pages mount it by including <div id="shell"></div> and calling mountShell({ page, title }).

const NAV_ITEMS = [
  { id: 'dashboard', href: 'index.html', icon: 'layout-dashboard', label: 'Dashboard' },
  { id: 'users', href: 'users.html', icon: 'users', label: 'Users' },
  { id: 'content', href: 'moderation.html', icon: 'layers', label: 'Content' },
  { id: 'activity', href: 'activity.html', icon: 'activity', label: 'Activity' },
  { id: 'notifications', href: 'notifications.html', icon: 'bell', label: 'Notifications', badge: true },
];

const PAGE_META = {
  dashboard:    { title: 'Dashboard',     eyebrow: 'Overview' },
  users:        { title: 'Users',         eyebrow: 'Accounts' },
  content:      { title: 'Content',       eyebrow: 'Moderation' },
  activity:     { title: 'Activity',      eyebrow: 'Live feed' },
  notifications:{ title: 'Notifications', eyebrow: 'Inbox' },
};

export function mountShell({ page = 'dashboard', actions = '' } = {}) {
  const meta = PAGE_META[page] || { title: 'Admin', eyebrow: '' };
  const navHtml = NAV_ITEMS.map((item) => `
    <a href="${item.href}" class="nav-item${item.id === page ? ' active' : ''}" data-page="${item.id}">
      <i data-lucide="${item.icon}"></i>
      <span>${item.label}</span>
      ${item.badge ? '<span class="nav-badge" data-notification-badge hidden>0</span>' : ''}
    </a>
  `).join('');

  const html = `
    <div class="shell-backdrop" data-shell-backdrop></div>
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="sidebar-brand">
          <div class="sidebar-brand-icon"><i data-lucide="shield-check"></i></div>
          <div class="sidebar-brand-text">
            <h2>FutureGate</h2>
            <p>Admin workspace</p>
          </div>
        </div>
      </div>
      <div class="sidebar-section-label">Workspace</div>
      <nav class="sidebar-nav">
        ${navHtml}
      </nav>
      <div class="sidebar-footer">
        <div class="admin-info">
          <div class="admin-avatar" id="admin-avatar">A</div>
          <div style="min-width: 0;">
            <div class="admin-name" id="admin-name">Admin</div>
            <div class="admin-email" id="admin-email"></div>
          </div>
        </div>
        <button class="btn-logout" id="btn-logout" type="button">
          <i data-lucide="log-out"></i>
          <span>Sign out</span>
        </button>
      </div>
    </aside>
    <div class="workspace">
      <header class="workspace-header">
        <button class="toolbar-icon mobile-only" type="button" data-mobile-nav-toggle aria-label="Open navigation" aria-expanded="false">
          <i data-lucide="menu"></i>
        </button>
        <div class="workspace-heading">
          <div class="workspace-eyebrow">${meta.eyebrow}</div>
          <h1>${meta.title}</h1>
        </div>
        <div class="workspace-actions">
          <button class="toolbar-action" type="button" data-theme-toggle aria-label="Toggle theme">
            <i data-lucide="sun"></i>
          </button>
          <a class="toolbar-action" href="notifications.html" aria-label="Notifications">
            <i data-lucide="bell"></i>
            <span class="toolbar-pill-badge" data-notification-badge hidden>0</span>
          </a>
          ${actions}
        </div>
      </header>
      <main class="main-content page-shell" id="page-main">
        <div id="loading" class="loading"><div class="spinner"></div></div>
        <div id="page-content" style="display: none; flex-direction: column; gap: 20px;"></div>
      </main>
    </div>
  `;

  const shell = document.getElementById('shell');
  if (shell) {
    const layout = document.createElement('div');
    layout.className = 'layout';
    layout.innerHTML = html;
    shell.replaceWith(layout);
  }

  if (window.lucide) window.lucide.createIcons();
}

export function showPage() {
  const loading = document.getElementById('loading');
  const content = document.getElementById('page-content');
  if (loading) loading.style.display = 'none';
  if (content) content.style.display = 'flex';
}

export function setLoading(isLoading) {
  const loading = document.getElementById('loading');
  const content = document.getElementById('page-content');
  if (loading) loading.style.display = isLoading ? 'flex' : 'none';
  if (content && !isLoading) content.style.display = 'flex';
}
