import { mountShell, showPage } from './shell.js';
import {
  checkAuth,
  emptyStateHtml,
  esc,
  feedbackCardHtml,
  formatTimestamp,
  showToast,
} from './auth.js';
import {
  auth,
  collection,
  db,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  updateDoc,
  where,
} from './firebase-config.js';
import {
  friendlyDocumentErrorMessage,
  getCompanyCommercialRegisterDocument,
  getUserCvDocument,
  loadStudentCvSummary,
  openDocumentUrl,
} from './document-access.js';
import { matchesSearch } from './admin-utils.js';
import { openModal } from './ui.js';
import { WORKER_BASE_URL } from './google-books-config.js';

mountShell({ page: 'users' });

const queryParams = new URLSearchParams(window.location.search);
const state = buildInitialState();
const initialTargetId = firstText(
  queryParams.get('userId'),
  queryParams.get('uid'),
  queryParams.get('targetId'),
  queryParams.get('companyId'),
);

checkAuth(async () => {
  await loadUsers();
});

function buildInitialState() {
  const next = {
    all: [],
    filtered: [],
    role: 'all',
    level: 'all',
    approval: 'all',
    status: 'all',
    search: '',
    initialTargetOpened: false,
  };
  const role = normalizeChoice(queryParams.get('role'), [
    'all',
    'student',
    'company',
    'admin',
  ]);
  const level = normalizeChoice(queryParams.get('level'), [
    'all',
    'bac',
    'licence',
    'master',
    'doctorat',
  ]);
  const status = normalizeChoice(queryParams.get('status'), [
    'all',
    'active',
    'blocked',
    'pending',
    'approved',
    'rejected',
  ]);
  const approval = normalizeChoice(queryParams.get('approval'), [
    'all',
    'pending',
    'approved',
    'rejected',
  ]);

  if (role) next.role = role;
  if (level) next.level = level;
  if (approval) next.approval = approval;
  if (status === 'active' || status === 'blocked') next.status = status;
  if (status === 'pending' || status === 'approved' || status === 'rejected') {
    next.approval = status;
  }
  if (next.role !== 'student' && next.role !== 'all') next.level = 'all';
  if (next.role !== 'company' && next.role !== 'all') next.approval = 'all';
  if (next.level !== 'all') next.approval = 'all';

  return next;
}

async function loadUsers() {
  try {
    const snap = await getDocs(
      query(collection(db, 'users'), orderBy('createdAt', 'desc')),
    );
    state.all = snap.docs.map((snapshot) => {
      const data = snapshot.data();
      return { id: snapshot.id, ...data, uid: String(data.uid || snapshot.id) };
    });
    renderShell();
    applyFilters();
    showPage();
    openInitialTargetIfNeeded();
    if (window.lucide) window.lucide.createIcons();
  } catch (error) {
    console.error(error);
    const root = document.getElementById('page-content');
    root.innerHTML = feedbackCardHtml('Could not load users.', {
      type: 'error',
    });
    showPage();
    if (window.lucide) window.lucide.createIcons();
  }
}

function openInitialTargetIfNeeded() {
  if (state.initialTargetOpened || !initialTargetId) return;
  const user = state.all.find(
    (item) => uidForUser(item) === initialTargetId || item.id === initialTargetId,
  );
  if (!user) return;
  state.initialTargetOpened = true;
  viewUser(user.id);
}

function computeStats() {
  const total = state.all.length;
  let active = 0;
  let blocked = 0;
  let admins = 0;
  let pending = 0;

  for (const user of state.all) {
    if (user.role === 'admin') admins++;
    if (user.isActive === false) blocked++;
    else active++;
    if (user.role === 'company' && normalizedApproval(user) === 'pending') {
      pending++;
    }
  }

  return { total, active, blocked, admins, pending };
}

function renderSummaryPills() {
  const stats = computeStats();
  return `
    <span class="summary-pill"><i data-lucide="users"></i><strong>${stats.total}</strong> Total</span>
    <span class="summary-pill is-success"><i data-lucide="check-circle"></i><strong>${stats.active}</strong> Active</span>
    <span class="summary-pill is-danger"><i data-lucide="ban"></i><strong>${stats.blocked}</strong> Blocked</span>
    <span class="summary-pill is-warning"><i data-lucide="clock"></i><strong>${stats.pending}</strong> Pending review</span>
    <span class="summary-pill is-info"><i data-lucide="shield"></i><strong>${stats.admins}</strong> Admins</span>`;
}

