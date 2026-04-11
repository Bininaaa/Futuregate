const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function loadServiceAccount() {
  const inlineJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (inlineJson) {
    return JSON.parse(inlineJson);
  }

  const configuredPath =
      process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const localPath = path.join(__dirname, 'service-account.local.json');
  const candidatePath = configuredPath || localPath;

  if (!fs.existsSync(candidatePath)) {
    throw new Error(
      [
        'Missing Firebase Admin credentials.',
        'Set FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT_PATH,',
        'or GOOGLE_APPLICATION_CREDENTIALS, or place a local file at',
        `"${localPath}".`,
      ].join(' '),
    );
  }

  const credentialContents = fs.readFileSync(candidatePath, 'utf8');
  return JSON.parse(credentialContents);
}

admin.initializeApp({
  credential: admin.credential.cert(loadServiceAccount()),
});

const db = admin.firestore();

// Admin configuration (single source of truth).
const ADMIN_UID = 'zjCtD53DBxMqQAIRwCdma9l1Hwj1';
const ADMIN_EMAIL = 'avenirdz13@gmail.com';
const ADMIN_PASSWORD = 'Admin123456!';
const ADMIN_NAME = 'Admin FutureGate';
const ADMIN_ONLY_MODE = process.argv.includes('--admin-only');

function isUserNotFoundError(error) {
  return (
    error &&
    (error.code === 'auth/user-not-found' ||
      error.errorInfo?.code === 'auth/user-not-found')
  );
}

async function ensureAdminAuthUser() {
  console.log(
    `Ensuring admin auth account for ${ADMIN_EMAIL} (${ADMIN_UID})...`,
  );

  try {
    const existingUser = await admin.auth().getUser(ADMIN_UID);

    if (
      existingUser.email !== ADMIN_EMAIL ||
      existingUser.displayName !== ADMIN_NAME
    ) {
      const updatedUser = await admin.auth().updateUser(ADMIN_UID, {
        email: ADMIN_EMAIL,
        displayName: ADMIN_NAME,
      });

      console.log('Admin auth account updated:', updatedUser.uid);
      return { user: updatedUser, status: 'updated' };
    }

    console.log('Admin auth account already exists:', existingUser.uid);
    return { user: existingUser, status: 'existing' };
  } catch (error) {
    if (!isUserNotFoundError(error)) {
      throw error;
    }
  }

  try {
    const userByEmail = await admin.auth().getUserByEmail(ADMIN_EMAIL);

    if (userByEmail.uid !== ADMIN_UID) {
      throw new Error(
        [
          `Firebase Auth email ${ADMIN_EMAIL} already belongs to UID`,
          `${userByEmail.uid}, expected ${ADMIN_UID}.`,
          'Resolve the Auth mismatch before rerunning the seed.',
        ].join(' '),
      );
    }

    if (userByEmail.displayName !== ADMIN_NAME) {
      const updatedUser = await admin.auth().updateUser(ADMIN_UID, {
        displayName: ADMIN_NAME,
      });

      console.log('Admin auth account updated:', updatedUser.uid);
      return { user: updatedUser, status: 'updated' };
    }

    console.log('Admin auth account found by email:', userByEmail.uid);
    return { user: userByEmail, status: 'existing' };
  } catch (error) {
    if (!isUserNotFoundError(error)) {
      throw error;
    }
  }

  const createdUser = await admin.auth().createUser({
    uid: ADMIN_UID,
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    displayName: ADMIN_NAME,
  });

  console.log('Admin auth account created:', createdUser.uid);
  return { user: createdUser, status: 'created' };
}

