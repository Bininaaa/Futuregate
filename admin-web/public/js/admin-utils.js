function timestampToDate(value) {
  if (!value) {
    return null;
  }

  if (typeof value.toDate === 'function') {
    return value.toDate();
  }

  if (value instanceof Date) {
    return value;
  }

  if (typeof value.seconds === 'number') {
    return new Date(value.seconds * 1000);
  }

  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : new Date(parsed);
}

function timestampToMs(value) {
  return timestampToDate(value)?.getTime() || 0;
}

function formatFullTimestamp(value) {
  const date = timestampToDate(value);
  if (!date) {
    return '';
  }

  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(date);
}

function normalizeText(value) {
  return String(value || '').trim().toLowerCase();
}

function matchesSearch(fields, queryText) {
  const normalizedQuery = normalizeText(queryText);
  if (!normalizedQuery) {
    return true;
  }

  return fields.some((field) => normalizeText(field).includes(normalizedQuery));
}

function getQueryParam(name) {
  return new URLSearchParams(window.location.search).get(name) || '';
}

function updateUrlParams(nextParams = {}) {
  const url = new URL(window.location.href);

  Object.entries(nextParams).forEach(([key, value]) => {
    const safeValue = String(value || '').trim();
    if (safeValue) {
      url.searchParams.set(key, safeValue);
    } else {
      url.searchParams.delete(key);
    }
  });

  window.history.replaceState({}, '', url);
}

function truncateText(value, maxLength = 160) {
  const safeValue = String(value || '').trim();
  if (safeValue.length <= maxLength) {
    return safeValue;
  }

  return `${safeValue.slice(0, Math.max(0, maxLength - 1))}...`;
}

function activityTypeLabel(type) {
  const labels = {
    application: 'Application',
    opportunity: 'Opportunity',
    scholarship: 'Scholarship',
    training: 'Training',
    project_idea: 'Project Idea',
  };

  return labels[type] || 'Activity';
}

function typeIcon(type, subType) {
  const subs = {
    job: 'briefcase',
    internship: 'briefcase-business',
    sponsoring: 'badge-dollar-sign',
    contract: 'file-signature',
    volunteer: 'heart-handshake',
    freelance: 'laptop',
  };
  if (subType && subs[String(subType).toLowerCase()]) return subs[String(subType).toLowerCase()];
  if (subs[String(type).toLowerCase()]) return subs[String(type).toLowerCase()];
  const icons = {
    application: 'file-text',
    opportunity: 'briefcase',
    scholarship: 'award',
    training: 'book-open',
    project_idea: 'lightbulb',
    idea: 'lightbulb',
  };

  return icons[type] || 'activity';
}

function typeColor(type) {
  const colors = {
    application: '#7C3AED',
    opportunity: '#F59E0B',
    scholarship: '#E24A4A',
    training: '#14B8A6',
    project_idea: '#2563EB',
  };

  return colors[type] || '#64748B';
}

function adminTargetUrl(type, targetId = '') {
  const safeTargetId = encodeURIComponent(String(targetId || '').trim());

  switch (type) {
    case 'application':
      return safeTargetId
        ? `moderation.html?tab=opportunities&filter=pending_apps&applicationId=${safeTargetId}`
        : 'moderation.html?tab=opportunities&filter=pending_apps';
    case 'opportunity':
      return safeTargetId
        ? `moderation.html?tab=opportunities&opportunityId=${safeTargetId}`
        : 'moderation.html?tab=opportunities';
    case 'scholarship':
      return safeTargetId
        ? `moderation.html?tab=scholarships&scholarshipId=${safeTargetId}`
        : 'moderation.html?tab=scholarships';
    case 'training':
      return safeTargetId
        ? `moderation.html?tab=trainings&trainingId=${safeTargetId}`
        : 'moderation.html?tab=trainings';
    case 'project_idea':
      return safeTargetId
        ? `moderation.html?tab=ideas&ideaId=${safeTargetId}`
        : 'moderation.html?tab=ideas';
    default:
      return 'moderation.html';
  }
}

function targetParamName(type) {
  const mapping = {
    application: 'applicationId',
    opportunity: 'opportunityId',
    scholarship: 'scholarshipId',
    training: 'trainingId',
    project_idea: 'ideaId',
  };

  return mapping[type] || '';
}

export {
  activityTypeLabel,
  adminTargetUrl,
  formatFullTimestamp,
  getQueryParam,
  matchesSearch,
  normalizeText,
  targetParamName,
  timestampToDate,
  timestampToMs,
  truncateText,
  typeColor,
  typeIcon,
  updateUrlParams,
};
