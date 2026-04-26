import { auth, db, doc, getDoc, collection, getDocs, query, where } from './firebase-config.js';
import { esc, emptyStateHtml, feedbackCardHtml, formatTimestamp, showToast } from './auth.js';
import { openModal, closeModal } from './ui.js';
import { typeColor, typeIcon, activityTypeLabel, formatFullTimestamp } from './admin-utils.js';
import {
  friendlyDocumentErrorMessage,
  getCompanyCommercialRegisterDocument,
  openDocumentUrl,
} from './document-access.js';

const MODAL_ID = 'details-modal';

function ensureModal() {
  let modal = document.getElementById(MODAL_ID);
  if (modal) return modal;
  modal = document.createElement('div');
  modal.className = 'modal-backdrop';
  modal.id = MODAL_ID;
  modal.innerHTML = `
    <div class="modal modal-lg details-modal">
      <div class="modal-header details-header">
        <div class="details-header-main">
          <div class="details-header-icon" id="details-icon"><i data-lucide="info"></i></div>
          <div>
            <div class="details-eyebrow" id="details-eyebrow">Details</div>
            <h3 id="details-title">Details</h3>
          </div>
        </div>
        <button class="modal-close" data-close-modal="${MODAL_ID}" aria-label="Close"><i data-lucide="x"></i></button>
      </div>
      <div class="modal-body" id="details-body"></div>
      <div class="modal-footer" id="details-footer"></div>
    </div>`;
  document.body.appendChild(modal);
  return modal;
}

function setHeader({ icon = 'info', color = 'var(--c-primary)', eyebrow = 'Details', title = 'Details' }) {
  const iconEl = document.getElementById('details-icon');
  iconEl.style.background = color + '1a';
  iconEl.style.color = color;
  iconEl.innerHTML = `<i data-lucide="${icon}"></i>`;
  document.getElementById('details-eyebrow').textContent = eyebrow;
  document.getElementById('details-title').textContent = title;
}

function setBody(html) { document.getElementById('details-body').innerHTML = html; }
function setFooter(html) { document.getElementById('details-footer').innerHTML = html || ''; }

function renderLoading() {
  setBody('<div class="details-loading"><div class="spinner"></div><p>Loading details…</p></div>');
  setFooter('');
}

function renderError(message) {
  setBody(feedbackCardHtml(message || 'Could not load details.', { type: 'error', title: 'Something went wrong' }));
  setFooter('');
}

function kvGrid(pairs) {
  const visible = pairs.filter((p) => p && p.value !== null && p.value !== undefined && String(p.value).trim() !== '');
  if (visible.length === 0) return '';
  return `<div class="details-kv">${visible.map((p) => `
    <div class="details-kv-row">
      <div class="details-kv-label"><i data-lucide="${p.icon || 'dot'}"></i>${esc(p.label)}</div>
      <div class="details-kv-value">${p.html ? p.value : esc(String(p.value))}</div>
    </div>
  `).join('')}</div>`;
}

function section(title, html, icon = 'layers') {
  if (!html) return '';
  return `<div class="details-section">
    <div class="details-section-title"><i data-lucide="${icon}"></i>${esc(title)}</div>
    ${html}
  </div>`;
}

function chips(list, color) {
  if (!Array.isArray(list) || list.length === 0) return '';
  return `<div class="details-chips">${list.map((v) => `<span class="badge" style="background:${color || 'var(--c-surface-hover)'}">${esc(String(v))}</span>`).join('')}</div>`;
}

function paragraphs(text) {
  if (!text) return '';
  return `<div class="details-prose">${String(text).split(/\n+/).map((p) => `<p>${esc(p)}</p>`).join('')}</div>`;
}

function statusBadge(status) {
  if (!status) return '';
  const map = { approved: 'success', active: 'success', pending: 'warning', draft: 'warning', closed: 'danger', rejected: 'danger', reviewed: 'info', accepted: 'success', blocked: 'danger', open: 'success' };
  const label = String(status).replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  return `<span class="badge badge-${map[status] || 'primary'}">${esc(label)}</span>`;
}