function renderShell() {
  const root = document.getElementById('page-content');
  root.innerHTML = `
    <section class="surface-panel">
      <div class="summary-pills">${renderSummaryPills()}</div>

      <div class="chip-row">
        <div class="chip-group" role="tablist" aria-label="Role filter">
          <button type="button" class="chip" data-filter="role" data-value="all"><i data-lucide="users"></i>All</button>
          <button type="button" class="chip" data-filter="role" data-value="student"><i data-lucide="graduation-cap"></i>Students</button>
          <button type="button" class="chip" data-filter="role" data-value="company"><i data-lucide="building-2"></i>Companies</button>
          <button type="button" class="chip" data-filter="role" data-value="admin"><i data-lucide="shield"></i>Admins</button>
        </div>
        <div class="chip-group" id="level-chips" role="tablist" aria-label="Academic level">
          <span class="chip-group__label">Level</span>
          <button type="button" class="chip" data-filter="level" data-value="all">All</button>
          <button type="button" class="chip" data-filter="level" data-value="bac">Bac</button>
          <button type="button" class="chip" data-filter="level" data-value="licence">Licence</button>
          <button type="button" class="chip" data-filter="level" data-value="master">Master</button>
          <button type="button" class="chip" data-filter="level" data-value="doctorat">Doctorat</button>
        </div>
        <div class="chip-group" id="status-chips" role="tablist" aria-label="Account status">
          <span class="chip-group__label">Status</span>
          <button type="button" class="chip" data-filter="status" data-value="all">All</button>
          <button type="button" class="chip" data-filter="status" data-value="active"><i data-lucide="check"></i>Active</button>
          <button type="button" class="chip" data-filter="status" data-value="blocked"><i data-lucide="ban"></i>Blocked</button>
        </div>
        <div class="chip-group" id="approval-chips" role="tablist" aria-label="Company review">
          <span class="chip-group__label">Company review</span>
          <button type="button" class="chip" data-filter="approval" data-value="all">All</button>
          <button type="button" class="chip" data-filter="approval" data-value="pending"><i data-lucide="clock"></i>Pending</button>
          <button type="button" class="chip" data-filter="approval" data-value="approved"><i data-lucide="check"></i>Approved</button>
          <button type="button" class="chip" data-filter="approval" data-value="rejected"><i data-lucide="x-circle"></i>Rejected</button>
        </div>
      </div>

      <div class="filter-bar">
        <div class="search-bar" style="flex:1;">
          <i data-lucide="search"></i>
          <input id="user-search" type="search" value="${esc(state.search)}" placeholder="Search by name, email, or company..."/>
        </div>
      </div>

      <div id="user-summary" style="margin-bottom: 12px; color: var(--c-text-faint); font-size: 13px;"></div>
      <div id="user-list" class="list-grid"></div>
    </section>
  `;

  document.querySelectorAll('[data-filter]').forEach((button) => {
    button.addEventListener('click', () => {
      const filter = button.getAttribute('data-filter');
      const value = button.getAttribute('data-value');
      if (filter === 'role') {
        state.role = value;
        if (value !== 'student' && value !== 'all') state.level = 'all';
        if (value !== 'company' && value !== 'all') state.approval = 'all';
      } else if (filter === 'level') {
        state.level = value;
        if (value !== 'all') state.approval = 'all';
      } else if (filter === 'approval') {
        if (state.level !== 'all' && value !== 'all') return;
        state.approval = value;
      } else {
        state[filter] = value;
      }
      applyFilters();
    });
  });

  document.getElementById('user-search').addEventListener('input', (event) => {
    state.search = event.target.value;
    applyFilters();
  });

  syncChips();
}

function syncChips() {
  document.querySelectorAll('[data-filter]').forEach((button) => {
    const filter = button.getAttribute('data-filter');
    const value = button.getAttribute('data-value');
    button.classList.toggle('active', state[filter] === value);
  });

  const levelChips = document.getElementById('level-chips');
  const approvalChips = document.getElementById('approval-chips');
  if (!levelChips || !approvalChips) return;

  levelChips.style.display =
    state.role === 'student' || state.role === 'all' ? '' : 'none';
  approvalChips.style.display =
    state.role === 'company' || state.role === 'all' ? '' : 'none';

  const levelActive = state.level !== 'all';
  approvalChips.querySelectorAll('.chip').forEach((chip) => {
    chip.style.opacity = levelActive ? '0.45' : '';
    chip.style.pointerEvents = levelActive ? 'none' : '';
    chip.setAttribute('aria-disabled', levelActive ? 'true' : 'false');
  });
}

function normalizedApproval(user) {
  const status = cleanText(user?.approvalStatus).toLowerCase();
  if (status === 'pending' || status === 'approved' || status === 'rejected') {
    return status;
  }
  return user?.role === 'company' ? 'approved' : '';
}

function applyFilters() {
  let users = state.all.slice();
  if (state.role !== 'all') users = users.filter((user) => user.role === state.role);
  if (state.level !== 'all') {
    users = users.filter(
      (user) => cleanText(user.academicLevel).toLowerCase() === state.level,
    );
  }
  if (state.approval !== 'all') {
    users = users.filter(
      (user) => user.role === 'company' && normalizedApproval(user) === state.approval,
    );
  }
  if (state.status === 'active') users = users.filter((user) => user.isActive !== false);
  else if (state.status === 'blocked') {
    users = users.filter((user) => user.isActive === false);
  }
  if (state.search.trim()) {
    users = users.filter((user) =>
      matchesSearch([user.fullName, user.companyName, user.email], state.search),
    );
  }
  state.filtered = users;
  syncChips();
  renderUsers();
}

function renderUsers() {
  const list = document.getElementById('user-list');
  const summary = document.getElementById('user-summary');
  const noun = state.filtered.length === 1 ? 'user' : 'users';
  summary.textContent = `${state.filtered.length} ${noun} shown of ${state.all.length} total.`;

  if (!state.filtered.length) {
    list.innerHTML = emptyStateHtml('Adjust the filters or search differently.', {
      title: 'No users match',
      icon: 'search-x',
    });
    if (window.lucide) window.lucide.createIcons();
    return;
  }

  list.innerHTML = state.filtered.map((user) => userRow(user)).join('');
  list.querySelectorAll('[data-action]').forEach((button) => {
    button.addEventListener('click', (event) => {
      event.preventDefault();
      event.stopPropagation();
      const action = button.getAttribute('data-action');
      const id = button.getAttribute('data-id');
      if (action === 'view') return viewUser(id);
      if (action === 'approve') {
        return confirmAction(
          id,
          { approvalStatus: 'approved' },
          'Approve company',
          'The company will be able to post opportunities.',
        );
      }
      if (action === 'reject') {
        return confirmAction(
          id,
          { approvalStatus: 'rejected' },
          'Reject company',
          'The company will stay visible to admins but cannot post approved content.',
        );
      }
      if (action === 'block') {
        return confirmAction(
          id,
          { isActive: false },
          'Block user',
          'The user will lose access to the app.',
        );
      }
      if (action === 'unblock') {
        return confirmAction(
          id,
          { isActive: true },
          'Unblock user',
          'The user will regain access.',
        );
      }
    });
  });
  list.querySelectorAll('.user-row').forEach((row) => {
    row.addEventListener('click', () => viewUser(row.getAttribute('data-user-id')));
    row.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        viewUser(row.getAttribute('data-user-id'));
      }
    });
  });

  if (window.lucide) window.lucide.createIcons();
}

