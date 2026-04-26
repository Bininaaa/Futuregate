// FutureGate Admin — Premium Shell v3
// Renders the shared sidebar + workspace header.
// Pages mount it via: mountShell({ page, actions })

const NAV_ITEMS = [
  { id: 'dashboard',     href: 'index.html',         icon: 'layout-dashboard', label: 'Dashboard'     },
  { id: 'users',         href: 'users.html',          icon: 'users',            label: 'Users'         },
  { id: 'content',       href: 'moderation.html',     icon: 'layers',           label: 'Content'       },
  { id: 'activity',      href: 'activity.html',       icon: 'activity',         label: 'Activity'      },
  { id: 'notifications', href: 'notifications.html',  icon: 'bell',             label: 'Notifications', badge: true },
];

const PAGE_META = {
  dashboard:     { title: 'Dashboard',     eyebrow: 'Overview'    },
  users:         { title: 'Users',         eyebrow: 'Accounts'    },
  content:       { title: 'Content',       eyebrow: 'Moderation'  },
  activity:      { title: 'Activity',      eyebrow: 'Live feed'   },
  notifications: { title: 'Notifications', eyebrow: 'Inbox'       },
};

function navHtmlForPage(page) {
  return NAV_ITEMS.map((item) => {
    const active = item.id === page ? ' active' : '';
    const current = item.id === page ? ' aria-current="page"' : '';
    const badge = item.badge
      ? `<span class="nav-badge" data-notification-badge hidden>0</span>`
      : '';
    return `
      <a href="${item.href}" class="nav-item${active}" data-page="${item.id}" title="${item.label}"${current}>
        <span class="nav-icon"><i data-lucide="${item.icon}"></i></span>
        <span class="nav-label">${item.label}</span>
        ${badge}
      </a>`;
  }).join('');
}

function workspaceActionsHtml(actions = '') {
  return `
    <button class="toolbar-action" type="button" data-theme-toggle aria-label="Toggle theme">
      <i data-lucide="sun"></i>
    </button>
    <a class="toolbar-action" href="notifications.html" aria-label="Notifications" style="position:relative">
      <i data-lucide="bell"></i>
      <span class="toolbar-pill-badge" data-notification-badge hidden>0</span>
    </a>
    ${actions}
  `;
}

function loadingShellHtml() {
  return `
    <div id="loading" class="loading"><div class="spinner"></div></div>
    <div id="page-content" style="display:none;flex-direction:column;gap:20px;"></div>
  `;
}

export function mountShell({ page = 'dashboard', actions = '' } = {}) {
  const meta    = PAGE_META[page] || { title: 'Admin', eyebrow: '' };
  const navHtml = navHtmlForPage(page);
  const existingLayout = document.querySelector('.layout');

  if (existingLayout && !document.getElementById('shell')) {
    const nav = existingLayout.querySelector('.sidebar-nav');
    const eyebrow = existingLayout.querySelector('.workspace-eyebrow');
    const title = existingLayout.querySelector('.workspace-heading h1');
    const actionsEl = existingLayout.querySelector('.workspace-actions');
    const main = existingLayout.querySelector('#page-main');

    if (nav) nav.innerHTML = navHtml;
    if (eyebrow) eyebrow.textContent = meta.eyebrow;
    if (title) title.textContent = meta.title;
    if (actionsEl) actionsEl.innerHTML = workspaceActionsHtml(actions);
    if (main) main.innerHTML = loadingShellHtml();
    existingLayout.classList.remove('workspace-navigating');

    if (window.lucide) window.lucide.createIcons();
    return;
  }

  const html = `
    <div class="shell-backdrop" data-shell-backdrop></div>

    <!-- ─── Sidebar ─── -->
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="sidebar-brand">
          <div class="sidebar-brand-icon">
            <i data-lucide="shield-check"></i>
          </div>
          <div class="sidebar-brand-text">
            <h2>FutureGate</h2>
            <p>Admin workspace</p>
          </div>
        </div>
        <button class="sidebar-collapse-btn" type="button" data-sidebar-collapse-toggle
          aria-label="Collapse sidebar" aria-pressed="false" title="Collapse sidebar">
          <i data-lucide="panel-left-close"></i>
        </button>
      </div>

      <div class="sidebar-section-label">Workspace</div>
      <nav class="sidebar-nav">${navHtml}</nav>

      <div class="sidebar-footer">
        <div class="admin-info">
          <div class="admin-avatar" id="admin-avatar">A</div>
          <div class="admin-meta" style="min-width:0">
            <div class="admin-name"  id="admin-name">Admin</div>
            <div class="admin-email" id="admin-email"></div>
          </div>
        </div>
        <button class="btn-logout" id="btn-logout" type="button">
          <i data-lucide="log-out"></i>
          <span>Sign out</span>
        </button>
      </div>
    </aside>

    <!-- ─── Workspace ─── -->
    <div class="workspace">
      <header class="workspace-header">
        <button class="toolbar-icon mobile-only" type="button"
          data-mobile-nav-toggle aria-label="Open navigation" aria-expanded="false">
          <i data-lucide="menu"></i>
        </button>

        <div class="workspace-heading">
          <div class="workspace-eyebrow">${meta.eyebrow}</div>
          <h1>${meta.title}</h1>
        </div>

        <div class="workspace-actions">
          ${workspaceActionsHtml(actions)}
        </div>
      </header>

      <main class="main-content page-shell" id="page-main">
        ${loadingShellHtml()}
      </main>
    </div>
  `;

  const shell = document.getElementById('shell');
  if (shell) {
    const layout     = document.createElement('div');
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
  const layout = document.querySelector('.layout');
  layout?.classList.add('auth-ready');
  layout?.classList.remove('workspace-navigating');
}

export function setLoading(isLoading) {
  const loading = document.getElementById('loading');
  const content = document.getElementById('page-content');
  if (loading) loading.style.display = isLoading ? 'flex' : 'none';
  if (content) content.style.display = isLoading ? 'none' : 'flex';
  document.querySelector('.layout')?.classList.toggle('workspace-navigating', Boolean(isLoading));
}