async function upsertAdminUserDocument() {
  const adminUserRef = db.collection('users').doc(ADMIN_UID);
  const existingAdminSnapshot = await adminUserRef.get();
  const existingAdminData = existingAdminSnapshot.exists
    ? existingAdminSnapshot.data()
    : null;

  await adminUserRef.set(
    {
      uid: ADMIN_UID,
      email: ADMIN_EMAIL,
      fullName: ADMIN_NAME,
      role: 'admin',
      adminLevel: 'super_admin',
      isActive: true,
      provider: 'email',
      phone: '',
      location: '',
      profileImage: '',
      academicLevel: '',
      university: '',
      fieldOfStudy: '',
      bio: '',
      companyName: '',
      sector: '',
      description: '',
      website: '',
      logo: '',
      researchTopic: '',
      laboratory: '',
      supervisor: '',
      researchDomain: '',
      createdAt:
        existingAdminData?.createdAt ??
        admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(`Admin Firestore document upserted: users/${ADMIN_UID}`);
}

async function seedAdminAccount() {
  const authResult = await ensureAdminAuthUser();
  await upsertAdminUserDocument();
  return authResult;
}

async function seedDatabase() {
  try {
    console.log('Seeding started...');
    const adminUid = ADMIN_UID;

    if (ADMIN_ONLY_MODE) {
      const adminResult = await seedAdminAccount();

      console.log('');
      console.log('========================================');
      console.log('Admin seed completed successfully!');
      console.log('========================================');
      console.log(`Firestore document: users/${ADMIN_UID}`);

      if (adminResult.status === 'created') {
        console.log(`Admin auth account created for ${ADMIN_EMAIL}.`);
        console.log(`Temporary login: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
      } else if (adminResult.status === 'updated') {
        console.log(
          `Admin auth account updated for ${ADMIN_EMAIL}. Password was not changed.`,
        );
      } else {
        console.log(
          `Admin auth account already matched ${ADMIN_EMAIL}. Password was not changed.`,
        );
      }

      console.log('');
      process.exit(0);
    }

    const adminResult = await seedAdminAccount();

    // USERS
    await db.collection('users').doc('student_bac_001').set({
      uid: 'student_bac_001',
      fullName: 'Yasser Bac',
      email: 'bac@email.dz',
      role: 'student',
      academicLevel: 'bac',
      phone: '+213555111111',
      location: 'Algiers, Algeria',
      profileImage: '',
      university: '',
      fieldOfStudy: '',
      bio: 'New bac student',
      companyName: '',
      sector: '',
      description: '',
      website: '',
      logo: '',
      adminLevel: '',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('users').doc('student_licence_001').set({
      uid: 'student_licence_001',
      fullName: 'Yasser Licence',
      email: 'licence@email.dz',
      role: 'student',
      academicLevel: 'licence',
      phone: '+213555222222',
      location: 'Oran, Algeria',
      profileImage: '',
      university: 'University of Oran',
      fieldOfStudy: 'Computer Science',
      bio: 'Licence student interested in mobile development',
      companyName: '',
      sector: '',
      description: '',
      website: '',
      logo: '',
      adminLevel: '',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('users').doc('student_master_001').set({
      uid: 'student_master_001',
      fullName: 'Yasser Master',
      email: 'master@email.dz',
      role: 'student',
      academicLevel: 'master',
      phone: '+213555333333',
      location: 'Algiers, Algeria',
      profileImage: '',
      university: 'University of Algiers',
      fieldOfStudy: 'Computer Science',
      bio: 'Master student interested in AI and mobile development',
      companyName: '',
      sector: '',
      description: '',
      website: '',
      logo: '',
      adminLevel: '',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('users').doc('company_001').set({
      uid: 'company_001',
      fullName: 'Ooredoo HR',
      email: 'hr@ooredoo.dz',
      role: 'company',
      phone: '+213555888111',
      location: 'Algiers, Algeria',
      profileImage: '',
      academicLevel: '',
      university: '',
      fieldOfStudy: '',
      bio: '',
      companyName: 'Ooredoo Algeria',
      sector: 'Telecommunications',
      description: 'Telecom company offering internships and jobs',
      website: 'https://www.ooredoo.dz',
      logo: '',
      adminLevel: '',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Users seeded.');

    // OPPORTUNITIES
    await db.collection('opportunities').doc('opp_001').set({
      id: 'opp_001',
      companyId: 'company_001',
      companyName: 'Ooredoo Algeria',
      companyLogo: '',
      title: 'Junior Flutter Developer',
      description:
          'We are looking for a junior Flutter developer for mobile projects.',
      type: 'job',
      location: 'Algiers, Algeria',
      requirements: 'Flutter, Firebase, teamwork',
      status: 'open',
      deadline: '2026-04-01',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('opportunities').doc('opp_002').set({
      id: 'opp_002',
      companyId: 'company_001',
      companyName: 'Ooredoo Algeria',
      companyLogo: '',
      title: 'AI Internship',
      description:
          'Internship for students interested in AI and Data Science.',
      type: 'internship',
      location: 'Algiers, Algeria',
      requirements: 'Python, ML basics',
      status: 'open',
      deadline: '2026-05-01',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('opportunities').doc('opp_003').set({
      id: 'opp_003',
      companyId: 'company_001',
      companyName: 'Ooredoo Algeria',
      companyLogo: '',
      title: 'Marketing Internship',
      description: 'Join our marketing team for a 3-month internship.',
      type: 'internship',
      location: 'Oran, Algeria',
      requirements: 'Marketing knowledge, social media skills',
      status: 'open',
      deadline: '2026-06-01',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Opportunities seeded.');

    // APPLICATIONS
    await db.collection('applications').doc('app_001').set({
      id: 'app_001',
      studentId: 'student_master_001',
      studentName: 'Yasser Master',
      opportunityId: 'opp_001',
      companyId: 'company_001',
      cvId: 'cv_001',
      status: 'pending',
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('applications').doc('app_002').set({
      id: 'app_002',
      studentId: 'student_licence_001',
      studentName: 'Yasser Licence',
      opportunityId: 'opp_001',
      companyId: 'company_001',
      cvId: 'cv_002',
      status: 'pending',
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('applications').doc('app_003').set({
      id: 'app_003',
      studentId: 'student_bac_001',
      studentName: 'Yasser Bac',
      opportunityId: 'opp_001',
      companyId: 'company_001',
      cvId: '',
      status: 'pending',
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('applications').doc('app_004').set({
      id: 'app_004',
      studentId: 'student_master_001',
      studentName: 'Yasser Master',
      opportunityId: 'opp_002',
      companyId: 'company_001',
      cvId: 'cv_001',
      status: 'accepted',
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('applications').doc('app_005').set({
      id: 'app_005',
      studentId: 'student_licence_001',
      studentName: 'Yasser Licence',
      opportunityId: 'opp_002',
      companyId: 'company_001',
      cvId: 'cv_002',
      status: 'pending',
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Applications seeded.');

    // TRAININGS
    await db.collection('trainings').doc('training_001').set({
      id: 'training_001',
      title: 'Flutter for Beginners',
      description: 'Learn Flutter from scratch with hands-on projects.',
      provider: 'Ooredoo Academy',
      duration: '6 weeks',
      level: 'beginner',
      link: 'https://example.com/flutter-course',
      createdBy: 'company_001',
      createdByRole: 'company',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('trainings').doc('training_002').set({
      id: 'training_002',
      title: 'Python & Machine Learning',
      description:
          'Introduction to Python programming and basic ML concepts.',
      provider: 'Algeria Digital Academy',
      duration: '8 weeks',
      level: 'intermediate',
      link: 'https://example.com/python-ml',
      createdBy: adminUid,
      createdByRole: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Trainings seeded.');

    // SCHOLARSHIPS
    await db.collection('scholarships').doc('scholarship_001').set({
      id: 'scholarship_001',
      title: 'Excellence Master Scholarship',
      description:
          'Full funding for high-achieving master students in STEM fields. Covers tuition, living expenses, and travel.',
      provider: 'Campus France',
      eligibility: 'Master students in STEM with GPA above 14/20',
      amount: 10000,
      deadline: '2026-05-15',
      link: 'https://example.com/scholarship',
      createdBy: adminUid,
      createdByRole: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('scholarships').doc('scholarship_002').set({
      id: 'scholarship_002',
      title: 'Licence Research Grant',
      description:
          'Financial support for licence students conducting research projects in technology and innovation.',
      provider: 'Ministry of Higher Education',
      eligibility: 'Licence students in Computer Science or Engineering',
      amount: 5000,
      deadline: '2026-07-01',
      link: 'https://example.com/research-grant',
      createdBy: adminUid,
      createdByRole: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Scholarships seeded.');

    // PROJECT IDEAS
    await db.collection('projectIdeas').doc('project_001').set({
      id: 'project_001',
      title: 'Smart CV Analyzer',
      description:
          'An application that evaluates CV quality using AI and provides improvement suggestions to students.',
      domain: 'AI / Mobile',
      level: 'master',
      tools: 'Flutter, Python, TensorFlow',
      status: 'approved',
      submittedBy: 'student_master_001',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('projectIdeas').doc('project_002').set({
      id: 'project_002',
      title: 'University Course Scheduler',
      description:
          'A web app that helps students plan their weekly schedule based on available courses and preferences.',
      domain: 'Web Development',
      level: 'licence',
      tools: 'React, Node.js, Firebase',
      status: 'pending',
      submittedBy: 'student_licence_001',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('projectIdeas').doc('project_003').set({
      id: 'project_003',
      title: 'Student Budget Tracker',
      description:
          'A mobile app for students to track their daily expenses and manage their budget effectively.',
      domain: 'Mobile Development',
      level: 'bac',
      tools: 'Flutter, SQLite',
      status: 'pending',
      submittedBy: 'student_bac_001',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Project Ideas seeded.');

    // CVS
    await db.collection('cvs').doc('cv_001').set({
      id: 'cv_001',
      studentId: 'student_master_001',
      fullName: 'Yasser Master',
      email: 'master@email.dz',
      phone: '+213555333333',
      address: 'Algiers, Algeria',
      summary:
          'Master student in computer science seeking internship opportunities in mobile development and AI.',
      education: [
        {
          degree: 'Master in Computer Science',
          institution: 'University of Algiers',
          year: '2024-2026',
        },
        {
          degree: 'Licence in Computer Science',
          institution: 'University of Algiers',
          year: '2021-2024',
        },
      ],
      experience: [
        {
          position: 'Mobile Developer Intern',
          company: 'Ooredoo Algeria',
          duration: '3 months (Summer 2025)',
        },
        {
          position: 'Freelance Web Developer',
          company: 'Self-employed',
          duration: '6 months (2024)',
        },
      ],
      skills: ['Flutter', 'Firebase', 'Java', 'Python', 'SQL', 'Git'],
      languages: ['Arabic', 'French', 'English'],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('cvs').doc('cv_002').set({
      id: 'cv_002',
      studentId: 'student_licence_001',
      fullName: 'Yasser Licence',
      email: 'licence@email.dz',
      phone: '+213555222222',
      address: 'Oran, Algeria',
      summary:
          'Licence student in computer science passionate about web and mobile development.',
      education: [
        {
          degree: 'Licence in Computer Science',
          institution: 'University of Oran',
          year: '2023-2026',
        },
      ],
      experience: [],
      skills: ['HTML', 'CSS', 'JavaScript', 'React', 'Flutter'],
      languages: ['Arabic', 'French'],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('CVs seeded.');

    // SAVED OPPORTUNITIES
    await db.collection('savedOpportunities').doc('save_001').set({
      id: 'save_001',
      studentId: 'student_master_001',
      opportunityId: 'opp_001',
      title: 'Junior Flutter Developer',
      companyName: 'Ooredoo Algeria',
      type: 'job',
      location: 'Algiers, Algeria',
      deadline: '2026-04-01',
      savedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('savedOpportunities').doc('save_002').set({
      id: 'save_002',
      studentId: 'student_master_001',
      opportunityId: 'opp_002',
      title: 'AI Internship',
      companyName: 'Ooredoo Algeria',
      type: 'internship',
      location: 'Algiers, Algeria',
      deadline: '2026-05-01',
      savedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('savedOpportunities').doc('save_003').set({
      id: 'save_003',
      studentId: 'student_licence_001',
      opportunityId: 'opp_003',
      title: 'Marketing Internship',
      companyName: 'Ooredoo Algeria',
      type: 'internship',
      location: 'Oran, Algeria',
      deadline: '2026-06-01',
      savedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Saved Opportunities seeded.');

    // CONVERSATIONS
    await db.collection('conversations').doc('conv_001').set({
      id: 'conv_001',
      studentId: 'student_master_001',
      studentName: 'Yasser Master',
      companyId: 'company_001',
      companyName: 'Ooredoo Algeria',
      lastMessage: 'Hello, I am interested in the internship.',
      lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active',
    });

    await db
        .collection('conversations')
        .doc('conv_001')
        .collection('messages')
        .doc('msg_001')
        .set({
      id: 'msg_001',
      senderId: 'student_master_001',
      senderRole: 'student',
      text: 'Hello, I am interested in the internship.',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    });

    await db
        .collection('conversations')
        .doc('conv_001')
        .collection('messages')
        .doc('msg_002')
        .set({
      id: 'msg_002',
      senderId: 'company_001',
      senderRole: 'company',
      text: 'Hello Yasser, thank you for your interest.',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    });

    console.log('Conversations seeded.');

    // NOTIFICATIONS
    await db.collection('notifications').doc('notif_001').set({
      id: 'notif_001',
      userId: 'student_master_001',
      title: 'Application sent',
      message:
          'Your application for Junior Flutter Developer was sent successfully.',
      type: 'application',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('notifications').doc('notif_002').set({
      id: 'notif_002',
      userId: 'student_licence_001',
      title: 'New Scholarship Available',
      message:
          'A new scholarship matching your profile is available. Check it out!',
      type: 'scholarship',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Notifications seeded.');

    console.log('');
    console.log('========================================');
    console.log('Database seeded successfully!');
    console.log('========================================');
    console.log('');
    console.log('Collections created:');
    console.log('  - users (5 docs: 3 students, 1 company, 1 admin)');
    console.log('  - opportunities (3 docs)');
    console.log('  - applications (5 docs)');
    console.log('  - trainings (2 docs)');
    console.log('  - scholarships (2 docs)');
    console.log('  - projectIdeas (3 docs)');
    console.log('  - cvs (2 docs)');
    console.log('  - savedOpportunities (3 docs)');
    console.log('  - conversations (1 doc with 2 messages)');
    console.log('  - notifications (2 docs)');
    console.log('');
    console.log(`Admin Firestore document: users/${ADMIN_UID}`);
    if (adminResult.status === 'created') {
      console.log(`Admin login: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
    } else if (adminResult.status === 'updated') {
      console.log(
        `Admin auth account updated for ${ADMIN_EMAIL}. Password was not changed.`,
      );
    } else {
      console.log(
        `Admin auth account already matched ${ADMIN_EMAIL}. Password was not changed.`,
      );
    }
    console.log('');

    process.exit(0);
  } catch (error) {
    console.error('Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();
