import {
  db,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
} from './firebase-config.js';
import {
  activityTypeLabel,
  timestampToMs,
  truncateText,
} from './admin-utils.js';

const ACTIVITY_SOURCES = [
  {
    key: 'applications',
    type: 'application',
    collectionName: 'applications',
    orderField: 'appliedAt',
  },
  {
    key: 'projectIdeas',
    type: 'project_idea',
    collectionName: 'projectIdeas',
    orderField: 'createdAt',
  },
  {
    key: 'opportunities',
    type: 'opportunity',
    collectionName: 'opportunities',
    orderField: 'createdAt',
  },
  {
    key: 'scholarships',
    type: 'scholarship',
    collectionName: 'scholarships',
    orderField: 'createdAt',
  },
  {
    key: 'trainings',
    type: 'training',
    collectionName: 'trainings',
    orderField: 'createdAt',
  },
];

function createActivityState() {
  return ACTIVITY_SOURCES.reduce((state, source) => {
    state[source.key] = {
      items: [],
      lastDoc: null,
      hasMore: true,
    };
    return state;
  }, {});
}

async function enrichApplicationActivities(docs) {
  const opportunityIds = [...new Set(docs.map((item) => String(item.data().opportunityId || '').trim()).filter(Boolean))];
  const opportunityEntries = await Promise.all(
    opportunityIds.map(async (id) => {
      const snapshot = await getDoc(doc(db, 'opportunities', id)).catch(() => null);
      return [id, snapshot?.exists() ? snapshot.data() : null];
    }),
  );
  const opportunities = new Map(opportunityEntries);

  return docs.map((snapshot) => {
    const data = snapshot.data() || {};
    const opportunity = opportunities.get(String(data.opportunityId || '').trim()) || {};
    const opportunityTitle = String(opportunity?.title || 'Untitled opportunity').trim();
    const companyName = String(opportunity?.companyName || 'Unknown company').trim();
    const studentName = String(data.studentName || 'Student').trim();
    const status = String(data.status || '').trim();

    return {
      id: snapshot.id,
      type: 'application',
      typeLabel: activityTypeLabel('application'),
      targetId: snapshot.id,
      timestamp: data.appliedAt || null,
      title: opportunityTitle,
      actorName: studentName,
      status,
      description: `${studentName} applied to ${opportunityTitle} at ${companyName}.`,
    };
  });
}

async function enrichProjectIdeaActivities(docs) {
  return docs.map((snapshot) => {
    const data = snapshot.data() || {};
    const title = String(data.title || 'Untitled project idea').trim();
    const actorName = String(data.submittedByName || data.submittedBy || 'Student').trim();
    const status = String(data.status || 'pending').trim();

    return {
      id: snapshot.id,
      type: 'project_idea',
      typeLabel: activityTypeLabel('project_idea'),
      targetId: snapshot.id,
      timestamp: data.createdAt || null,
      title,
      actorName,
      status,
      description: `${actorName} submitted "${title}".`,
    };
  });
}

async function enrichOpportunityActivities(docs) {
  return docs.map((snapshot) => {
    const data = snapshot.data() || {};
    const title = String(data.title || 'Untitled opportunity').trim();
    const actorName = String(data.companyName || 'Unknown company').trim();
    const status = String(data.status || '').trim();

    return {
      id: snapshot.id,
      type: 'opportunity',
      typeLabel: activityTypeLabel('opportunity'),
      targetId: snapshot.id,
      timestamp: data.createdAt || null,
      title,
      actorName,
      status,
      description: `${actorName} published "${title}".`,
    };
  });
}

async function enrichScholarshipActivities(docs) {
  return docs.map((snapshot) => {
    const data = snapshot.data() || {};
    const title = String(data.title || 'Untitled scholarship').trim();
    const actorName = String(data.provider || 'Unknown provider').trim();

    return {
      id: snapshot.id,
      type: 'scholarship',
      typeLabel: activityTypeLabel('scholarship'),
      targetId: snapshot.id,
      timestamp: data.createdAt || null,
      title,
      actorName,
      status: '',
      description: `${actorName} published "${title}".`,
    };
  });
}

async function enrichTrainingActivities(docs) {
  return docs.map((snapshot) => {
    const data = snapshot.data() || {};
    const title = String(data.title || 'Untitled training').trim();
    const actorName = String(data.provider || data.source || 'Training source').trim();

    return {
      id: snapshot.id,
      type: 'training',
      typeLabel: activityTypeLabel('training'),
      targetId: snapshot.id,
      timestamp: data.createdAt || null,
      title,
      actorName,
      status: data.isFeatured === true ? 'featured' : '',
      description: `${actorName} added "${title}".`,
    };
  });
}

async function mapActivityDocs(source, docs) {
  switch (source.type) {
    case 'application':
      return enrichApplicationActivities(docs);
    case 'project_idea':
      return enrichProjectIdeaActivities(docs);
    case 'opportunity':
      return enrichOpportunityActivities(docs);
    case 'scholarship':
      return enrichScholarshipActivities(docs);
    case 'training':
      return enrichTrainingActivities(docs);
    default:
      return [];
  }
}

async function loadRecentActivitiesPage(state, { pageSize = 4, maxItems = 50 } = {}) {
  const nextState = state || createActivityState();

  await Promise.all(
    ACTIVITY_SOURCES.map(async (source) => {
      const sourceState = nextState[source.key];
      if (!sourceState || sourceState.hasMore === false) {
        return;
      }

      const constraints = [orderBy(source.orderField, 'desc'), limit(pageSize)];
      if (sourceState.lastDoc) {
        constraints.push(startAfter(sourceState.lastDoc));
      }

      const snapshot = await getDocs(query(collection(db, source.collectionName), ...constraints));
      if (snapshot.empty) {
        sourceState.hasMore = false;
        return;
      }

      const mappedItems = await mapActivityDocs(source, snapshot.docs);
      sourceState.items.push(...mappedItems);
      sourceState.lastDoc = snapshot.docs[snapshot.docs.length - 1];
      sourceState.hasMore = snapshot.docs.length === pageSize;
    }),
  );

  const items = ACTIVITY_SOURCES.flatMap((source) => nextState[source.key]?.items || [])
    .sort((left, right) => timestampToMs(right.timestamp) - timestampToMs(left.timestamp))
    .slice(0, maxItems)
    .map((item) => ({
      ...item,
      description: truncateText(item.description, 160),
    }));

  const hasMore = ACTIVITY_SOURCES.some((source) => nextState[source.key]?.hasMore);

  return {
    items,
    state: nextState,
    hasMore,
  };
}

export { createActivityState, loadRecentActivitiesPage };
