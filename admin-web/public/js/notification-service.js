import {
  db,
  collection,
  doc,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  updateDoc,
  where,
  writeBatch,
} from './firebase-config.js';

function normalizeNotification(snapshot) {
  const data = snapshot.data() || {};
  const body = String(data.body || data.message || '').trim();

  return {
    id: snapshot.id,
    userId: String(data.userId || '').trim(),
    title: String(data.title || 'Notification').trim(),
    message: String(data.message || body).trim(),
    body,
    type: String(data.type || '').trim(),
    createdAt: data.createdAt || null,
    isRead: data.isRead === true,
    conversationId: String(data.conversationId || '').trim(),
    targetId: String(data.targetId || '').trim(),
    route: String(data.route || '').trim(),
    eventKey: String(data.eventKey || '').trim(),
  };
}

async function loadNotificationsPage({
  userId,
  pageSize = 20,
  cursor = null,
} = {}) {
  if (!userId) {
    return {
      items: [],
      cursor: null,
      hasMore: false,
    };
  }

  const constraints = [
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    limit(pageSize),
  ];

  if (cursor) {
    constraints.push(startAfter(cursor));
  }

  const snapshot = await getDocs(query(collection(db, 'notifications'), ...constraints));

  return {
    items: snapshot.docs.map(normalizeNotification),
    cursor: snapshot.docs.length > 0 ? snapshot.docs[snapshot.docs.length - 1] : cursor,
    hasMore: snapshot.docs.length === pageSize,
  };
}

async function markNotificationRead(notificationId) {
  if (!notificationId) {
    return;
  }

  await updateDoc(doc(db, 'notifications', notificationId), {
    isRead: true,
  });
}

async function markNotificationsRead(notificationIds) {
  const ids = [...new Set((notificationIds || []).map((value) => String(value || '').trim()).filter(Boolean))];
  if (ids.length === 0) {
    return;
  }

  const batch = writeBatch(db);
  ids.forEach((id) => {
    batch.update(doc(db, 'notifications', id), {
      isRead: true,
    });
  });

  await batch.commit();
}

export { loadNotificationsPage, markNotificationRead, markNotificationsRead, normalizeNotification };