function userRow(user) {
  const role = cleanText(user.role) || 'user';
  const name = displayName(user);
  const email = cleanText(user.email) || 'Not provided';
  const approval = normalizedApproval(user);
  const isActive = user.isActive !== false;
  const dotClass = !isActive
    ? 'is-blocked'
    : approval === 'pending'
      ? 'is-pending'
      : approval === 'rejected'
        ? 'is-blocked'
        : 'is-active';
  const levelBadge =
    role === 'student' && cleanText(user.academicLevel)
      ? `<span class="badge"><i data-lucide="graduation-cap"></i>${esc(capitalizeLabel(user.academicLevel))}</span>`
      : '';
  const approvalBadge = role === 'company' ? approvalBadgeHtml(approval) : '';
  const accountBadge =
    role !== 'company' || !isActive || approval === 'approved'
      ? accountBadgeHtml(isActive)
      : '';

  const actions = [];
  if (role === 'company') {
    if (approval !== 'approved') {
      actions.push(
        `<button class="btn btn-sm btn-success" data-action="approve" data-id="${esc(uidForUser(user))}"><i data-lucide="check"></i>Approve</button>`,
      );
    }
    if (approval === 'pending') {
      actions.push(
        `<button class="btn btn-sm btn-danger" data-action="reject" data-id="${esc(uidForUser(user))}"><i data-lucide="x"></i>Reject</button>`,
      );
    }
  }
  if (role !== 'admin') {
    actions.push(
      isActive
        ? `<button class="btn btn-sm btn-danger" data-action="block" data-id="${esc(uidForUser(user))}"><i data-lucide="ban"></i>Block</button>`
        : `<button class="btn btn-sm btn-success" data-action="unblock" data-id="${esc(uidForUser(user))}"><i data-lucide="check"></i>Unblock</button>`,
    );
  }
  actions.push(
    `<button class="btn btn-sm" data-action="view" data-id="${esc(uidForUser(user))}"><i data-lucide="eye"></i>View</button>`,
  );

  return `<div class="user-row" data-user-id="${esc(uidForUser(user))}" role="button" tabindex="0" style="cursor:pointer;">
    ${avatarShell(user, dotClass)}
    <div class="row-body">
      <div class="row-title">${esc(name)}</div>
      <div class="row-sub">${esc(email)}</div>
      <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:6px;">
        ${roleBadgeHtml(role)}
        ${approvalBadge}
        ${accountBadge}
        ${levelBadge}
      </div>
    </div>
    <div class="row-actions">${actions.join('')}</div>
  </div>`;
}

function confirmAction(id, payload, title, message) {
  if (!confirm(`${title}\n\n${message}`)) return;
  const successMap = {
    'Approve company': 'Company approved.',
    'Reject company': 'Company rejected.',
    'Move to pending': 'Company moved to pending review.',
    'Block user': 'User blocked.',
    'Unblock user': 'User unblocked.',
  };
  return updateUser(id, payload, successMap[title] || 'Updated.');
}

async function notifyCompanyApprovalStatus(id) {
  const token = await auth.currentUser?.getIdToken();
  if (!token) return;

  const response = await fetch(`${WORKER_BASE_URL}/api/notify/company-approval-status`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ companyId: id }),
  });

  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    console.warn('Company approval notification failed:', payload.error || response.status);
  }
}

async function updateUser(id, payload, successMessage) {
  try {
    await updateDoc(doc(db, 'users', id), payload);
    if (['approved', 'rejected'].includes(cleanText(payload.approvalStatus).toLowerCase())) {
      await notifyCompanyApprovalStatus(id).catch((error) => {
        console.warn('Company approval notification failed:', error);
      });
    }
    const user = state.all.find((item) => uidForUser(item) === id || item.id === id);
    if (user) Object.assign(user, payload);
    applyFilters();
    const pills = document.querySelector('.summary-pills');
    if (pills) pills.innerHTML = renderSummaryPills();
    const openId = document.getElementById('profile-modal').getAttribute('data-user-id');
    if (openId === id) viewUser(id);
    if (window.lucide) window.lucide.createIcons();
    showToast(successMessage, 'success');
  } catch (error) {
    console.error(error);
    showToast('Update failed. Try again.', 'error');
  }
}