function capitalizeFirst(str) {
  if (!str) return '';
  return String(str).charAt(0).toUpperCase() + String(str).slice(1);
}

function activeAdminId() {
  return String(auth.currentUser?.uid || '').trim();
}

function canEditOpportunity(item) {
  const adminId = activeAdminId();
  return !!adminId &&
    String(item?.createdByRole || '').trim().toLowerCase() === 'admin' &&
    String(item?.companyId || '').trim() === adminId;
}

function canEditIdea(item) {
  const adminId = activeAdminId();
  return !!adminId && String(item?.submittedBy || '').trim() === adminId;
}

function canEditScholarship(item) {
  const adminId = activeAdminId();
  const createdBy = String(item?.createdBy || '').trim();
  const createdByRole = String(item?.createdByRole || '').trim().toLowerCase();
  return !!adminId && createdBy === adminId && (!createdByRole || createdByRole === 'admin');
}

function editLink(canEdit, href, label = 'Edit Admin post') {
  return canEdit
    ? `<a class="btn btn-primary" href="${href}"><i data-lucide="pencil"></i>${esc(label)}</a>`
    : '';
}

export function closeDetailsModal() { closeModal(MODAL_ID); }

export async function openDetailsModal(type, id) {
  ensureModal();
  openModal(MODAL_ID);
  renderLoading();
  if (window.lucide) window.lucide.createIcons();
  try {
    switch (type) {
      case 'opportunity': return await renderOpportunity(id);
      case 'scholarship': return await renderScholarship(id);
      case 'project_idea':
      case 'idea': return await renderIdea(id);
      case 'training': return await renderTraining(id);
      case 'application': return await renderApplication(id);
      case 'user': return await renderUser(id);
      default: return renderError('Unsupported detail type.');
    }
  } catch (e) {
    console.error('details load failed', e);
    renderError();
  }
}

