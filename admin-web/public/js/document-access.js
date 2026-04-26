import {
  auth,
  db,
  collection,
  getDocs,
  query,
  where,
} from './firebase-config.js';
import { WORKER_BASE_URL } from './google-books-config.js';

function trim(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function parseTimestampMs(value) {
  if (!value) {
    return 0;
  }

  if (typeof value.toDate === 'function') {
    const date = value.toDate();
    return Number.isFinite(date?.getTime()) ? date.getTime() : 0;
  }

  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  if (typeof value === 'object' && Number.isFinite(value.seconds)) {
    return value.seconds * 1000;
  }

  return 0;
}

function isPdfDocument(fileName, mimeType) {
  const normalizedMimeType = trim(mimeType).toLowerCase();
  if (normalizedMimeType === 'application/pdf') {
    return true;
  }

  return trim(fileName).toLowerCase().endsWith('.pdf');
}

function hasBuilderContent(cv) {
  const education = Array.isArray(cv?.education) ? cv.education : [];
  const experience = Array.isArray(cv?.experience) ? cv.experience : [];
  const skills = Array.isArray(cv?.skills) ? cv.skills : [];
  const languages = Array.isArray(cv?.languages) ? cv.languages : [];

  return Boolean(
    trim(cv?.fullName) ||
      trim(cv?.summary) ||
      education.length ||
      experience.length ||
      skills.length ||
      languages.length,
  );
}

function resolvePrimaryDocumentFields(cv) {
  const storagePath =
    trim(cv?.uploadedCvPath) ||
    trim(cv?.uploadedCvObjectKey) ||
    trim(cv?.uploadedCvStoragePath) ||
    trim(cv?.uploadedCvAccessPath) ||
    trim(cv?.uploadedCvSignedUrl) ||
    trim(cv?.uploadedCvAccessUrl) ||
    trim(cv?.uploadedCvUrl);
  const fileName = trim(cv?.uploadedFileName) || 'primary_cv.pdf';
  const mimeType = trim(cv?.uploadedCvMimeType);

  return {
    storagePath,
    fileName,
    mimeType,
    uploadedAt: cv?.uploadedCvUploadedAt || cv?.uploadedCvCreatedAt || null,
    isAvailable: Boolean(storagePath),
    isPdf: isPdfDocument(fileName, mimeType),
  };
}

function resolveBuiltDocumentFields(cv) {
  const templateId = trim(cv?.templateId) || 'builder';
  const fileName = trim(cv?.exportedPdfFileName) || `cv_${templateId}.pdf`;
  const storagePath =
    trim(cv?.exportedPdfPath) ||
    trim(cv?.exportedPdfObjectKey) ||
    trim(cv?.exportedPdfStoragePath) ||
    trim(cv?.exportedPdfAccessPath) ||
    trim(cv?.exportedPdfSignedUrl) ||
    trim(cv?.exportedPdfAccessUrl) ||
    trim(cv?.exportedPdfUrl);
  const mimeType = trim(cv?.exportedPdfMimeType) || 'application/pdf';

  return {
    storagePath,
    fileName,
    mimeType,
    isAvailable: Boolean(storagePath),
    isPdf: isPdfDocument(fileName, mimeType),
  };
}

function resolveDocumentFields(cv, variant) {
  return variant === 'built'
    ? resolveBuiltDocumentFields(cv)
    : resolvePrimaryDocumentFields(cv);
}

function selectBestCvCandidate(candidates, variant = 'primary') {
  if (!Array.isArray(candidates) || candidates.length === 0) {
    return null;
  }

  return [...candidates].sort((left, right) => {
    const leftFields = resolveDocumentFields(left, variant);
    const rightFields = resolveDocumentFields(right, variant);
    const leftHasDocument = leftFields.isAvailable ? 1 : 0;
    const rightHasDocument = rightFields.isAvailable ? 1 : 0;

    if (leftHasDocument !== rightHasDocument) {
      return rightHasDocument - leftHasDocument;
    }

    const leftUpdatedAt = parseTimestampMs(left?.updatedAt);
    const rightUpdatedAt = parseTimestampMs(right?.updatedAt);
    if (leftUpdatedAt !== rightUpdatedAt) {
      return rightUpdatedAt - leftUpdatedAt;
    }

    const leftCreatedAt = parseTimestampMs(left?.createdAt);
    const rightCreatedAt = parseTimestampMs(right?.createdAt);
    if (leftCreatedAt !== rightCreatedAt) {
      return rightCreatedAt - leftCreatedAt;
    }

    return 0;
  })[0] || null;
}

function buildCvSummary(candidates) {
  const safeCandidates = Array.isArray(candidates) ? candidates : [];
  const primaryCandidate = selectBestCvCandidate(safeCandidates, 'primary');
  const builtCandidate = selectBestCvCandidate(safeCandidates, 'built');
  const fallbackCandidate =
    primaryCandidate ||
    builtCandidate ||
    [...safeCandidates].sort(
      (left, right) =>
        parseTimestampMs(right?.updatedAt || right?.createdAt) -
        parseTimestampMs(left?.updatedAt || left?.createdAt),
    )[0] ||
    null;
  const builderCandidate = builtCandidate || fallbackCandidate;

  return {
    hasCvRecord: safeCandidates.length > 0,
    primaryCandidate,
    builtCandidate,
    primary: resolvePrimaryDocumentFields(primaryCandidate),
    built: {
      ...resolveBuiltDocumentFields(builtCandidate),
      hasBuilderContent: hasBuilderContent(builderCandidate),
      summary: trim(builderCandidate?.summary),
      fullName: trim(builderCandidate?.fullName),
      email: trim(builderCandidate?.email),
      phone: trim(builderCandidate?.phone),
      address: trim(builderCandidate?.address),
      skills: Array.isArray(builderCandidate?.skills)
        ? builderCandidate.skills.filter((item) => trim(item))
        : [],
      languages: Array.isArray(builderCandidate?.languages)
        ? builderCandidate.languages.filter((item) => trim(item))
        : [],
    },
  };
}

async function getAuthToken() {
  const user = auth.currentUser;
  if (!user) {
    throw new Error('Not authenticated.');
  }

  return user.getIdToken();
}

async function workerGet(path) {
  const token = await getAuthToken();
  const response = await fetch(`${WORKER_BASE_URL}${path}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    const requestError = new Error(
      payload.error || `Request failed: ${response.status}`,
    );
    requestError.status = response.status;
    throw requestError;
  }

  return payload;
}

async function getApplicationCv(applicationId) {
  const payload = await workerGet(
    `/api/applications/${encodeURIComponent(applicationId)}/cv`,
  );

  return payload.cv && typeof payload.cv === 'object' ? payload.cv : null;
}

async function getApplicationCvDocument(applicationId, { variant = 'primary' } = {}) {
  const payload = await workerGet(
    `/api/applications/${encodeURIComponent(applicationId)}/cv/access?variant=${encodeURIComponent(variant)}`,
  );

  return payload.document && typeof payload.document === 'object'
    ? payload.document
    : null;
}

async function getUserCvDocument(userId, { variant = 'primary' } = {}) {
  const payload = await workerGet(
    `/api/users/${encodeURIComponent(userId)}/cv/access?variant=${encodeURIComponent(variant)}`,
  );

  return payload.document && typeof payload.document === 'object'
    ? payload.document
    : null;
}

async function getCompanyCommercialRegisterDocument(companyId) {
  const payload = await workerGet(
    `/api/companies/${encodeURIComponent(companyId)}/commercial-register/access`,
  );

  return payload.document && typeof payload.document === 'object'
    ? payload.document
    : null;
}

async function loadStudentCvSummary(userId) {
  const trimmedUserId = trim(userId);
  if (!trimmedUserId) {
    return buildCvSummary([]);
  }

  const snapshot = await getDocs(
    query(collection(db, 'cvs'), where('studentId', '==', trimmedUserId)),
  );
  const candidates = [];
  snapshot.forEach((item) => {
    candidates.push({
      id: item.id,
      ...item.data(),
    });
  });

  return buildCvSummary(candidates);
}

function friendlyDocumentErrorMessage(
  error,
  fallback = 'We couldn\'t open the document right now.',
) {
  const message = String(error?.message || error || '').toLowerCase();
  const status = Number(error?.status);

  if (status === 401 || message.includes('401') || message.includes('auth')) {
    return 'Your admin session expired. Please sign in again.';
  }

  if (status === 403 || message.includes('403') || message.includes('permission')) {
    return 'Permission denied while opening the document.';
  }

  if (status === 404 || message.includes('404') || message.includes('not found')) {
    return 'The requested document is no longer available.';
  }

  if (message.includes('invalid') || message.includes('unavailable')) {
    return 'This document link is invalid or unavailable.';
  }

  return fallback;
}

function openDocumentUrl(url, { download = false, fileName = '' } = {}) {
  const safeUrl = trim(url);
  if (!safeUrl) {
    throw new Error('File unavailable.');
  }

  const link = document.createElement('a');
  link.href = safeUrl;
  if (download) {
    if (trim(fileName)) {
      link.setAttribute('download', trim(fileName));
    }
  } else {
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
  }

  document.body.appendChild(link);
  link.click();
  link.remove();
}

export {
  buildCvSummary,
  friendlyDocumentErrorMessage,
  getApplicationCv,
  getApplicationCvDocument,
  getCompanyCommercialRegisterDocument,
  getUserCvDocument,
  hasBuilderContent,
  isPdfDocument,
  loadStudentCvSummary,
  openDocumentUrl,
  parseTimestampMs,
  resolveBuiltDocumentFields,
  resolvePrimaryDocumentFields,
  selectBestCvCandidate,
  trim,
};