async function viewUser(id) {
  openModal('profile-modal');
  const body = document.getElementById('profile-body');
  const titleEl = document.getElementById('profile-title');
  const modal = document.getElementById('profile-modal');
  modal.setAttribute('data-user-id', id);
  body.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
  try {
    const userDoc = await getDoc(doc(db, 'users', id));
    if (!userDoc.exists()) throw new Error('User not found');
    const data = userDoc.data();
    const user = { id, ...data, uid: String(data.uid || id) };
    const role = cleanText(user.role) || 'user';
    const approval = normalizedApproval(user);
    const isActive = user.isActive !== false;
    const name = displayName(user);
    const subtitle =
      role === 'company'
        ? cleanText(user.sector) || cleanText(user.location) || 'Company profile'
        : role === 'student'
          ? cleanText(user.university) || 'Student profile'
          : 'Admin profile';

    titleEl.textContent = name;

    const hero = `
      <div class="profile-hero">
        ${avatarHtml(user, 64)}
        <div>
          <div class="profile-hero__name">${esc(name)}</div>
          <div class="row-sub" style="margin-bottom:8px;">${esc(subtitle)}</div>
          <div class="profile-hero__badges">
            ${roleBadgeHtml(role)}
            ${role === 'company' ? approvalBadgeHtml(approval) : ''}
            ${accountBadgeHtml(isActive)}
            ${
              role === 'student' && cleanText(user.academicLevel)
                ? `<span class="badge"><i data-lucide="graduation-cap"></i>${esc(capitalizeLabel(user.academicLevel))}</span>`
                : ''
            }
          </div>
        </div>
      </div>`;

    const contactHtml = profileSection(
      'contact',
      'Contact',
      [
        profileBlock('Email', cleanText(user.email) || 'Not provided', {
          muted: !cleanText(user.email),
        }),
        profileBlock(
          'Phone',
          cleanText(user.phone)
            ? `<a href="tel:${esc(user.phone)}">${esc(user.phone)}</a>`
            : 'Not provided',
          { html: Boolean(cleanText(user.phone)), muted: !cleanText(user.phone) },
        ),
        profileBlock('Location', cleanText(user.location || user.address) || 'Not provided', {
          muted: !cleanText(user.location || user.address),
        }),
        profileBlock('Joined', formatTimestamp(user.createdAt) || 'Not provided', {
          muted: !formatTimestamp(user.createdAt),
        }),
      ].join(''),
    );

    const accountRows = [
      profileBlock('UID', uidForUser(user)),
      profileBlock('Provider', cleanText(user.provider) || 'email'),
      profileBlock('Posting language', cleanText(user.preferredPostingLanguage) || 'Not provided', {
        muted: !cleanText(user.preferredPostingLanguage),
      }),
      profileBlock('Presence', user.isOnline === true ? 'Online' : lastSeenLabel(user.lastSeenAt), {
        muted: user.isOnline !== true,
      }),
    ];
    if (role === 'student') {
      accountRows.push(
        profileBlock('Onboarding', user.studentOnboardingPending === true ? 'Pending' : 'Complete'),
      );
    }
    if (role === 'admin' && cleanText(user.adminLevel)) {
      accountRows.push(profileBlock('Admin level', user.adminLevel));
    }
    const accountHtml = profileSection('shield-check', 'Account', accountRows.join(''));

    let roleSection = '';
    if (role === 'student') {
      const rows = [
        profileBlock(
          'Academic level',
          cleanText(user.academicLevel) ? capitalizeLabel(user.academicLevel) : 'Not provided',
          { muted: !cleanText(user.academicLevel) },
        ),
        profileBlock('University', cleanText(user.university) || 'Not provided', {
          muted: !cleanText(user.university),
        }),
        profileBlock('Field of study', cleanText(user.fieldOfStudy) || 'Not provided', {
          muted: !cleanText(user.fieldOfStudy),
        }),
      ];
      const academicLevel = cleanText(user.academicLevel).toLowerCase();
      const isDoctorate = academicLevel === 'doctorat' || academicLevel.includes('doctor');
      if (isDoctorate) {
        rows.push(
          profileBlock('Research topic', cleanText(user.researchTopic) || 'Not provided', {
            muted: !cleanText(user.researchTopic),
          }),
          profileBlock('Laboratory', cleanText(user.laboratory) || 'Not provided', {
            muted: !cleanText(user.laboratory),
          }),
          profileBlock('Supervisor', cleanText(user.supervisor) || 'Not provided', {
            muted: !cleanText(user.supervisor),
          }),
          profileBlock('Research domain', cleanText(user.researchDomain) || 'Not provided', {
            muted: !cleanText(user.researchDomain),
          }),
        );
      }
      roleSection = profileSection('graduation-cap', 'Academic', rows.join(''));
    } else if (role === 'company') {
      const website = cleanText(user.website);
      const rows = [
        profileBlock('Company name', cleanText(user.companyName) || cleanText(user.fullName) || 'Not provided', {
          muted: !cleanText(user.companyName || user.fullName),
        }),
        profileBlock('Approval status', approvalBadgeHtml(approval), { html: true }),
        profileBlock('Sector', cleanText(user.sector || user.industry) || 'Not provided', {
          muted: !cleanText(user.sector || user.industry),
        }),
        profileBlock('Website', website ? externalLinkHtml(website) : 'Not provided', {
          html: Boolean(website),
          muted: !website,
        }),
      ];
      if (cleanText(user.companySize)) rows.push(profileBlock('Company size', user.companySize));
      if (cleanText(user.registrationNumber)) {
        rows.push(profileBlock('Registration #', user.registrationNumber));
      }
      roleSection = profileSection('building-2', 'Company', rows.join(''));
    }

    const bioText = cleanText(user.bio || user.description);
    const bioSection = bioText
      ? `
        <div class="profile-section">
          <div class="profile-section__title"><i data-lucide="text"></i>${role === 'company' ? 'About' : 'Bio'}</div>
          <div class="profile-block"><div class="profile-block-value" style="white-space:pre-wrap;">${esc(bioText)}</div></div>
        </div>`
      : '';

    const studentExtras =
      role === 'student'
        ? `
          <div class="profile-section" id="cv-section">
            <div class="profile-section__title"><i data-lucide="file-text"></i>CV</div>
            <div id="cv-block" class="profile-block"><div class="loading" style="padding:10px;"><div class="spinner"></div></div></div>
          </div>
          <div class="profile-section" id="apps-section">
            <div class="profile-section__title"><i data-lucide="send"></i>Applications</div>
            <div id="apps-block" class="profile-block"><div class="loading" style="padding:10px;"><div class="spinner"></div></div></div>
          </div>`
        : '';

    const companyExtras =
      role === 'company'
        ? companyModerationHtml(approval, isActive) +
          companyOpportunitiesHtml() +
          commercialRegisterHtml(user)
        : '';
    const moderationHtml = role !== 'admin' ? accountModerationHtml(isActive) : '';

    body.innerHTML =
      hero +
      contactHtml +
      accountHtml +
      roleSection +
      bioSection +
      studentExtras +
      companyExtras +
      moderationHtml;
    bindProfileActions(id);

    if (role === 'student') {
      loadStudentCvBlock(id);
      loadStudentAppsBlock(id);
    }
    if (role === 'company') {
      loadCompanyOpportunitiesBlock(id, name);
    }

    if (window.lucide) window.lucide.createIcons();
  } catch (error) {
    console.error(error);
    body.innerHTML = feedbackCardHtml('Could not load this profile.', { type: 'error' });
    if (window.lucide) window.lucide.createIcons();
  }
}