async function fetchDoc(path, id) {
  const snap = await getDoc(doc(db, path, id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() };
}

async function renderOpportunity(id) {
  const it = await fetchDoc('opportunities', id);
  if (!it) return renderError('Opportunity not found.');
  const requirements = Array.isArray(it.requirementItems) && it.requirementItems.length
    ? it.requirementItems.join('\n')
    : it.requirements;

  let applications = [];
  try {
    const snap = await getDocs(query(collection(db, 'applications'), where('opportunityId', '==', id)));
    applications = snap.docs.map((item) => ({ id: item.id, ...item.data() }));
  } catch {}
  const appCounts = applicationStatusCounts(applications);

  const typeLabel = capitalizeFirst(it.type || it.opportunityType || 'Job');
  const salaryRange = buildSalaryRange(it);
  const publisherId = String(it.companyId || '').trim();

  setHeader({ icon: 'briefcase', color: typeColor('opportunity'), eyebrow: 'Opportunity', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Publisher', value: it.companyName, icon: 'building-2' },
      { label: 'Location', value: it.location, icon: 'map-pin' },
      { label: 'Type', value: typeLabel, icon: 'tag' },
      { label: 'Status', value: statusBadge(it.status || 'open'), html: true, icon: 'circle-dot' },
      { label: 'Work Mode', value: capitalizeFirst(it.workMode || ''), icon: 'monitor' },
      { label: 'Employment', value: capitalizeFirst((it.employmentType || '').replace(/_/g, ' ')), icon: 'briefcase' },
      { label: 'Amount', value: salaryRange || (it.isPaid === false ? 'Unpaid' : ''), icon: 'coins' },
      { label: 'Deadline', value: formatFullTimestamp(it.applicationDeadline || it.deadline), icon: 'calendar-clock' },
      { label: 'Posted', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    ])}
    ${section('Description', paragraphs(it.description), 'align-left')}
    ${section('Requirements', paragraphs(requirements), 'list-checks')}
    ${section('Applications', applicationSummaryHtml(appCounts), 'file-text')}
    ${section('Skills', chips(it.skills, 'rgba(59,130,246,0.1)'), 'sparkles')}
    <div class="details-flags">
      ${it.isFeatured ? '<span class="badge badge-warning"><i data-lucide="star"></i>Featured</span>' : ''}
      ${it.isHidden ? '<span class="badge badge-danger"><i data-lucide="eye-off"></i>Hidden</span>' : ''}
    </div>
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}"><i data-lucide="x"></i>Close</button>
    ${publisherId ? `<button class="btn btn-ghost" id="view-publisher-btn" data-user-id="${esc(publisherId)}"><i data-lucide="user"></i>Publisher profile</button>` : ''}
    ${editLink(canEditOpportunity(it), `opp-editor?id=${encodeURIComponent(id)}`)}
  `);
  bindPublisherBtn();
  if (window.lucide) window.lucide.createIcons();
}

async function renderScholarship(id) {
  const it = await fetchDoc('scholarships', id);
  if (!it) return renderError('Scholarship not found.');
  const applyLink = it.link || it.applyUrl || '';
  const eligibility = Array.isArray(it.eligibilityItems) && it.eligibilityItems.length
    ? it.eligibilityItems.join('\n')
    : it.eligibility;
  const isFeatured = it.featured === true || it.isFeatured === true;
  const fundingLabel = (it.fundingType || '').replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  const publisherId = String(it.createdBy || '').trim();

  setHeader({ icon: 'graduation-cap', color: typeColor('scholarship'), eyebrow: 'Scholarship', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Provider', value: it.provider || it.organization, icon: 'building-2' },
      { label: 'Country', value: it.country, icon: 'map-pin' },
      { label: 'City', value: it.city, icon: 'map-pin' },
      { label: 'Amount', value: it.amount, icon: 'coins' },
      { label: 'Funding Type', value: fundingLabel, icon: 'tag' },
      { label: 'Level', value: capitalizeFirst(it.level || it.academicLevel || ''), icon: 'graduation-cap' },
      { label: 'Category', value: capitalizeFirst(it.category || ''), icon: 'folder' },
      { label: 'Deadline', value: formatFullTimestamp(it.deadline), icon: 'calendar-clock' },
      { label: 'Apply URL', value: applyLink ? `<a href="${esc(applyLink)}" target="_blank" rel="noopener">${esc(applyLink)}</a>` : '', html: true, icon: 'external-link' },
      { label: 'Posted', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    ])}
    ${section('Description', paragraphs(it.description), 'align-left')}
    ${section('Eligibility', paragraphs(eligibility), 'list-checks')}
    ${section('Tags', chips(it.tags, 'rgba(180,83,9,0.1)'), 'tag')}
    <div class="details-flags">
      ${isFeatured ? '<span class="badge badge-warning"><i data-lucide="star"></i>Featured</span>' : ''}
      ${it.isHidden ? '<span class="badge badge-danger"><i data-lucide="eye-off"></i>Hidden</span>' : ''}
    </div>
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}"><i data-lucide="x"></i>Close</button>
    ${publisherId ? `<button class="btn btn-ghost" id="view-publisher-btn" data-user-id="${esc(publisherId)}"><i data-lucide="user"></i>Publisher profile</button>` : ''}
    ${editLink(canEditScholarship(it), `scholarship-editor?id=${encodeURIComponent(id)}`)}
  `);
  bindPublisherBtn();
  if (window.lucide) window.lucide.createIcons();
}

