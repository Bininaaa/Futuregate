// Lightweight Firestore REST API + FCM client for Cloudflare Workers.

import { getAccessToken } from './google-auth.js';

// ── Value conversion ────────────────────────────────────────────────

function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if (typeof v === 'object') {
    const fields = {};
    for (const [k, val] of Object.entries(v)) fields[k] = toValue(val);
    return { mapValue: { fields } };
  }
  return { stringValue: String(v) };
}

function fromValue(fv) {
  if (!fv) return null;
  if ('stringValue' in fv) return fv.stringValue;
  if ('integerValue' in fv) return parseInt(fv.integerValue, 10);
  if ('doubleValue' in fv) return fv.doubleValue;
  if ('booleanValue' in fv) return fv.booleanValue;
  if ('nullValue' in fv) return null;
  if ('timestampValue' in fv) return fv.timestampValue;
  if ('arrayValue' in fv) return (fv.arrayValue.values || []).map(fromValue);
  if ('mapValue' in fv) return fromFields(fv.mapValue.fields || {});
  if ('referenceValue' in fv) return fv.referenceValue;
  if ('geoPointValue' in fv) return fv.geoPointValue;
  return null;
}

function fromFields(fields) {
  const out = {};
  for (const [k, v] of Object.entries(fields)) out[k] = fromValue(v);
  return out;
}

function toFields(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (v !== undefined) fields[k] = toValue(v);
  }
  return fields;
}

// ── Helpers ─────────────────────────────────────────────────────────

function baseUrl(projectId) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
}

function baseName(projectId) {
  return `projects/${projectId}/databases/(default)/documents`;
}

// ── CRUD ────────────────────────────────────────────────────────────

async function firestoreGet(env, collection, docId) {
  const token = await getAccessToken(env);
  const res = await fetch(`${baseUrl(env.FIREBASE_PROJECT_ID)}/${collection}/${docId}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Firestore GET: ${res.status} ${await res.text()}`);
  const doc = await res.json();
  return { exists: true, id: doc.name.split('/').pop(), data: fromFields(doc.fields || {}) };
}

async function firestoreSet(env, collection, docId, data, merge = false) {
  const token = await getAccessToken(env);
  let url = `${baseUrl(env.FIREBASE_PROJECT_ID)}/${collection}/${docId}`;

  if (merge) {
    const mask = Object.keys(data)
      .filter((k) => data[k] !== undefined)
      .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
      .join('&');
    url += `?${mask}`;
  }

  const res = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields(data) }),
  });
  if (!res.ok) throw new Error(`Firestore SET: ${res.status} ${await res.text()}`);
  return res.json();
}

async function firestoreUpdate(env, collection, docId, data) {
  return firestoreSet(env, collection, docId, data, true);
}

async function firestoreDelete(env, collection, docId) {
  const token = await getAccessToken(env);
  const res = await fetch(`${baseUrl(env.FIREBASE_PROJECT_ID)}/${collection}/${docId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok && res.status !== 404) {
    throw new Error(`Firestore DELETE: ${res.status} ${await res.text()}`);
  }
}

// ── Query ───────────────────────────────────────────────────────────

async function firestoreQuery(env, collectionId, filters, options = {}) {
  const token = await getAccessToken(env);
  const url = `${baseUrl(env.FIREBASE_PROJECT_ID)}:runQuery`;

  const structuredQuery = {
    from: [{ collectionId, allDescendants: options.allDescendants || false }],
  };

  if (filters && filters.length > 0) {
    const fieldFilters = filters.map((f) => ({
      fieldFilter: {
        field: { fieldPath: f.field },
        op: f.op || 'EQUAL',
        value: toValue(f.value),
      },
    }));
    structuredQuery.where =
      fieldFilters.length === 1
        ? fieldFilters[0]
        : { compositeFilter: { op: 'AND', filters: fieldFilters } };
  }

  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery }),
  });
  if (!res.ok) throw new Error(`Firestore query: ${res.status} ${await res.text()}`);

  const rows = await res.json();
  return rows
    .filter((r) => r.document)
    .map((r) => ({
      id: r.document.name.split('/').pop(),
      ref: r.document.name,
      data: fromFields(r.document.fields || {}),
    }));
}

// ── Batch write ─────────────────────────────────────────────────────

async function firestoreBatchWrite(env, writes) {
  if (writes.length === 0) return [];

  const token = await getAccessToken(env);
  const url = `https://firestore.googleapis.com/v1/${baseName(env.FIREBASE_PROJECT_ID)}:batchWrite`;
  const prefix = baseName(env.FIREBASE_PROJECT_ID);

  const converted = writes
    .map((w) => {
      if (w.delete) {
        const full = w.delete.startsWith('projects/') ? w.delete : `${prefix}/${w.delete}`;
        return { delete: full };
      }
      if (w.update) {
        const full = w.update.path.startsWith('projects/')
          ? w.update.path
          : `${prefix}/${w.update.path}`;
        const write = { update: { name: full, fields: toFields(w.update.data) } };
        const mask = Array.isArray(w.update.mask)
          ? [...new Set(w.update.mask.map((item) => String(item || '').trim()).filter(Boolean))]
          : [];
        if (mask.length > 0) {
          write.updateMask = { fieldPaths: mask };
        }
        if (w.update.currentDocument && typeof w.update.currentDocument === 'object') {
          write.currentDocument = w.update.currentDocument;
        }
        return write;
      }
      return null;
    })
    .filter(Boolean);

  const results = [];

  for (let i = 0; i < converted.length; i += 500) {
    const batch = converted.slice(i, i + 500);
    const res = await fetch(url, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ writes: batch }),
    });
    if (!res.ok) throw new Error(`Firestore batchWrite: ${res.status} ${await res.text()}`);

    const payload = await res.json();
    const statuses = Array.isArray(payload?.status) ? payload.status : [];
    const writeResults = Array.isArray(payload?.writeResults) ? payload.writeResults : [];

    for (let j = 0; j < batch.length; j += 1) {
      const status = statuses[j] && typeof statuses[j] === 'object' ? statuses[j] : {};
      const code = Number(status.code || 0);

      results.push({
        ok: code === 0,
        code,
        message: typeof status.message === 'string' ? status.message : '',
        writeResult: writeResults[j] && typeof writeResults[j] === 'object' ? writeResults[j] : {},
      });
    }
  }

  return results;
}

// ── FCM ─────────────────────────────────────────────────────────────

async function sendFcmMessage(env, message) {
  const token = await getAccessToken(env);
  const url = `https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message }),
  });

  if (!res.ok) {
    const body = await res.text();
    return {
      success: false,
      invalidToken: res.status === 404 || /NOT_FOUND|UNREGISTERED/.test(body),
    };
  }

  return { success: true };
}

export {
  firestoreGet,
  firestoreSet,
  firestoreUpdate,
  firestoreDelete,
  firestoreQuery,
  firestoreBatchWrite,
  sendFcmMessage,
};
