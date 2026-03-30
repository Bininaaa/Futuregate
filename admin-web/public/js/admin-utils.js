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

function typeIcon(type) {
  const icons = {
    application: 'AP',
    opportunity: 'OP',
    scholarship: 'SC',
    training: 'TR',
    project_idea: 'PI',
  };

  return icons[type] || 'AC';
}

function typeColor(type) {
  const colors = {
    application: '#7B1FA2',
    opportunity: '#FF8C00',
    scholarship: '#E91E63',
    training: '#00BCD4',
    project_idea: '#FFC107',
  };

  return colors[type] || '#777777';
}

function adminTargetUrl(type, targetId = '') {
  const safeTargetId = encodeURIComponent(String(targetId || '').trim());

  switch (type) {
    case 'application':
      return safeTargetId
        ? `moderation.html?tab=applications&applicationId=${safeTargetId}`
        : 'moderation.html?tab=applications';
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