async function renderIdea(id) {
  const it = await fetchDoc('projectIdeas', id);
  if (!it) return renderError('Project idea not found.');
  const summary = it.shortDescription || it.tagline || it.summary;
  const tools = Array.isArray(it.tools) ? it.tools : String(it.tools || '').split(',').map((t) => t.trim()).filter(Boolean);
  const publisherId = String(it.submittedBy || '').trim();

  setHeader({ icon: 'lightbulb', color: typeColor('project_idea'), eyebrow: 'Project Idea', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Domain', value: capitalizeFirst(it.domain || ''), icon: 'tag' },
      { label: 'Stage', value: capitalizeFirst(it.stage || ''), icon: 'flag' },
      { label: 'Level', value: capitalizeFirst(it.level || ''), icon: 'graduation-cap' },
      { label: 'Category', value: capitalizeFirst(it.category || ''), icon: 'folder' },
      { label: 'Status', value: statusBadge(it.status || 'pending'), html: true, icon: 'circle-dot' },
      { label: 'Submitted by', value: it.submittedByName || '—', icon: 'user' },
      { label: 'Submitted', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    ])}
    ${section('Summary', paragraphs(summary), 'align-left')}
    ${section('Description', paragraphs(it.description), 'text')}
    ${it.problemStatement ? section('Problem Statement', paragraphs(it.problemStatement), 'alert-circle') : ''}
    ${it.solution ? section('Solution', paragraphs(it.solution), 'lightbulb') : ''}
    ${section('Tools & Stack', chips(tools, 'rgba(245,158,11,0.1)'), 'code-2')}
    ${section('Skills Needed', chips(it.skillsNeeded, 'rgba(59,130,246,0.1)'), 'sparkles')}
    ${section('Tags', chips(it.tags, 'rgba(245,158,11,0.08)'), 'tag')}
    <div class="details-flags">${it.isHidden ? '<span class="badge badge-danger"><i data-lucide="eye-off"></i>Hidden</span>' : ''}</div>
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}"><i data-lucide="x"></i>Close</button>
    ${publisherId ? `<button class="btn btn-ghost" id="view-publisher-btn" data-user-id="${esc(publisherId)}"><i data-lucide="user"></i>Publisher profile</button>` : ''}
    ${editLink(canEditIdea(it), `idea-editor?id=${encodeURIComponent(id)}`)}
  `);
  bindPublisherBtn();
  if (window.lucide) window.lucide.createIcons();
}

async function renderTraining(id) {
  const it = await fetchDoc('trainings', id);
  if (!it) return renderError('Training not found.');
  setHeader({ icon: 'book-open', color: typeColor('training'), eyebrow: 'Training', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Author', value: it.author || it.provider, icon: 'user' },
      { label: 'Source', value: capitalizeFirst(it.source || (it.videoId ? 'YouTube' : it.isbn ? 'Book' : '')), icon: 'tag' },
      { label: 'Level', value: capitalizeFirst(it.level || ''), icon: 'graduation-cap' },
      { label: 'Added', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
      { label: 'Link', value: it.url ? `<a href="${esc(it.url)}" target="_blank" rel="noopener">Open resource</a>` : '', html: true, icon: 'external-link' },
    ])}
    ${it.thumbnail ? `<img src="${esc(it.thumbnail)}" alt="" style="width:100%;max-height:260px;object-fit:cover;border-radius:12px;margin-bottom:14px;" />` : ''}
    ${section('Description', paragraphs(it.description), 'align-left')}
    ${section('Tags', chips(it.tags, 'rgba(20,184,166,0.1)'), 'tag')}
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}"><i data-lucide="x"></i>Close</button>
    <a class="btn btn-primary" href="moderation?tab=trainings&trainingId=${encodeURIComponent(id)}"><i data-lucide="pencil"></i>Edit in moderation</a>
  `);
  if (window.lucide) window.lucide.createIcons();
}

