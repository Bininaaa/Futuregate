// FutureGate Admin — Premium Shell v3
// Renders the shared sidebar + workspace header.
// Pages mount it via: mountShell({ page, actions })

import { t, getLang, setLang, applyTranslations } from './i18n.js';

const NAV_ITEMS = [
  { id: 'dashboard',     href: '/',             icon: 'layout-dashboard', labelKey: 'nav.dashboard',     labelFallback: 'Dashboard'     },
  { id: 'users',         href: 'users',          icon: 'users',            labelKey: 'nav.users',         labelFallback: 'Users'         },
  { id: 'content',       href: 'moderation',     icon: 'layers',           labelKey: 'nav.content',       labelFallback: 'Content'       },
  { id: 'activity',      href: 'activity',       icon: 'activity',         labelKey: 'nav.activity',      labelFallback: 'Activity'      },
  { id: 'notifications', href: 'notifications',  icon: 'bell',             labelKey: 'nav.notifications', labelFallback: 'Notifications', badge: true },
];

const PAGE_META = {
  dashboard:     { titleKey: 'page.dashboard.title',     titleFallback: 'Dashboard',     eyebrowKey: 'page.dashboard.eyebrow',     eyebrowFallback: 'Overview'    },
  users:         { titleKey: 'page.users.title',         titleFallback: 'Users',         eyebrowKey: 'page.users.eyebrow',         eyebrowFallback: 'Accounts'    },
  content:       { titleKey: 'page.content.title',       titleFallback: 'Content',       eyebrowKey: 'page.content.eyebrow',       eyebrowFallback: 'Moderation'  },
  activity:      { titleKey: 'page.activity.title',      titleFallback: 'Activity',      eyebrowKey: 'page.activity.eyebrow',      eyebrowFallback: 'Live feed'   },
  notifications: { titleKey: 'page.notifications.title', titleFallback: 'Notifications', eyebrowKey: 'page.notifications.eyebrow', eyebrowFallback: 'Inbox'       },
};

const LANG_OPTIONS = [
  { code: 'en', label: 'EN' },
  { code: 'ar', label: 'AR' },
  { code: 'fr', label: 'FR' },
];

function navHtmlForPage(page) {
  return NAV_ITEMS.map((item) => {
    const active = item.id === page ? ' active' : '';
    const current = item.id === page ? ' aria-current="page"' : '';
    const badge = item.badge
      ? `<span class="nav-badge" data-notification-badge hidden>0</span>`
      : '';
    const label = t(item.labelKey, item.labelFallback);
    return `
      <a href="${item.href}" class="nav-item${active}" data-page="${item.id}" data-i18n-title="${item.labelKey}" data-i18n-title-fallback="${item.labelFallback}" title="${label}"${current}>
        <span class="nav-icon"><i data-lucide="${item.icon}"></i></span>
        <span class="nav-label" data-i18n="${item.labelKey}" data-i18n-fallback="${item.labelFallback}">${label}</span>
        ${badge}
      </a>`;
  }).join('');
}

function languageMenuHtml() {
  const current = getLang();
  return `
    <div class="lang-switcher" data-lang-switcher>
      <button class="toolbar-action lang-toggle" type="button" data-lang-toggle
        aria-haspopup="menu" aria-expanded="false"
        data-i18n-aria-label="shell.language" data-i18n-aria-label-fallback="Language"
        aria-label="Language" title="Language">
        <i data-lucide="languages"></i>
        <span class="lang-current">${current.toUpperCase()}</span>
      </button>
      <div class="lang-menu" role="menu" hidden>
        ${LANG_OPTIONS.map((opt) => `
          <button type="button" role="menuitemradio"
            class="lang-menu-item${opt.code === current ? ' is-active' : ''}"
            data-lang-option="${opt.code}"
            aria-checked="${opt.code === current ? 'true' : 'false'}">
            <span class="lang-menu-code">${opt.label}</span>
            <span class="lang-menu-name">${langName(opt.code)}</span>
          </button>
        `).join('')}
      </div>
    </div>
  `;
}

function langName(code) {
  switch (code) {
    case 'ar': return 'العربية';
    case 'fr': return 'Français';
    default:   return 'English';
  }
}