function bindProfileActions(id) {
  document.querySelectorAll('[data-mod]').forEach((button) => {
    button.addEventListener('click', () => {
      const action = button.getAttribute('data-mod');
      if (action === 'approve') {
        confirmAction(
          id,
          { approvalStatus: 'approved' },
          'Approve company',
          'The company will be able to post opportunities.',
        );
      }
      if (action === 'reject') {
        confirmAction(
          id,
          { approvalStatus: 'rejected' },
          'Reject company',
          'The company will stay visible to admins but cannot post approved content.',
        );
      }
      if (action === 'set-pending') {
        confirmAction(
          id,
          { approvalStatus: 'pending' },
          'Move to pending',
          'The company will require review again.',
        );
      }
      if (action === 'block') {
        confirmAction(id, { isActive: false }, 'Block user', 'The user will lose access to the app.');
      }
      if (action === 'unblock') {
        confirmAction(id, { isActive: true }, 'Unblock user', 'The user will regain access.');
      }
    });
  });

  document.querySelectorAll('[data-commercial-register]').forEach((button) => {
    button.addEventListener('click', () => {
      openCommercialRegister(id, {
        download: button.getAttribute('data-commercial-register') === 'download',
      });
    });
  });
}

async function loadStudentCvBlock(id) {
  const block = document.getElementById('cv-block');
  if (!block) return;
  try {
    const summary = await loadStudentCvSummary(id);
    const primary = summary?.primary;
    const built = summary?.built;
    const buttons = [];
    if (primary?.isAvailable) {
      buttons.push(
        `<button class="btn btn-sm" data-cv="primary" data-document-action="view" ${primary.isPdf === false ? 'disabled title="Preview requires a PDF file"' : ''}><i data-lucide="file"></i>View uploaded CV</button>`,
      );
      buttons.push(
        '<button class="btn btn-sm" data-cv="primary" data-document-action="download"><i data-lucide="download"></i>Download uploaded CV</button>',
      );
    }
    if (built?.isAvailable) {
      buttons.push(
        '<button class="btn btn-sm" data-cv="built" data-document-action="view"><i data-lucide="file-text"></i>View built CV</button>',
      );
      buttons.push(
        '<button class="btn btn-sm" data-cv="built" data-document-action="download"><i data-lucide="download"></i>Download built CV</button>',
      );
    }
    if (!buttons.length) {
      const builtText = built?.hasBuilderContent
        ? 'Builder data exists, but no exported PDF is available.'
        : 'No CV uploaded yet.';
      block.innerHTML = `<div class="profile-block-value" style="color:var(--c-text-faint);">${esc(builtText)}</div>`;
    } else {
      block.innerHTML = `<div style="display:flex;flex-wrap:wrap;gap:8px;">${buttons.join('')}</div>`;
      block.querySelectorAll('[data-cv]').forEach((button) => {
        button.addEventListener('click', async () => {
          try {
            const variant = button.getAttribute('data-cv');
            const download = button.getAttribute('data-document-action') === 'download';
            const document = await getUserCvDocument(id, { variant });
            openResolvedDocument(document, { download });
          } catch (error) {
            showToast(friendlyDocumentErrorMessage(error), 'error');
          }
        });
      });
    }
    if (window.lucide) window.lucide.createIcons();
  } catch (error) {
    console.warn('CV summary failed:', error);
    block.innerHTML =
      '<div class="profile-block-value" style="color:var(--c-text-faint);">No CV record.</div>';
  }
}