async function renderApplication(id) {
  const it = await fetchDoc('applications', id);
  if (!it) return renderError('Application not found.');
  let opp = null;
  if (it.opportunityId) { try { opp = await fetchDoc('opportunities', it.opportunityId); } catch {} }
  setHeader({ icon: 'file-text', color: typeColor('application'), eyebrow: 'Application', title: `${it.studentName || 'Student'} → ${opp?.title || 'Opportunity'}` });
  setBody(`
    ${kvGrid([
      { label: 'Student', value: it.studentName, icon: 'user' },
      { label: 'Email', value: it.studentEmail, icon: 'mail' },
      { label: 'Opportunity', value: opp?.title || '—', icon: 'briefcase' },
      { label: 'Company', value: opp?.companyName, icon: 'building-2' },
      { label: 'Status', value: statusBadge(it.status || 'pending'), html: true, icon: 'circle-dot' },
      { label: 'Applied', value: formatFullTimestamp(it.appliedAt), icon: 'calendar' },
    ])}
    ${section('Cover Letter', paragraphs(it.coverLetter), 'message-square')}
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}"><i data-lucide="x"></i>Close</button>
    <a class="btn btn-primary" href="moderation?tab=opportunities&filter=pending_apps&applicationId=${encodeURIComponent(id)}"><i data-lucide="file"></i>Review CV</a>
  `);
  if (window.lucide) window.lucide.createIcons();
}

