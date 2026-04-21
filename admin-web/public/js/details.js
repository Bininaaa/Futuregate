import { db, doc, getDoc, collection, getDocs, query, where } from './firebase-config.js';
import { esc, emptyStateHtml, feedbackCardHtml, formatTimestamp } from './auth.js';
import { openModal, closeModal } from './ui.js';
import { typeColor, typeIcon, activityTypeLabel, formatFullTimestamp } from './admin-utils.js';

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
  const map = { approved: 'success', active: 'success', pending: 'warning', draft: 'warning', closed: 'danger', rejected: 'danger', reviewed: 'info', accepted: 'success' };
  return `<span class="badge badge-${map[status] || 'primary'}">${esc(status)}</span>`;
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
  // Count applications for this opportunity
  let appCount = 0;
  try {
    const snap = await getDocs(query(collection(db, 'applications'), where('opportunityId', '==', id)));
    appCount = snap.size;
  } catch {}
  setHeader({ icon: 'briefcase', color: typeColor('opportunity'), eyebrow: 'Opportunity', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Company', value: it.companyName, icon: 'building-2' },
      { label: 'Location', value: it.location, icon: 'map-pin' },
      { label: 'Type', value: it.type || it.opportunityType, icon: 'tag' },
      { label: 'Status', value: statusBadge(it.status || 'active'), html: true, icon: 'circle-dot' },
      { label: 'Applications', value: `${appCount}`, icon: 'file-text' },
      { label: 'Posted', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
      { label: 'Apply URL', value: it.applyUrl ? `<a href="${esc(it.applyUrl)}" target="_blank" rel="noopener">${esc(it.applyUrl)}</a>` : '', html: true, icon: 'external-link' },
    ])}
    ${section('Description', paragraphs(it.description), 'align-left')}
    ${section('Requirements', paragraphs(requirements), 'list-checks')}
    ${section('Skills', chips(it.skills, 'rgba(59,34,246,0.1)'), 'sparkles')}
    <div class="details-flags">
      ${it.isFeatured ? '<span class="badge badge-warning"><i data-lucide="star"></i>Featured</span>' : ''}
      ${it.isHidden ? '<span class="badge badge-danger"><i data-lucide="eye-off"></i>Hidden</span>' : ''}
    </div>
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}">Close</button>
    <a class="btn btn-primary" href="moderation.html?tab=opportunities&opportunityId=${encodeURIComponent(id)}"><i data-lucide="pencil"></i>Open in moderation</a>
  `);
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
  setHeader({ icon: 'graduation-cap', color: typeColor('scholarship'), eyebrow: 'Scholarship', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Provider', value: it.provider || it.organization, icon: 'building-2' },
      { label: 'Country', value: it.country, icon: 'map-pin' },
      { label: 'Amount', value: it.amount, icon: 'coins' },
      { label: 'Level', value: it.level || it.academicLevel, icon: 'graduation-cap' },
      { label: 'Deadline', value: formatFullTimestamp(it.deadline), icon: 'calendar-clock' },
      { label: 'Apply URL', value: applyLink ? `<a href="${esc(applyLink)}" target="_blank" rel="noopener">${esc(applyLink)}</a>` : '', html: true, icon: 'external-link' },
      { label: 'Posted', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    ])}
    ${section('Description', paragraphs(it.description), 'align-left')}
    ${section('Eligibility', paragraphs(eligibility), 'list-checks')}
    <div class="details-flags">
      ${isFeatured ? '<span class="badge badge-warning"><i data-lucide="star"></i>Featured</span>' : ''}
      ${it.isHidden ? '<span class="badge badge-danger"><i data-lucide="eye-off"></i>Hidden</span>' : ''}
    </div>
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}">Close</button>
    <a class="btn btn-primary" href="moderation.html?tab=scholarships&scholarshipId=${encodeURIComponent(id)}"><i data-lucide="pencil"></i>Open in moderation</a>
  `);
  if (window.lucide) window.lucide.createIcons();
}