async function loadStudentAppsBlock(id) {
  const block = document.getElementById('apps-block');
  if (!block) return;
  try {
    const snap = await getDocs(query(collection(db, 'applications'), where('studentId', '==', id)));
    const docs = snap.docs
      .slice()
      .sort((left, right) => timestampMs(right.data().appliedAt) - timestampMs(left.data().appliedAt));
    if (docs.length === 0) {
      block.innerHTML =
        '<div class="profile-block-value" style="color:var(--c-text-faint);">No applications yet.</div>';
      return;
    }
    block.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap;">
        <div>
          <div class="profile-block-label">Total applications</div>
          <div class="profile-block-value" style="font-size:20px;font-weight:700;">${docs.length}</div>
        </div>
        <button class="btn btn-sm" id="view-apps-btn"><i data-lucide="list"></i>View all</button>
      </div>`;
    document.getElementById('view-apps-btn').addEventListener('click', () => openAppsList(docs));
    if (window.lucide) window.lucide.createIcons();
  } catch (error) {
    console.warn('Applications summary failed:', error);
    block.innerHTML =
      '<div class="profile-block-value" style="color:var(--c-text-faint);">Could not load applications.</div>';
  }
}

async function openAppsList(docs) {
  openModal('apps-modal');
  document.getElementById('apps-title').textContent = 'Applications';
  const body = document.getElementById('apps-body');
  body.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
  try {
    const appData = docs
      .map((item) => ({ id: item.id, ...item.data() }))
      .sort((left, right) => timestampMs(right.appliedAt) - timestampMs(left.appliedAt));
    const oppIds = Array.from(
      new Set(appData.map((application) => cleanText(application.opportunityId)).filter(Boolean)),
    );
    const oppsMap = new Map();
    await Promise.all(
      oppIds.map(async (opportunityId) => {
        try {
          const snapshot = await getDoc(doc(db, 'opportunities', opportunityId));
          if (snapshot.exists()) oppsMap.set(opportunityId, { id: opportunityId, ...snapshot.data() });
        } catch {}
      }),
    );

    if (!appData.length) {
      body.innerHTML = emptyStateHtml('This student has not applied anywhere yet.', {
        title: 'No applications',
        icon: 'inbox',
      });
    } else {
      body.innerHTML = `<div class="list-grid">${appData
        .map((application) => {
          const opportunity = oppsMap.get(cleanText(application.opportunityId));
          const title = opportunity?.title || application.opportunityTitle || 'Opportunity removed';
          const company = opportunity?.companyName || application.companyName || '';
          const applied = formatTimestamp(application.appliedAt);
          const status = cleanText(application.status || 'submitted').toLowerCase();
          return `<div class="item-row">
            <div class="row-body">
              <div class="row-title">${esc(title)}</div>
              <div class="row-sub">${esc(company)}${applied ? ` - ${esc(applied)}` : ''}</div>
            </div>
            <div style="display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end;">
              <span class="badge ${applicationStatusClass(status)}">${esc(status || 'submitted')}</span>
              ${opportunityStateBadge(opportunity)}
            </div>
          </div>`;
        })
        .join('')}</div>`;
    }
    if (window.lucide) window.lucide.createIcons();
  } catch (error) {
    console.error(error);
    body.innerHTML = feedbackCardHtml('Could not load applications.', { type: 'error' });
    if (window.lucide) window.lucide.createIcons();
  }
}

async function loadCompanyOpportunitiesBlock(companyId, companyName) {
  const block = document.getElementById('company-opportunities-block');
  if (!block) return;
  block.dataset.companyId = companyId;
  try {
    const opportunities = await loadCompanyOpportunities(companyId);
    if (block.dataset.companyId !== companyId) return;
    const countLabel =
      opportunities.length === 1
        ? '1 posted opportunity'
        : `${opportunities.length} posted opportunities`;
    block.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap;">
        <div>
          <div class="profile-block-label">Posted opportunities</div>
          <div class="profile-block-value">${opportunities.length ? esc(countLabel) : 'No opportunities posted yet.'}</div>
        </div>
        <button class="btn btn-sm" id="view-company-opps-btn"><i data-lucide="briefcase"></i>View opportunities</button>
      </div>`;
    document
      .getElementById('view-company-opps-btn')
      .addEventListener('click', () => openCompanyOpportunitiesList(companyName, opportunities));
    if (window.lucide) window.lucide.createIcons();
  } catch (error) {
    console.warn('Company opportunities failed:', error);
    block.innerHTML =
      '<div class="profile-block-value" style="color:var(--c-text-faint);">Opportunity history is unavailable right now.</div>';
  }
}

async function loadCompanyOpportunities(companyId) {
  const snap = await getDocs(query(collection(db, 'opportunities'), where('companyId', '==', companyId)));
  return snap.docs
    .map((item) => ({ id: item.id, ...item.data() }))
    .sort((left, right) => timestampMs(right.createdAt) - timestampMs(left.createdAt));
}

function openCompanyOpportunitiesList(companyName, opportunities) {
  openModal('apps-modal');
  document.getElementById('apps-title').textContent = cleanText(companyName)
    ? `${companyName} opportunities`
    : 'Company opportunities';
  const body = document.getElementById('apps-body');
  if (!opportunities.length) {
    body.innerHTML = emptyStateHtml('This company has not posted any opportunities yet.', {
      title: 'No opportunities',
      icon: 'briefcase',
    });
  } else {
    body.innerHTML = `<div class="list-grid">${opportunities
      .map((opportunity) => {
        const status = effectiveOpportunityStatus(opportunity);
        const type = cleanText(opportunity.type) || 'job';
        const location = cleanText(opportunity.location);
        const created = formatTimestamp(opportunity.createdAt);
        return `<div class="item-row">
          <div class="row-body">
            <div class="row-title">${esc(cleanText(opportunity.title) || 'Untitled opportunity')}</div>
            <div class="row-sub">${esc([location, created].filter(Boolean).join(' - '))}</div>
          </div>
          <div style="display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end;">
            <span class="badge badge-info"><i data-lucide="${opportunityTypeIcon(type)}"></i>${esc(capitalizeLabel(type))}</span>
            <span class="badge ${status === 'open' ? 'badge-success' : 'badge-warning'}">${esc(capitalizeLabel(status))}</span>
            ${opportunity.isHidden === true ? '<span class="badge badge-warning"><i data-lucide="eye-off"></i>Hidden</span>' : ''}
          </div>
        </div>`;
      })
      .join('')}</div>`;
  }
  if (window.lucide) window.lucide.createIcons();
}

