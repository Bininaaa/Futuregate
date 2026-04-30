import {
  auth,
  db,
  collection,
  getDocs,
  query,
  where,
} from './firebase-config.js';
import { WORKER_BASE_URL } from './google-books-config.js';
import { t } from './i18n.js';

function trim(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function isPlainObject(value) {
  return Boolean(value && typeof value === 'object' && !Array.isArray(value));
}

function firstText(...values) {
  for (const value of values) {
    const text = trim(value);
    if (text) {
      return text;
    }
  }

  return '';
}

function firstFieldText(sources, fields) {
  for (const source of sources) {
    if (!isPlainObject(source)) {
      continue;
    }

    for (const field of fields) {
      const text = trim(source[field]);
      if (text) {
        return text;
      }
    }
  }

  return '';
}

function normalizeOpenableDocumentUrl(value) {
  const rawValue = trim(value);
  if (!rawValue) {
    return '';
  }

  if (rawValue.startsWith('//')) {
    return `https:${rawValue}`;
  }

  if (/^(https?:|blob:|data:)/i.test(rawValue)) {
    return rawValue;
  }

  if (/^[a-z0-9.-]+\.[a-z]{2,}(?::\d+)?(?:\/|$)/i.test(rawValue)) {
    return `https://${rawValue}`;
  }

  return '';
}

const VIEW_URL_FIELDS = [
  'viewUrl',
  'viewURL',
  'view_url',
  'previewUrl',
  'previewURL',
  'preview_url',
  'accessUrl',
  'accessURL',
  'access_url',
  'signedUrl',
  'signedURL',
  'signed_url',
  'publicUrl',
  'publicURL',
  'public_url',
  'fileUrl',
  'fileURL',
  'file_url',
  'url',
  'href',
  'link',
];

const DOWNLOAD_URL_FIELDS = [
  'downloadUrl',
  'downloadURL',
  'download_url',
  'signedDownloadUrl',
  'signedDownloadURL',
  'signed_download_url',
  'downloadSignedUrl',
  'downloadSignedURL',
  'download_signed_url',
  'downloadAccessUrl',
  'downloadAccessURL',
  'download_access_url',
  ...VIEW_URL_FIELDS,
];

const STORAGE_PATH_FIELDS = [
  'storagePath',
  'objectKey',
  'path',
  'accessPath',
  'uploadedCvPath',
  'uploadedCvObjectKey',
  'uploadedCvStoragePath',
  'uploadedCvAccessPath',
  'uploadedCvUrl',
  'uploadedCvAccessUrl',
  'uploadedCvSignedUrl',
  'exportedPdfPath',
  'exportedPdfObjectKey',
  'exportedPdfStoragePath',
  'exportedPdfAccessPath',
  'exportedPdfUrl',
  'exportedPdfAccessUrl',
  'exportedPdfSignedUrl',
  'commercialRegisterStoragePath',
  'commercialRegisterObjectKey',
  'commercialRegisterAccessPath',
  'commercialRegisterUrl',
  'commercialRegisterAccessUrl',
  'commercialRegisterSignedUrl',
];

const FILE_NAME_FIELDS = [
  'fileName',
  'filename',
  'name',
  'uploadedFileName',
  'exportedPdfFileName',
  'commercialRegisterFileName',
];

const MIME_TYPE_FIELDS = [
  'mimeType',
  'contentType',
  'type',
  'uploadedCvMimeType',
  'exportedPdfMimeType',
  'commercialRegisterMimeType',
];

function normalizeDocumentRecord(record, extraSources = []) {
  if (!isPlainObject(record)) {
    return null;
  }

  const sources = [record, ...extraSources].filter(isPlainObject);
  const viewUrl = firstFieldText(sources, VIEW_URL_FIELDS);
  const downloadUrl = firstFieldText(sources, DOWNLOAD_URL_FIELDS);
  const fileName = firstFieldText(sources, FILE_NAME_FIELDS);
  const mimeType = firstFieldText(sources, MIME_TYPE_FIELDS);
  const storagePath = firstFieldText(sources, STORAGE_PATH_FIELDS);

  return {
    ...record,
    storagePath: firstText(record.storagePath, storagePath),
    fileName: firstText(record.fileName, fileName),
    mimeType: firstText(record.mimeType, mimeType),
    viewUrl: firstText(record.viewUrl, viewUrl),
    downloadUrl: firstText(record.downloadUrl, downloadUrl),
    url: firstText(record.url, viewUrl, downloadUrl),
  };
}

function documentFromPayload(payload, preferredKeys = []) {
  if (!isPlainObject(payload)) {
    return null;
  }

  const nestedData = isPlainObject(payload.data) ? payload.data : null;
  const candidates = [
    payload.document,
    ...preferredKeys.map((key) => payload[key]),
    payload.file,
    payload.attachment,
    nestedData?.document,
    nestedData?.file,
    nestedData,
    payload,
  ];
  const record = candidates.find(isPlainObject);
  if (!record) {
    return null;
  }

  return normalizeDocumentRecord(record, [payload, nestedData].filter(Boolean));
}

function resolveDocumentUrl(document, { download = false } = {}) {
  const normalizedDocument = normalizeDocumentRecord(document);
  if (!normalizedDocument) {
    return '';
  }

  const candidates = download
    ? [
        normalizedDocument.downloadUrl,
        normalizedDocument.url,
        normalizedDocument.viewUrl,
      ]
    : [
        normalizedDocument.viewUrl,
        normalizedDocument.url,
        normalizedDocument.downloadUrl,
      ];

  for (const candidate of candidates) {
    const safeUrl = normalizeOpenableDocumentUrl(candidate);
    if (safeUrl) {
      return safeUrl;
    }
  }

  return '';
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
  const storagePath = firstText(
    cv?.uploadedCvPath,
    cv?.uploadedCvObjectKey,
    cv?.uploadedCvStoragePath,
    cv?.uploadedCvAccessPath,
    cv?.uploadedCvUrl,
    cv?.uploadedCvAccessUrl,
    cv?.uploadedCvSignedUrl,
  );
  const fileName = firstText(cv?.uploadedFileName, cv?.fileName) || 'primary_cv.pdf';
  const mimeType = firstText(cv?.uploadedCvMimeType, cv?.mimeType);

  return {
    storagePath,
    fileName,
    mimeType,
    uploadedAt: cv?.uploadedCvCreatedAt || null,
    isAvailable: Boolean(storagePath),
    isPdf: isPdfDocument(fileName, mimeType),
  };
}

function resolveBuiltDocumentFields(cv) {
  const templateId = trim(cv?.templateId) || 'builder';
  const fileName = firstText(cv?.exportedPdfFileName, cv?.fileName) || `cv_${templateId}.pdf`;
  const storagePath = firstText(
    cv?.exportedPdfPath,
    cv?.exportedPdfObjectKey,
    cv?.exportedPdfStoragePath,
    cv?.exportedPdfAccessPath,
    cv?.exportedPdfUrl,
    cv?.exportedPdfAccessUrl,
    cv?.exportedPdfSignedUrl,
  );
  const mimeType = firstText(cv?.exportedPdfMimeType, cv?.mimeType) || 'application/pdf';

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

  return documentFromPayload(payload, ['cvDocument', 'cv']);
}

async function getUserCvDocument(userId, { variant = 'primary' } = {}) {
  const payload = await workerGet(
    `/api/users/${encodeURIComponent(userId)}/cv/access?variant=${encodeURIComponent(variant)}`,
  );

  return documentFromPayload(payload, ['cvDocument', 'cv']);
}

async function getCompanyCommercialRegisterDocument(companyId) {
  const payload = await workerGet(
    `/api/companies/${encodeURIComponent(companyId)}/commercial-register/access`,
  );

  return documentFromPayload(payload, ['commercialRegister', 'register']);
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
  fallback,
) {
  const fallbackText = fallback || t('doc.cantOpen', 'We couldn\'t open the document right now.');
  const message = String(error?.message || error || '').toLowerCase();
  const status = Number(error?.status);

  if (status === 401 || message.includes('401') || message.includes('auth')) {
    return t('doc.sessionExpired', 'Your admin session expired. Please sign in again.');
  }

  if (status === 403 || message.includes('403') || message.includes('permission')) {
    return t('doc.permissionDenied', 'Permission denied while opening the document.');
  }

  if (status === 404 || message.includes('404') || message.includes('not found')) {
    return t('doc.notFound', 'The requested document is no longer available.');
  }

  if (message.includes('invalid') || message.includes('unavailable')) {
    return t('doc.invalid', 'This document link is invalid or unavailable.');
  }

  if (message.includes('secure document access is not configured')) {
    return t('doc.notConfigured', 'Secure document access is not configured for this environment.');
  }

  return fallbackText;
}

function openDocumentUrl(url, { download = false, fileName = '' } = {}) {
  const safeUrl = normalizeOpenableDocumentUrl(url);
  if (!safeUrl) {
    throw new Error(t('doc.unavailable', 'Document unavailable.'));
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

function openResolvedDocument(document, { download = false } = {}) {
  const normalizedDocument = normalizeDocumentRecord(document);
  const safeUrl = resolveDocumentUrl(normalizedDocument, { download });
  if (!safeUrl) {
    throw new Error(t('doc.unavailable', 'Document unavailable.'));
  }

  openDocumentUrl(safeUrl, {
    download,
    fileName: normalizedDocument?.fileName || '',
  });
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
  openResolvedDocument,
  parseTimestampMs,
  resolveBuiltDocumentFields,
  resolveDocumentUrl,
  resolvePrimaryDocumentFields,
  selectBestCvCandidate,
  trim,
};