function workspaceActionsHtml(actions = '') {
  return `
    ${languageMenuHtml()}
    <button class="toolbar-action" type="button" data-theme-toggle
      data-i18n-aria-label="shell.toggleTheme" data-i18n-aria-label-fallback="Toggle theme"
      aria-label="Toggle theme">
      <i data-lucide="sun"></i>
    </button>
    <a class="toolbar-action" href="notifications"
      data-i18n-aria-label="shell.notifications" data-i18n-aria-label-fallback="Notifications"
      aria-label="Notifications" style="position:relative">
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
  const meta    = PAGE_META[page] || { titleKey: '', titleFallback: 'Admin', eyebrowKey: '', eyebrowFallback: '' };
  const navHtml = navHtmlForPage(page);
  const existingLayout = document.querySelector('.layout');
  const titleText = t(meta.titleKey, meta.titleFallback);
  const eyebrowText = t(meta.eyebrowKey, meta.eyebrowFallback);

  if (existingLayout && !document.getElementById('shell')) {
    const nav = existingLayout.querySelector('.sidebar-nav');
    const eyebrow = existingLayout.querySelector('.workspace-eyebrow');
    const title = existingLayout.querySelector('.workspace-heading h1');
    const actionsEl = existingLayout.querySelector('.workspace-actions');
    const main = existingLayout.querySelector('#page-main');

    if (nav) nav.innerHTML = navHtml;
    if (eyebrow) {
      eyebrow.setAttribute('data-i18n', meta.eyebrowKey);
      eyebrow.setAttribute('data-i18n-fallback', meta.eyebrowFallback);
      eyebrow.textContent = eyebrowText;
    }
    if (title) {
      title.setAttribute('data-i18n', meta.titleKey);
      title.setAttribute('data-i18n-fallback', meta.titleFallback);
      title.textContent = titleText;
    }
    if (actionsEl) actionsEl.innerHTML = workspaceActionsHtml(actions);
    if (main) main.innerHTML = loadingShellHtml();
    existingLayout.classList.remove('workspace-navigating');

    bindLanguageSwitcher();
    applyTranslations();
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
            <p data-i18n="shell.adminWorkspace" data-i18n-fallback="Admin workspace">${t('shell.adminWorkspace', 'Admin workspace')}</p>
          </div>
        </div>
        <button class="sidebar-collapse-btn" type="button" data-sidebar-collapse-toggle
          data-i18n-aria-label="shell.collapseSidebar" data-i18n-aria-label-fallback="Collapse sidebar"
          data-i18n-title="shell.collapseSidebar" data-i18n-title-fallback="Collapse sidebar"
          aria-label="Collapse sidebar" aria-pressed="false" title="Collapse sidebar">
          <i data-lucide="panel-left-close"></i>
        </button>
      </div>

      <div class="sidebar-section-label" data-i18n="shell.workspace" data-i18n-fallback="Workspace">${t('shell.workspace', 'Workspace')}</div>
      <nav class="sidebar-nav">${navHtml}</nav>

      <div class="sidebar-footer">
        <div class="admin-info">
          <div class="admin-avatar" id="admin-avatar">A</div>
          <div class="admin-meta" style="min-width:0">
            <div class="admin-name"  id="admin-name" data-i18n="shell.admin" data-i18n-fallback="Admin">${t('shell.admin', 'Admin')}</div>
            <div class="admin-email" id="admin-email"></div>
          </div>
        </div>
        <button class="btn-logout" id="btn-logout" type="button">
          <i data-lucide="log-out"></i>
          <span data-i18n="shell.signOut" data-i18n-fallback="Sign out">${t('shell.signOut', 'Sign out')}</span>
        </button>
      </div>
    </aside>

    <!-- ─── Workspace ─── -->
    <div class="workspace">
      <header class="workspace-header">
        <button class="toolbar-icon mobile-only" type="button"
          data-mobile-nav-toggle
          data-i18n-aria-label="shell.openNavigation" data-i18n-aria-label-fallback="Open navigation"
          aria-label="Open navigation" aria-expanded="false">
          <i data-lucide="menu"></i>
        </button>

        <div class="workspace-heading">
          <div class="workspace-eyebrow" data-i18n="${meta.eyebrowKey}" data-i18n-fallback="${meta.eyebrowFallback}">${eyebrowText}</div>
          <h1 data-i18n="${meta.titleKey}" data-i18n-fallback="${meta.titleFallback}">${titleText}</h1>
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

  bindLanguageSwitcher();
  applyTranslations();
  if (window.lucide) window.lucide.createIcons();
}

function bindLanguageSwitcher() {
  const switcher = document.querySelector('[data-lang-switcher]');
  if (!switcher || switcher.dataset.bound === 'true') return;
  switcher.dataset.bound = 'true';

  const toggle = switcher.querySelector('[data-lang-toggle]');
  const menu = switcher.querySelector('.lang-menu');
  if (!toggle || !menu) return;

  function close() {
    menu.hidden = true;
    toggle.setAttribute('aria-expanded', 'false');
  }
  function open() {
    menu.hidden = false;
    toggle.setAttribute('aria-expanded', 'true');
  }

  toggle.addEventListener('click', (event) => {
    event.stopPropagation();
    if (menu.hidden) open();
    else close();
  });

  menu.querySelectorAll('[data-lang-option]').forEach((btn) => {
    btn.addEventListener('click', (event) => {
      event.stopPropagation();
      const code = btn.getAttribute('data-lang-option');
      if (code) {
        setLang(code);
        // Re-render the shell so labels update everywhere; also refresh notifications and active state.
        document.querySelectorAll('[data-lang-switcher]').forEach((node) => {
          node.outerHTML = languageMenuHtml();
        });
        bindLanguageSwitcher();
        applyTranslations();
        if (window.lucide) window.lucide.createIcons();
      }
      close();
    });
  });

  document.addEventListener('click', (event) => {
    if (!switcher.contains(event.target)) close();
  });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') close();
  });
}

export function showPage() {
  const loading = document.getElementById('loading');
  const content = document.getElementById('page-content');
  if (loading) loading.style.display = 'none';
  if (content) content.style.display = 'flex';
  const layout = document.querySelector('.layout');
  layout?.classList.add('auth-ready');
  layout?.classList.remove('workspace-navigating');
  // Translations may have been added by the page after mount.
  applyTranslations();
}

export function setLoading(isLoading) {
  const loading = document.getElementById('loading');
  const content = document.getElementById('page-content');
  if (loading) loading.style.display = isLoading ? 'flex' : 'none';
  if (content) content.style.display = isLoading ? 'none' : 'flex';
  document.querySelector('.layout')?.classList.toggle('workspace-navigating', Boolean(isLoading));
}

// Re-translate page chrome when the language changes.
document.addEventListener('languagechange', () => {
  applyTranslations();
});