async function openCommercialRegister(companyId, { download = false } = {}) {
  try {
    const document = await getCompanyCommercialRegisterDocument(companyId);
    openResolvedDocument(document, { download });
  } catch (error) {
    showToast(friendlyDocumentErrorMessage(error), 'error');
  }
}

function openResolvedDocument(document, { download = false } = {}) {
  const url = download
    ? firstText(document?.downloadUrl, document?.url, document?.viewUrl)
    : firstText(document?.viewUrl, document?.url, document?.downloadUrl);
  if (!url) throw new Error('Document unavailable');
  openDocumentUrl(url, { download, fileName: document?.fileName || '' });
}

function companyModerationHtml(approval, isActive) {
  const buttons = [];
  if (approval !== 'approved') {
    buttons.push(
      '<button class="btn btn-success" data-mod="approve"><i data-lucide="check"></i>Approve company</button>',
    );
  }
  if (approval !== 'rejected') {
    buttons.push(
      '<button class="btn btn-danger" data-mod="reject"><i data-lucide="x"></i>Reject company</button>',
    );
  }
  if (approval !== 'pending') {
    buttons.push(
      '<button class="btn btn-warning" data-mod="set-pending"><i data-lucide="clock"></i>Move to pending</button>',
    );
  }
  if (!buttons.length) return '';
  return `
    <div class="profile-section">
      <div class="profile-section__title"><i data-lucide="shield-check"></i>Company review</div>
      <div class="profile-block">
        <div style="display:flex;flex-wrap:wrap;gap:8px;">${buttons.join('')}</div>
        ${!isActive ? '<div class="profile-block-label" style="margin-top:10px;">Account is currently blocked.</div>' : ''}
      </div>
    </div>`;
}

function accountModerationHtml(isActive) {
  const button = isActive
    ? '<button class="btn btn-danger" data-mod="block"><i data-lucide="ban"></i>Block user</button>'
    : '<button class="btn btn-success" data-mod="unblock"><i data-lucide="check"></i>Unblock user</button>';
  return `
    <div class="profile-section">
      <div class="profile-section__title"><i data-lucide="settings"></i>Access</div>
      <div class="profile-block"><div style="display:flex;flex-wrap:wrap;gap:8px;">${button}</div></div>
    </div>`;
}

function companyOpportunitiesHtml() {
  return `
    <div class="profile-section">
      <div class="profile-section__title"><i data-lucide="briefcase"></i>Posted opportunities</div>
      <div id="company-opportunities-block" class="profile-block"><div class="loading" style="padding:10px;"><div class="spinner"></div></div></div>
    </div>`;
}

function commercialRegisterHtml(user) {
  const hasRegister = hasCommercialRegister(user);
  const uploaded = formatTimestamp(user.commercialRegisterUploadedAt) || 'Not provided';
  const fileName = cleanText(user.commercialRegisterFileName) || 'Commercial register';
  return `
    <div class="profile-section">
      <div class="profile-section__title"><i data-lucide="file-check-2"></i>Commercial register</div>
      <div class="profile-block">
        ${
          hasRegister
            ? `
              <div class="profile-block-label">${esc(fileName)}</div>
              <div class="profile-block-value" style="margin-bottom:12px;color:var(--c-text-faint);font-size:12px;">Uploaded ${esc(uploaded)}</div>
              <div style="display:flex;flex-wrap:wrap;gap:8px;">
                <button class="btn btn-sm" data-commercial-register="view"><i data-lucide="eye"></i>View register</button>
                <button class="btn btn-sm" data-commercial-register="download"><i data-lucide="download"></i>Download register</button>
              </div>`
            : '<div class="profile-block-value" style="color:var(--c-danger);">Commercial register missing.</div>'
        }
      </div>
    </div>`;
}

function profileSection(icon, title, bodyHtml) {
  return `
    <div class="profile-section">
      <div class="profile-section__title"><i data-lucide="${esc(icon)}"></i>${esc(title)}</div>
      <div class="profile-grid">${bodyHtml}</div>
    </div>`;
}

function profileBlock(label, value, { html = false, muted = false } = {}) {
  const display = html ? value : esc(value);
  return `<div class="profile-block"><div class="profile-block-label">${esc(label)}</div><div class="profile-block-value" style="${muted ? 'color:var(--c-text-faint);font-weight:500;' : ''}">${display}</div></div>`;
}

function avatarShell(user, dotClass) {
  return `<div class="avatar-wrap">${avatarHtml(user)}<span class="avatar-dot ${dotClass}"></span></div>`;
}

function avatarHtml(user, size = 42) {
  const role = cleanText(user.role) || 'user';
  const name = displayName(user);
  const initial = (name[0] || '?').toUpperCase();
  const photoUrl = avatarUrl(user);
  const avatarClass = role === 'company' ? 'user-avatar logo-contain' : 'user-avatar';
  const sizeStyle = size ? `width:${size}px;height:${size}px;` : '';
  if (!photoUrl) {
    return `<div class="${avatarClass}" style="${sizeStyle}background:${roleBg(role)};color:${roleColor(role)}">${esc(initial)}</div>`;
  }
  return `<div class="${avatarClass}" style="${sizeStyle}"><img src="${esc(photoUrl)}" alt="" onerror="this.parentNode.innerHTML='${esc(initial)}';this.parentNode.style.background='${roleBg(role)}';this.parentNode.style.color='${roleColor(role)}';"></div>`;
}