async function renderUser(id) {
  const it = await fetchDoc('users', id);
  if (!it) return renderError('User not found.');
  const name = it.fullName || it.companyName || 'Unknown';
  const role = String(it.role || 'user').toLowerCase();
  const isActive = it.isActive !== false;
  const approval = String(it.approvalStatus || (role === 'company' ? 'approved' : '')).toLowerCase();

  const iconName = role === 'company' ? 'building-2' : role === 'admin' ? 'shield' : 'user';
  const headerColor = role === 'company' ? '#14B8A6' : role === 'admin' ? '#F59E0B' : 'var(--c-primary)';
  const statusValue = !isActive ? 'blocked' : (approval || 'active');

  setHeader({ icon: iconName, color: headerColor, eyebrow: capitalizeFirst(role), title: name });

  const identityRows = [
    { label: 'Email', value: it.email, icon: 'mail' },
    { label: 'Phone', value: it.phone, icon: 'phone' },
    { label: 'Location', value: it.location || it.address, icon: 'map-pin' },
    { label: 'Status', value: statusBadge(statusValue), html: true, icon: 'circle-dot' },
    { label: 'Joined', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    { label: 'Provider', value: capitalizeFirst(it.provider || 'email'), icon: 'key' },
  ].filter(Boolean);

  let roleSection = '';
  if (role === 'student') {
    const studentRows = [
      { label: 'Academic Level', value: capitalizeFirst(it.academicLevel || ''), icon: 'graduation-cap' },
      { label: 'University', value: it.university, icon: 'building-2' },
      { label: 'Field of Study', value: it.fieldOfStudy, icon: 'book-open' },
      it.researchTopic ? { label: 'Research Topic', value: it.researchTopic, icon: 'microscope' } : null,
      it.laboratory ? { label: 'Laboratory', value: it.laboratory, icon: 'flask-conical' } : null,
      it.supervisor ? { label: 'Supervisor', value: it.supervisor, icon: 'user-check' } : null,
    ].filter(Boolean);
    if (studentRows.length) roleSection = section('Academic', kvGrid(studentRows), 'graduation-cap');
  } else if (role === 'company') {
    const website = String(it.website || '').trim();
    const companyRows = [
      { label: 'Approval', value: statusBadge(approval || 'approved'), html: true, icon: 'badge-check' },
      { label: 'Sector', value: it.sector || it.industry, icon: 'tag' },
      { label: 'Company Size', value: it.companySize, icon: 'users' },
      { label: 'Registration #', value: it.registrationNumber, icon: 'hash' },
      website ? { label: 'Website', value: `<a href="${esc(/^https?:\/\//i.test(website) ? website : 'https://' + website)}" target="_blank" rel="noopener">${esc(website)}</a>`, html: true, icon: 'globe' } : null,
    ].filter(Boolean);
    if (companyRows.length) roleSection = section('Company', kvGrid(companyRows), 'building-2');
  }

  const publisherStats = role === 'company'
    ? await loadPublisherStats(id, name)
    : null;
  const bioText = String(it.bio || it.description || '').trim();

  setBody(`
    ${kvGrid(identityRows)}
    ${roleSection}
    ${publisherStats ? publisherStatsSection(publisherStats) : ''}
    ${bioText ? section(role === 'company' ? 'About' : 'Bio', paragraphs(bioText), 'align-left') : ''}
    ${role === 'company' ? commercialRegisterSection(it) : ''}
    ${section('Skills', chips(it.skills, 'rgba(99,102,241,0.1)'), 'sparkles')}
  `);

  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}"><i data-lucide="x"></i>Close</button>
  `);
  bindCommercialRegisterButtons(id);
  if (window.lucide) window.lucide.createIcons();
}

function applicationStatusCounts(applications) {
  const counts = { total: applications.length, pending: 0, accepted: 0, rejected: 0 };
  applications.forEach((application) => {
    const status = String(application.status || 'pending').trim().toLowerCase();
    if (status === 'accepted') counts.accepted += 1;
    else if (status === 'rejected') counts.rejected += 1;
    else counts.pending += 1;
  });
  return counts;
}

function applicationSummaryHtml(counts) {
  return `<div class="details-stat-row">
    <span class="badge badge-info"><i data-lucide="users"></i>${counts.total} Total</span>
    <span class="badge badge-warning"><i data-lucide="hourglass"></i>${counts.pending} Pending</span>
    <span class="badge badge-success"><i data-lucide="check"></i>${counts.accepted} Accepted</span>
    <span class="badge badge-danger"><i data-lucide="x"></i>${counts.rejected} Rejected</span>
  </div>`;
}

async function loadPublisherStats(userId, publisherName) {
  const [opportunities, scholarships] = await Promise.all([
    loadPublisherOpportunities(userId),
    loadPublisherScholarships(userId, publisherName),
  ]);
  return {
    jobs: opportunities.filter((item) => normalizedOpportunityType(item) === 'job').length,
    internships: opportunities.filter((item) => normalizedOpportunityType(item) === 'internship').length,
    sponsored: opportunities.filter((item) => normalizedOpportunityType(item) === 'sponsoring').length,
    scholarships: scholarships.length,
  };
}

async function loadPublisherOpportunities(userId) {
  try {
    const snap = await getDocs(query(collection(db, 'opportunities'), where('companyId', '==', userId)));
    return snap.docs.map((item) => ({ id: item.id, ...item.data() }));
  } catch {
    return [];
  }
}

async function loadPublisherScholarships(userId, publisherName) {
  const matches = new Map();
  try {
    const snap = await getDocs(query(collection(db, 'scholarships'), where('createdBy', '==', userId)));
    snap.docs.forEach((item) => matches.set(item.id, { id: item.id, ...item.data() }));
  } catch {}

  const providerName = String(publisherName || '').trim().toLowerCase();
  if (providerName) {
    try {
      const snap = await getDocs(collection(db, 'scholarships'));
      snap.docs.forEach((item) => {
        const data = item.data();
        const provider = String(data.provider || data.organization || '').trim().toLowerCase();
        if (provider && provider === providerName) {
          matches.set(item.id, { id: item.id, ...data });
        }
      });
    } catch {}
  }
  return Array.from(matches.values());
}

function publisherStatsSection(stats) {
  return section('Published Content', `<div class="details-content-metrics">
    ${contentMetric('Jobs', stats.jobs, 'briefcase')}
    ${contentMetric('Internships', stats.internships, 'badge-check')}
    ${contentMetric('Sponsored', stats.sponsored, 'badge-dollar-sign')}
    ${contentMetric('Scholarships', stats.scholarships, 'graduation-cap')}
  </div>`, 'bar-chart-3');
}

function contentMetric(label, value, icon) {
  return `<div class="details-content-metric">
    <div class="details-content-metric__icon"><i data-lucide="${icon}"></i></div>
    <div>
      <div class="details-content-metric__value">${Number(value || 0).toLocaleString()}</div>
      <div class="details-content-metric__label">${esc(label)}</div>
    </div>
  </div>`;
}

function normalizedOpportunityType(item) {
  return String(item?.type || item?.opportunityType || 'job').trim().toLowerCase();
}

function commercialRegisterSection(user) {
  const hasRegister = hasCommercialRegister(user);
  const uploaded = formatFullTimestamp(user?.commercialRegisterUploadedAt) ||
    formatTimestamp(user?.commercialRegisterUploadedAt) ||
    'Not provided';
  const fileName = String(user?.commercialRegisterFileName || '').trim() || 'Commercial register';
  const body = hasRegister
    ? `
      <div class="details-kv-row">
        <div class="details-kv-label"><i data-lucide="file-check-2"></i>Document</div>
        <div class="details-kv-value">
          <div style="font-weight:700;margin-bottom:4px;">${esc(fileName)}</div>
          <div style="color:var(--c-text-faint);font-size:12px;margin-bottom:12px;">Uploaded ${esc(uploaded)}</div>
          <div style="display:flex;flex-wrap:wrap;gap:8px;">
            <button class="btn btn-sm" data-commercial-register="view"><i data-lucide="eye"></i>View register</button>
            <button class="btn btn-sm" data-commercial-register="download"><i data-lucide="download"></i>Download register</button>
          </div>
        </div>
      </div>`
    : `
      <div class="details-kv-row">
        <div class="details-kv-label"><i data-lucide="file-x-2"></i>Document</div>
        <div class="details-kv-value" style="color:var(--c-danger);font-weight:700;">Commercial register missing.</div>
      </div>`;
  return section('Commercial register', `<div class="details-kv">${body}</div>`, 'file-check-2');
}

function hasCommercialRegister(user) {
  return Boolean(
    String(
      user?.commercialRegisterStoragePath ||
      user?.commercialRegisterObjectKey ||
      user?.commercialRegisterAccessPath ||
      user?.commercialRegisterUrl ||
      user?.commercialRegisterAccessUrl ||
      user?.commercialRegisterSignedUrl ||
      '',
    ).trim(),
  );
}

function bindCommercialRegisterButtons(companyId) {
  document.querySelectorAll('[data-commercial-register]').forEach((button) => {
    button.addEventListener('click', () => {
      openCommercialRegister(companyId, {
        download: button.getAttribute('data-commercial-register') === 'download',
      });
    });
  });
}

async function openCommercialRegister(companyId, { download = false } = {}) {
  try {
    const document = await getCompanyCommercialRegisterDocument(companyId);
    const url = download
      ? document?.downloadUrl || document?.url || document?.viewUrl
      : document?.viewUrl || document?.url || document?.downloadUrl;
    if (!url) throw new Error('Document unavailable');
    openDocumentUrl(url, { download, fileName: document?.fileName || '' });
  } catch (error) {
    showToast(friendlyDocumentErrorMessage(error), 'error');
  }
}

function bindPublisherBtn() {
  const btn = document.getElementById('view-publisher-btn');
  if (!btn) return;
  btn.addEventListener('click', async () => {
    const userId = btn.getAttribute('data-user-id');
    if (!userId) return;
    btn.disabled = true;
    renderLoading();
    if (window.lucide) window.lucide.createIcons();
    try {
      await renderUser(userId);
    } catch (e) {
      console.error('publisher profile load failed', e);
      renderError('Could not load publisher profile.');
    }
  });
}

function buildSalaryRange(it) {
  const min = it.salaryMin ?? it.fundingAmount;
  const max = it.salaryMax;
  const currency = it.salaryCurrency || it.fundingCurrency || '';
  const period = it.salaryPeriod ? `/${it.salaryPeriod}` : '';
  if (min != null && max != null) return `${min}–${max} ${currency}${period}`.trim();
  if (min != null) return `From ${min} ${currency}${period}`.trim();
  if (it.compensationText) return it.compensationText;
  if (it.fundingNote) return it.fundingNote;
  return '';
}