async function renderIdea(id) {
  const it = await fetchDoc('projectIdeas', id);
  if (!it) return renderError('Project idea not found.');
  const summary = it.shortDescription || it.tagline || it.summary;
  setHeader({ icon: 'lightbulb', color: typeColor('project_idea'), eyebrow: 'Project idea', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Domain', value: it.domain, icon: 'tag' },
      { label: 'Status', value: statusBadge(it.status || 'pending'), html: true, icon: 'circle-dot' },
      { label: 'Submitted by', value: it.submittedByName || '—', icon: 'user' },
      { label: 'Submitted', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    ])}
    ${section('Summary', paragraphs(summary), 'align-left')}
    ${section('Description', paragraphs(it.description), 'text')}
    ${section('Skills', chips(it.skills, 'rgba(37,99,235,0.1)'), 'sparkles')}
    <div class="details-flags">${it.isHidden ? '<span class="badge badge-danger"><i data-lucide="eye-off"></i>Hidden</span>' : ''}</div>
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}">Close</button>
    <a class="btn btn-primary" href="moderation.html?tab=ideas&ideaId=${encodeURIComponent(id)}"><i data-lucide="pencil"></i>Open in moderation</a>
  `);
  if (window.lucide) window.lucide.createIcons();
}

async function renderTraining(id) {
  const it = await fetchDoc('trainings', id);
  if (!it) return renderError('Training not found.');
  setHeader({ icon: 'book-open', color: typeColor('training'), eyebrow: 'Training', title: it.title || 'Untitled' });
  setBody(`
    ${kvGrid([
      { label: 'Author', value: it.author || it.provider, icon: 'user' },
      { label: 'Source', value: it.source || (it.videoId ? 'YouTube' : it.isbn ? 'Book' : '—'), icon: 'tag' },
      { label: 'Level', value: it.level, icon: 'graduation-cap' },
      { label: 'Link', value: it.url ? `<a href="${esc(it.url)}" target="_blank" rel="noopener">Open resource</a>` : '', html: true, icon: 'external-link' },
      { label: 'Added', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    ])}
    ${it.thumbnail ? `<img src="${esc(it.thumbnail)}" alt="" style="width:100%;max-height:260px;object-fit:cover;border-radius:12px;margin-bottom:14px;" />` : ''}
    ${section('Description', paragraphs(it.description), 'align-left')}
    ${section('Tags', chips(it.tags, 'rgba(20,184,166,0.1)'), 'sparkles')}
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}">Close</button>
    <a class="btn btn-primary" href="moderation.html?tab=trainings&trainingId=${encodeURIComponent(id)}"><i data-lucide="pencil"></i>Open in moderation</a>
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
    ${section('Cover letter', paragraphs(it.coverLetter), 'message-square')}
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}">Close</button>
    <a class="btn btn-primary" href="moderation.html?tab=opportunities&filter=pending_apps&applicationId=${encodeURIComponent(id)}"><i data-lucide="file"></i>Open CV & review</a>
  `);
  if (window.lucide) window.lucide.createIcons();
}

async function renderUser(id) {
  const it = await fetchDoc('users', id);
  if (!it) return renderError('User not found.');
  const name = it.fullName || it.companyName || 'Unknown';
  setHeader({ icon: 'user', color: 'var(--c-primary)', eyebrow: it.role || 'User', title: name });
  setBody(`
    ${kvGrid([
      { label: 'Email', value: it.email, icon: 'mail' },
      { label: 'Phone', value: it.phone, icon: 'phone' },
      { label: 'Role', value: it.role, icon: 'badge' },
      { label: 'Level', value: it.academicLevel, icon: 'graduation-cap' },
      { label: 'University', value: it.university, icon: 'building-2' },
      { label: 'Field', value: it.fieldOfStudy, icon: 'book-open' },
      { label: 'Company', value: it.companyName, icon: 'building-2' },
      { label: 'Status', value: statusBadge(it.isActive === false ? 'blocked' : (it.approvalStatus || 'active')), html: true, icon: 'circle-dot' },
      { label: 'Joined', value: formatFullTimestamp(it.createdAt), icon: 'calendar' },
    ])}
    ${section('Bio', paragraphs(it.bio), 'align-left')}
    ${section('Skills', chips(it.skills, 'rgba(59,34,246,0.1)'), 'sparkles')}
  `);
  setFooter(`
    <button class="btn" data-close-modal="${MODAL_ID}">Close</button>
    <a class="btn btn-primary" href="users.html?userId=${encodeURIComponent(id)}"><i data-lucide="external-link"></i>Open profile</a>
  `);
  if (window.lucide) window.lucide.createIcons();
}