function roleBadgeHtml(role) {
  const safeRole = cleanText(role) || 'user';
  const label =
    safeRole === 'student'
      ? 'Student'
      : safeRole === 'company'
        ? 'Company'
        : safeRole === 'admin'
          ? 'Admin'
          : 'User';
  const cls =
    safeRole === 'student'
      ? 'badge-info'
      : safeRole === 'company'
        ? 'badge-success'
        : safeRole === 'admin'
          ? 'badge-warning'
          : '';
  const icon =
    safeRole === 'student'
      ? 'graduation-cap'
      : safeRole === 'company'
        ? 'building-2'
        : safeRole === 'admin'
          ? 'shield'
          : 'user';
  return `<span class="badge ${cls}"><i data-lucide="${icon}"></i>${label}</span>`;
}

function approvalBadgeHtml(status) {
  const safeStatus = status === 'pending' || status === 'rejected' ? status : 'approved';
  const cls =
    safeStatus === 'pending'
      ? 'badge-warning'
      : safeStatus === 'rejected'
        ? 'badge-danger'
        : 'badge-success';
  const icon =
    safeStatus === 'pending' ? 'clock' : safeStatus === 'rejected' ? 'x-circle' : 'badge-check';
  const label =
    safeStatus === 'pending'
      ? 'Pending review'
      : safeStatus === 'rejected'
        ? 'Rejected'
        : 'Approved';
  return `<span class="badge ${cls}"><i data-lucide="${icon}"></i>${label}</span>`;
}

function accountBadgeHtml(isActive) {
  return isActive
    ? '<span class="badge badge-success"><i data-lucide="check"></i>Active</span>'
    : '<span class="badge badge-danger"><i data-lucide="ban"></i>Blocked</span>';
}

function applicationStatusClass(status) {
  if (status === 'accepted') return 'badge-success';
  if (status === 'rejected' || status === 'withdrawn') return 'badge-danger';
  if (status === 'reviewing') return 'badge-info';
  return 'badge-warning';
}

function opportunityStateBadge(opportunity) {
  if (!opportunity) return '<span class="badge badge-danger">Opportunity unavailable</span>';
  if (opportunity.isHidden === true) {
    return '<span class="badge badge-warning"><i data-lucide="eye-off"></i>Opportunity hidden</span>';
  }
  if (effectiveOpportunityStatus(opportunity) === 'closed') {
    return '<span class="badge badge-warning">Opportunity closed</span>';
  }
  return '';
}

function effectiveOpportunityStatus(opportunity) {
  const status = cleanText(opportunity?.status).toLowerCase();
  if (status === 'closed') return 'closed';
  const deadline = dateFromValue(opportunity?.applicationDeadline || opportunity?.deadline);
  if (deadline && deadline.getTime() < Date.now()) return 'closed';
  return 'open';
}

function opportunityTypeIcon(type) {
  const normalized = cleanText(type).toLowerCase();
  if (normalized === 'internship') return 'user-check';
  if (normalized === 'freelance') return 'laptop';
  if (normalized === 'volunteer') return 'heart-handshake';
  if (normalized === 'contract') return 'file-signature';
  return 'briefcase';
}

function hasCommercialRegister(user) {
  return Boolean(
    firstText(
      user?.commercialRegisterStoragePath,
      user?.commercialRegisterObjectKey,
      user?.commercialRegisterAccessPath,
      user?.commercialRegisterUrl,
      user?.commercialRegisterAccessUrl,
      user?.commercialRegisterSignedUrl,
    ),
  );
}

function lastSeenLabel(value) {
  const formatted = formatTimestamp(value);
  return formatted ? `Last seen ${formatted}` : 'Offline';
}

function externalLinkHtml(value) {
  const label = cleanText(value);
  const href = /^https?:\/\//i.test(label) ? label : `https://${label}`;
  return `<a href="${esc(href)}" target="_blank" rel="noopener">${esc(label)}</a>`;
}

function avatarUrl(user) {
  if (user?.role === 'company') {
    return firstText(user.logo, user.companyLogo, user.logoUrl, user.companyLogoUrl);
  }
  return firstText(
    user?.profileImage,
    user?.photoURL,
    user?.photoUrl,
    user?.profileImageUrl,
    user?.profilePhotoUrl,
    user?.profilePictureUrl,
    user?.avatarUrl,
  );
}

function roleColor(role) {
  return role === 'student'
    ? '#2563EB'
    : role === 'company'
      ? '#14B8A6'
      : role === 'admin'
        ? '#F59E0B'
        : '#64748B';
}

function roleBg(role) {
  return role === 'student'
    ? '#2563EB1a'
    : role === 'company'
      ? '#14B8A61a'
      : role === 'admin'
        ? '#F59E0B1a'
        : '#64748B1a';
}

function displayName(user) {
  return firstText(user?.fullName, user?.companyName, user?.email, 'Unknown');
}

function uidForUser(user) {
  return cleanText(user?.uid) || cleanText(user?.id);
}

function capitalizeLabel(value) {
  const text = cleanText(value);
  if (!text) return '';
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function normalizeChoice(value, allowed) {
  const normalized = cleanText(value).toLowerCase();
  return allowed.includes(normalized) ? normalized : '';
}

function firstText(...values) {
  for (const value of values) {
    const text = cleanText(value);
    if (text) return text;
  }
  return '';
}

function cleanText(value) {
  return String(value ?? '').trim();
}

function timestampMs(value) {
  const date = dateFromValue(value);
  return date ? date.getTime() : 0;
}

function dateFromValue(value) {
  if (!value) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (typeof value.toDate === 'function') {
    const date = value.toDate();
    return date && !Number.isNaN(date.getTime()) ? date : null;
  }
  if (typeof value.seconds === 'number') return new Date(value.seconds * 1000);
  if (typeof value === 'number') return Number.isFinite(value) ? new Date(value) : null;
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : new Date(parsed);
  }
  return null;
}
