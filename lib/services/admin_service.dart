import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_chart_data.dart';
import '../models/admin_activity_model.dart';
import '../models/admin_activity_preview_model.dart';
import '../models/admin_application_item_model.dart';
import '../models/application_model.dart';
import '../models/opportunity_model.dart';
import '../models/training_model.dart';
import '../models/user_model.dart';
import '../models/project_idea_model.dart';
import '../utils/application_status.dart';
import '../utils/opportunity_metadata.dart';
import '../utils/opportunity_type.dart';
import 'company_service.dart';
import 'notification_worker_service.dart';
import 'worker_api_service.dart';

class AdminService {
  static const String activitySourceApplications = 'applications';
  static const String activitySourceOpportunities = 'opportunities';
  static const String activitySourceScholarships = 'scholarships';
  static const String activitySourceTrainings = 'trainings';
  static const String activitySourceProjectIdeas = 'projectIdeas';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();
  final WorkerApiService _workerApi = WorkerApiService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    await _expireDeadlinesBestEffort();

    final usersSnapshot = await _firestore.collection('users').get();
    final opportunitiesSnapshot = await _firestore
        .collection('opportunities')
        .get();
    final trainingsSnapshot = await _firestore.collection('trainings').get();
    final scholarshipsSnapshot = await _firestore
        .collection('scholarships')
        .get();
    final applicationsSnapshot = await _firestore
        .collection('applications')
        .get();
    final projectIdeasSnapshot = await _firestore
        .collection('projectIdeas')
        .get();
    final cvsSnapshot = await _firestore.collection('cvs').get();
    final savedSnapshot = await _firestore
        .collection('savedOpportunities')
        .get();
    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('status', isEqualTo: 'active')
        .get();

    int totalUsers = usersSnapshot.docs.length;
    int studentsCount = 0;
    int bacCount = 0;
    int licenceCount = 0;
    int masterCount = 0;
    int doctoratCount = 0;
    int companyCount = 0;
    int adminCount = 0;
    int pendingCompanyCount = 0;
    int approvedCompanyCount = 0;
    int rejectedCompanyCount = 0;
    int activeUsersCount = 0;
    int inactiveUsersCount = 0;

    final Map<String, int> monthlyMap = {
      'Jan': 0,
      'Feb': 0,
      'Mar': 0,
      'Apr': 0,
      'May': 0,
      'Jun': 0,
      'Jul': 0,
      'Aug': 0,
      'Sep': 0,
      'Oct': 0,
      'Nov': 0,
      'Dec': 0,
    };

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = data['role'] ?? '';
      final academicLevel = data['academicLevel'] ?? '';
      final isActive = data['isActive'] ?? true;
      final createdAt = data['createdAt'];

      if (role == 'student') {
        studentsCount++;
        if (academicLevel == 'bac') {
          bacCount++;
        } else if (academicLevel == 'licence') {
          licenceCount++;
        } else if (academicLevel == 'master') {
          masterCount++;
        } else if (academicLevel == 'doctorat') {
          doctoratCount++;
        }
      } else if (role == 'company') {
        companyCount++;
        final approvalStatus = _normalizeCompanyApprovalStatus(
          data['approvalStatus'],
        );
        if (approvalStatus == 'pending') {
          pendingCompanyCount++;
        } else if (approvalStatus == 'rejected') {
          rejectedCompanyCount++;
        } else {
          approvedCompanyCount++;
        }
      } else if (role == 'admin') {
        adminCount++;
      }

      if (isActive == true) {
        activeUsersCount++;
      } else {
        inactiveUsersCount++;
      }

      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        final monthLabel = _monthLabel(date.month);
        monthlyMap[monthLabel] = (monthlyMap[monthLabel] ?? 0) + 1;
      }
    }

    final int totalApplications = applicationsSnapshot.docs.length;
    final int totalOpportunities = opportunitiesSnapshot.docs.length;
    final double applicationRate = totalOpportunities > 0
        ? (totalApplications / totalOpportunities)
        : 0.0;
    var pendingApplications = 0;
    var approvedApplications = 0;
    var rejectedApplications = 0;
    for (final doc in applicationsSnapshot.docs) {
      switch (ApplicationStatus.parse(doc.data()['status'])) {
        case ApplicationStatus.pending:
          pendingApplications++;
          break;
        case ApplicationStatus.accepted:
          approvedApplications++;
          break;
        case ApplicationStatus.rejected:
          rejectedApplications++;
          break;
        case ApplicationStatus.withdrawn:
          break;
      }
    }
    var openOpportunities = 0;
    var closedOpportunities = 0;
    var hiddenOpportunities = 0;
    for (final doc in opportunitiesSnapshot.docs) {
      final model = OpportunityModel.fromMap({...doc.data(), 'id': doc.id});
      if (model.isHidden) {
        hiddenOpportunities++;
      }
      if (model.effectiveStatus() == 'closed') {
        closedOpportunities++;
      } else {
        openOpportunities++;
      }
    }

    final int totalCvs = cvsSnapshot.docs.length;
    final double cvCompletionRate = studentsCount > 0
        ? (totalCvs / studentsCount) * 100
        : 0.0;

    final Map<String, int> applicationCounts = {};
    final Map<String, String> opportunityTitles = {};
    final Map<String, String> opportunityTypes = {};
    final Map<String, String> savedOpportunityTitles = {};
    final Map<String, String> savedOpportunityTypes = {};
    for (final doc in opportunitiesSnapshot.docs) {
      final data = doc.data();
      opportunityTitles[doc.id] = _resolveOpportunityTitle(data);
      opportunityTypes[doc.id] = OpportunityType.parse(
        data['type']?.toString(),
      );
    }
    for (final doc in applicationsSnapshot.docs) {
      final data = doc.data();
      final oppId = (data['opportunityId'] ?? '').toString().trim();
      if (oppId.isEmpty) {
        continue;
      }
      applicationCounts[oppId] = (applicationCounts[oppId] ?? 0) + 1;
    }

    final Map<String, int> saveCounts = {};
    for (final doc in savedSnapshot.docs) {
      final data = doc.data();
      final oppId = (data['opportunityId'] ?? '').toString().trim();
      if (oppId.isEmpty) {
        continue;
      }
      final savedTitle = _cleanLabel(data['title']);
      if (savedTitle.isNotEmpty) {
        savedOpportunityTitles[oppId] = savedTitle;
      }
      savedOpportunityTypes[oppId] = OpportunityType.parse(
        data['type']?.toString(),
      );
      saveCounts[oppId] = (saveCounts[oppId] ?? 0) + 1;
    }

    final sortedByApplications = applicationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApplied = sortedByApplications
        .map(
          (e) => _buildRankedOpportunityItem(
            id: e.key,
            count: e.value,
            liveTitles: opportunityTitles,
            liveTypes: opportunityTypes,
            savedTitles: savedOpportunityTitles,
            savedTypes: savedOpportunityTypes,
          ),
        )
        .whereType<Map<String, dynamic>>()
        .take(3)
        .toList();

    final sortedBySaves = saveCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSaved = sortedBySaves
        .map(
          (e) => _buildRankedOpportunityItem(
            id: e.key,
            count: e.value,
            liveTitles: opportunityTitles,
            liveTypes: opportunityTypes,
            savedTitles: savedOpportunityTitles,
            savedTypes: savedOpportunityTypes,
          ),
        )
        .whereType<Map<String, dynamic>>()
        .take(3)
        .toList();

    int pendingIdeas = 0;
    int approvedIdeas = 0;
    for (final doc in projectIdeasSnapshot.docs) {
      final status = doc.data()['status'] ?? 'pending';
      if (status == 'pending') {
        pendingIdeas++;
      } else if (status == 'approved') {
        approvedIdeas++;
      }
    }

    final monthlyRegistrations = monthlyMap.entries
        .map((entry) => {'month': entry.key, 'count': entry.value})
        .toList();

    return {
      'totalUsers': totalUsers,
      'students': studentsCount,
      'bac': bacCount,
      'licence': licenceCount,
      'master': masterCount,
      'companies': companyCount,
      'pendingCompanies': pendingCompanyCount,
      'approvedCompanies': approvedCompanyCount,
      'rejectedCompanies': rejectedCompanyCount,
      'doctorat': doctoratCount,
      'admins': adminCount,
      'activeUsers': activeUsersCount,
      'inactiveUsers': inactiveUsersCount,
      'opportunities': totalOpportunities,
      'openOpportunities': openOpportunities,
      'closedOpportunities': closedOpportunities,
      'hiddenOpportunities': hiddenOpportunities,
      'trainings': trainingsSnapshot.docs.length,
      'scholarships': scholarshipsSnapshot.docs.length,
      'applications': totalApplications,
      'pendingApplications': pendingApplications,
      'approvedApplications': approvedApplications,
      'rejectedApplications': rejectedApplications,
      'projectIdeas': projectIdeasSnapshot.docs.length,
      'pendingIdeas': pendingIdeas,
      'approvedIdeas': approvedIdeas,
      'applicationRate': applicationRate,
      'totalCvs': totalCvs,
      'cvCompletionRate': cvCompletionRate,
      'conversations': conversationsSnapshot.docs.length,
      'totalSaved': savedSnapshot.docs.length,
      'topApplied': topApplied,
      'topSaved': topSaved,
      'monthlyRegistrations': monthlyRegistrations,
    };
  }

  Future<AdminChartData> getAdminChartData() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final opportunitiesSnapshot = await _firestore
        .collection('opportunities')
        .get();
    final applicationsSnapshot = await _firestore
        .collection('applications')
        .get();

    int totalUsers = usersSnapshot.docs.length;
    int totalStudents = 0;
    int totalCompanies = 0;
    int bacCount = 0;
    int licenceCount = 0;
    int masterCount = 0;
    int doctoratCount = 0;

    final Map<String, int> monthlyMap = {
      'Jan': 0,
      'Feb': 0,
      'Mar': 0,
      'Apr': 0,
      'May': 0,
      'Jun': 0,
      'Jul': 0,
      'Aug': 0,
      'Sep': 0,
      'Oct': 0,
      'Nov': 0,
      'Dec': 0,
    };

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();

      final role = (data['role'] ?? '').toString().toLowerCase();
      final academicLevel = (data['academicLevel'] ?? '')
          .toString()
          .toLowerCase();
      final createdAt = data['createdAt'];

      if (role == 'student') {
        totalStudents++;
      } else if (role == 'company') {
        totalCompanies++;
      }

      if (academicLevel == 'bac') {
        bacCount++;
      } else if (academicLevel == 'licence') {
        licenceCount++;
      } else if (academicLevel == 'master') {
        masterCount++;
      } else if (academicLevel == 'doctorat') {
        doctoratCount++;
      }

      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        final monthLabel = _monthLabel(date.month);
        monthlyMap[monthLabel] = (monthlyMap[monthLabel] ?? 0) + 1;
      }
    }

    final monthlyRegistrations = monthlyMap.entries
        .map((entry) => MonthlyStat(month: entry.key, count: entry.value))
        .toList();

    return AdminChartData(
      totalUsers: totalUsers,
      totalStudents: totalStudents,
      totalCompanies: totalCompanies,
      totalOpportunities: opportunitiesSnapshot.docs.length,
      totalApplications: applicationsSnapshot.docs.length,
      bacCount: bacCount,
      licenceCount: licenceCount,
      masterCount: masterCount,
      doctoratCount: doctoratCount,
      monthlyRegistrations: monthlyRegistrations,
    );
  }

  String _monthLabel(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  Future<List<UserModel>> getRecentUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snapshot.docs
        .map(
          (doc) => UserModel.fromMap({
            ...doc.data(),
            'uid': (doc.data()['uid'] ?? doc.id).toString(),
          }),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRecentOpportunities() async {
    await _expireDeadlinesBestEffort();

    final snapshot = await _firestore
        .collection('opportunities')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<AdminActivityBatch> getAdminActivityBatch({
    required String source,
    int limit = 8,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    switch (source) {
      case activitySourceApplications:
        return _getApplicationActivityBatch(
          limit: limit,
          startAfterDocument: startAfterDocument,
        );
      case activitySourceOpportunities:
        return _getOpportunityActivityBatch(
          limit: limit,
          startAfterDocument: startAfterDocument,
        );
      case activitySourceScholarships:
        return _getScholarshipActivityBatch(
          limit: limit,
          startAfterDocument: startAfterDocument,
        );
      case activitySourceTrainings:
        return _getTrainingActivityBatch(
          limit: limit,
          startAfterDocument: startAfterDocument,
        );
      case activitySourceProjectIdeas:
        return _getProjectIdeaActivityBatch(
          limit: limit,
          startAfterDocument: startAfterDocument,
        );
      default:
        throw ArgumentError.value(
          source,
          'source',
          'Unknown admin activity source',
        );
    }
  }

  Future<List<AdminActivityModel>> getAdminActivities({
    int perCollectionLimit = 4,
  }) async {
    final safeLimit = perCollectionLimit < 1 ? 1 : perCollectionLimit;

    final results = await Future.wait([
      _firestore
          .collection('applications')
          .orderBy('appliedAt', descending: true)
          .limit(safeLimit)
          .get(),
      _firestore
          .collection('opportunities')
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
          .get(),
      _firestore
          .collection('scholarships')
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
          .get(),
      _firestore
          .collection('trainings')
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
          .get(),
      _firestore
          .collection('projectIdeas')
          .orderBy('createdAt', descending: true)
          .limit(safeLimit)
          .get(),
    ]);

    final applicationSnapshot = results[0];
    final opportunitySnapshot = results[1];
    final scholarshipSnapshot = results[2];
    final trainingSnapshot = results[3];
    final projectIdeaSnapshot = results[4];

    final applicationOpportunityIds = applicationSnapshot.docs
        .map((doc) => (doc.data()['opportunityId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final opportunityInfo = await _fetchOpportunityInfo(
      applicationOpportunityIds,
    );

    final projectIdeaOwnerIds = projectIdeaSnapshot.docs
        .map((doc) => (doc.data()['submittedBy'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final ownerNames = await _fetchUserDisplayNames(projectIdeaOwnerIds);

    final activities = <AdminActivityModel>[
      ...applicationSnapshot.docs.map((doc) {
        final data = doc.data();
        final opportunityId = (data['opportunityId'] ?? '').toString();
        final opportunityMeta = opportunityInfo[opportunityId];
        final opportunityTitle = (opportunityMeta?['title'] ?? '')
            .toString()
            .trim();
        final companyName = (opportunityMeta?['companyName'] ?? '')
            .toString()
            .trim();

        return AdminActivityModel(
          id: 'application_${doc.id}',
          type: 'application',
          relatedId: doc.id,
          relatedCollection: 'applications',
          title: opportunityTitle.isNotEmpty
              ? opportunityTitle
              : 'New application submitted',
          description: companyName.isNotEmpty
              ? 'Application submitted to $companyName'
              : 'A student submitted a new application',
          actorId: (data['studentId'] ?? '').toString(),
          actorName: (data['studentName'] ?? 'Student').toString(),
          status: (data['status'] ?? '').toString(),
          createdAt: data['appliedAt'] as Timestamp?,
        );
      }),
      ...opportunitySnapshot.docs.map((doc) {
        final data = doc.data();
        return AdminActivityModel(
          id: 'opportunity_${doc.id}',
          type: 'opportunity',
          relatedId: doc.id,
          relatedCollection: 'opportunities',
          title: (data['title'] ?? 'Untitled opportunity').toString(),
          description: 'New opportunity created',
          actorId: (data['companyId'] ?? '').toString(),
          actorName: (data['companyName'] ?? 'Company').toString(),
          status: (data['status'] ?? '').toString(),
          createdAt: data['createdAt'] as Timestamp?,
        );
      }),
      ...scholarshipSnapshot.docs.map((doc) {
        final data = doc.data();
        return AdminActivityModel(
          id: 'scholarship_${doc.id}',
          type: 'scholarship',
          relatedId: doc.id,
          relatedCollection: 'scholarships',
          title: (data['title'] ?? 'Untitled scholarship').toString(),
          description: 'New scholarship published',
          actorId: (data['createdBy'] ?? '').toString(),
          actorName: (data['provider'] ?? 'Provider').toString(),
          createdAt: data['createdAt'] as Timestamp?,
        );
      }),
      ...trainingSnapshot.docs.map((doc) {
        final data = doc.data();
        return AdminActivityModel(
          id: 'training_${doc.id}',
          type: 'training',
          relatedId: doc.id,
          relatedCollection: 'trainings',
          title: (data['title'] ?? 'Untitled training').toString(),
          description: 'New training published',
          actorId: (data['createdBy'] ?? '').toString(),
          actorName: (data['provider'] ?? 'Provider').toString(),
          status: (data['isFeatured'] == true) ? 'featured' : '',
          createdAt: data['createdAt'] as Timestamp?,
        );
      }),
      ...projectIdeaSnapshot.docs.map((doc) {
        final data = doc.data();
        final ownerId = (data['submittedBy'] ?? '').toString();
        final ownerName = (data['submittedByName'] ?? '').toString().trim();
        return AdminActivityModel(
          id: 'project_idea_${doc.id}',
          type: 'project_idea',
          relatedId: doc.id,
          relatedCollection: 'projectIdeas',
          title: (data['title'] ?? 'Untitled project idea').toString(),
          description: 'New project idea submitted for review',
          actorId: ownerId,
          actorName: ownerName.isNotEmpty
              ? ownerName
              : (ownerNames[ownerId] ?? 'Student'),
          status: (data['status'] ?? '').toString(),
          createdAt: data['createdAt'] as Timestamp?,
        );
      }),
    ];

    activities.sort(_compareByTimestampDesc);
    return activities;
  }

  Future<AdminActivityPreviewModel?> getActivityPreview(
    AdminActivityModel activity,
  ) async {
    switch (activity.type) {
      case 'application':
        final applicationData = await _getDocumentData(
          activitySourceApplications,
          activity.relatedId,
        );
        if (applicationData == null) {
          return null;
        }

        final opportunityId = (applicationData['opportunityId'] ?? '')
            .toString()
            .trim();
        final opportunityData = await _getDocumentData(
          activitySourceOpportunities,
          opportunityId,
        );

        if ((applicationData['studentName'] ?? '').toString().trim().isEmpty &&
            activity.actorName.trim().isNotEmpty) {
          applicationData['studentName'] = activity.actorName.trim();
        }

        return AdminActivityPreviewModel(
          collection: activitySourceApplications,
          documentId: activity.relatedId,
          data: applicationData,
          relatedCollection: activitySourceOpportunities,
          relatedDocumentId: opportunityId,
          relatedData: opportunityData,
        );
      case 'opportunity':
        final results = await Future.wait([
          _getDocumentData(activitySourceOpportunities, activity.relatedId),
          _firestore
              .collection(activitySourceApplications)
              .where('opportunityId', isEqualTo: activity.relatedId)
              .get(),
        ]);
        final opportunityData = results[0] as Map<String, dynamic>?;
        final applicationsSnapshot =
            results[1] as QuerySnapshot<Map<String, dynamic>>;
        if (opportunityData == null) {
          return null;
        }
        opportunityData['activityApplicationCount'] = applicationsSnapshot.size;

        return AdminActivityPreviewModel(
          collection: activitySourceOpportunities,
          documentId: activity.relatedId,
          data: opportunityData,
        );
      case 'scholarship':
        final scholarshipData = await _getDocumentData(
          activitySourceScholarships,
          activity.relatedId,
        );
        if (scholarshipData == null) {
          return null;
        }

        return AdminActivityPreviewModel(
          collection: activitySourceScholarships,
          documentId: activity.relatedId,
          data: scholarshipData,
        );
      case 'training':
        final trainingData = await _getDocumentData(
          activitySourceTrainings,
          activity.relatedId,
        );
        if (trainingData == null) {
          return null;
        }

        return AdminActivityPreviewModel(
          collection: activitySourceTrainings,
          documentId: activity.relatedId,
          data: trainingData,
        );
      case 'project_idea':
      default:
        final ideaData = await _getDocumentData(
          activitySourceProjectIdeas,
          activity.relatedId,
        );
        if (ideaData == null) {
          return null;
        }

        if ((ideaData['submittedByName'] ?? '').toString().trim().isEmpty &&
            activity.actorName.trim().isNotEmpty) {
          ideaData['submittedByName'] = activity.actorName.trim();
        }

        return AdminActivityPreviewModel(
          collection: activitySourceProjectIdeas,
          documentId: activity.relatedId,
          data: ideaData,
        );
    }
  }

  Future<AdminActivityBatch> _getApplicationActivityBatch({
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final safeLimit = limit < 1 ? 1 : limit;
    final snapshot = await _getActivitySnapshot(
      collection: activitySourceApplications,
      orderField: 'appliedAt',
      limit: safeLimit,
      startAfterDocument: startAfterDocument,
    );
    final pageDocs = _pageDocs(snapshot.docs, safeLimit);
    final opportunityInfo = await _fetchOpportunityInfo(
      pageDocs
          .map((doc) => (doc.data()['opportunityId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet(),
    );

    final activities = pageDocs.map((doc) {
      final data = doc.data();
      final opportunityId = (data['opportunityId'] ?? '').toString();
      final opportunityMeta = opportunityInfo[opportunityId];
      final opportunityTitle = (opportunityMeta?['title'] ?? '')
          .toString()
          .trim();
      final companyName = (opportunityMeta?['companyName'] ?? '')
          .toString()
          .trim();

      return AdminActivityModel(
        id: 'application_${doc.id}',
        type: 'application',
        relatedId: doc.id,
        relatedCollection: activitySourceApplications,
        title: opportunityTitle.isNotEmpty
            ? opportunityTitle
            : 'New application submitted',
        description: companyName.isNotEmpty
            ? 'Application submitted to $companyName'
            : 'A student submitted a new application',
        actorId: (data['studentId'] ?? '').toString(),
        actorName: (data['studentName'] ?? 'Student').toString(),
        status: (data['status'] ?? '').toString(),
        createdAt: data['appliedAt'] as Timestamp?,
      );
    }).toList();

    return AdminActivityBatch(
      activities: activities,
      lastDocument: pageDocs.isEmpty ? startAfterDocument : pageDocs.last,
      hasMore: snapshot.docs.length > safeLimit,
    );
  }

  Future<AdminActivityBatch> _getOpportunityActivityBatch({
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final safeLimit = limit < 1 ? 1 : limit;
    final snapshot = await _getActivitySnapshot(
      collection: activitySourceOpportunities,
      orderField: 'createdAt',
      limit: safeLimit,
      startAfterDocument: startAfterDocument,
    );
    final pageDocs = _pageDocs(snapshot.docs, safeLimit);

    final activities = pageDocs.map((doc) {
      final data = doc.data();
      return AdminActivityModel(
        id: 'opportunity_${doc.id}',
        type: 'opportunity',
        relatedId: doc.id,
        relatedCollection: activitySourceOpportunities,
        title: (data['title'] ?? 'Untitled opportunity').toString(),
        description: 'New opportunity created',
        actorId: (data['companyId'] ?? '').toString(),
        actorName: (data['companyName'] ?? 'Company').toString(),
        status: (data['status'] ?? '').toString(),
        createdAt: data['createdAt'] as Timestamp?,
      );
    }).toList();

    return AdminActivityBatch(
      activities: activities,
      lastDocument: pageDocs.isEmpty ? startAfterDocument : pageDocs.last,
      hasMore: snapshot.docs.length > safeLimit,
    );
  }

  Future<AdminActivityBatch> _getScholarshipActivityBatch({
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final safeLimit = limit < 1 ? 1 : limit;
    final snapshot = await _getActivitySnapshot(
      collection: activitySourceScholarships,
      orderField: 'createdAt',
      limit: safeLimit,
      startAfterDocument: startAfterDocument,
    );
    final pageDocs = _pageDocs(snapshot.docs, safeLimit);

    final activities = pageDocs.map((doc) {
      final data = doc.data();
      return AdminActivityModel(
        id: 'scholarship_${doc.id}',
        type: 'scholarship',
        relatedId: doc.id,
        relatedCollection: activitySourceScholarships,
        title: (data['title'] ?? 'Untitled scholarship').toString(),
        description: 'New scholarship published',
        actorId: (data['createdBy'] ?? '').toString(),
        actorName: (data['provider'] ?? 'Provider').toString(),
        createdAt: data['createdAt'] as Timestamp?,
      );
    }).toList();

    return AdminActivityBatch(
      activities: activities,
      lastDocument: pageDocs.isEmpty ? startAfterDocument : pageDocs.last,
      hasMore: snapshot.docs.length > safeLimit,
    );
  }

  Future<AdminActivityBatch> _getTrainingActivityBatch({
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final safeLimit = limit < 1 ? 1 : limit;
    final snapshot = await _getActivitySnapshot(
      collection: activitySourceTrainings,
      orderField: 'createdAt',
      limit: safeLimit,
      startAfterDocument: startAfterDocument,
    );
    final pageDocs = _pageDocs(snapshot.docs, safeLimit);

    final activities = pageDocs.map((doc) {
      final data = doc.data();
      return AdminActivityModel(
        id: 'training_${doc.id}',
        type: 'training',
        relatedId: doc.id,
        relatedCollection: activitySourceTrainings,
        title: (data['title'] ?? 'Untitled training').toString(),
        description: 'New training published',
        actorId: (data['createdBy'] ?? '').toString(),
        actorName: (data['provider'] ?? 'Provider').toString(),
        status: (data['isFeatured'] == true) ? 'featured' : '',
        createdAt: data['createdAt'] as Timestamp?,
      );
    }).toList();

    return AdminActivityBatch(
      activities: activities,
      lastDocument: pageDocs.isEmpty ? startAfterDocument : pageDocs.last,
      hasMore: snapshot.docs.length > safeLimit,
    );
  }

  Future<AdminActivityBatch> _getProjectIdeaActivityBatch({
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) async {
    final safeLimit = limit < 1 ? 1 : limit;
    final snapshot = await _getActivitySnapshot(
      collection: activitySourceProjectIdeas,
      orderField: 'createdAt',
      limit: safeLimit,
      startAfterDocument: startAfterDocument,
    );
    final pageDocs = _pageDocs(snapshot.docs, safeLimit);
    final ownerNames = await _fetchUserDisplayNames(
      pageDocs
          .map((doc) => (doc.data()['submittedBy'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet(),
    );

    final activities = pageDocs.map((doc) {
      final data = doc.data();
      final ownerId = (data['submittedBy'] ?? '').toString();
      final ownerName = (data['submittedByName'] ?? '').toString().trim();
      return AdminActivityModel(
        id: 'project_idea_${doc.id}',
        type: 'project_idea',
        relatedId: doc.id,
        relatedCollection: activitySourceProjectIdeas,
        title: (data['title'] ?? 'Untitled project idea').toString(),
        description: 'New project idea submitted for review',
        actorId: ownerId,
        actorName: ownerName.isNotEmpty
            ? ownerName
            : (ownerNames[ownerId] ?? 'Student'),
        status: (data['status'] ?? '').toString(),
        createdAt: data['createdAt'] as Timestamp?,
      );
    }).toList();

    return AdminActivityBatch(
      activities: activities,
      lastDocument: pageDocs.isEmpty ? startAfterDocument : pageDocs.last,
      hasMore: snapshot.docs.length > safeLimit,
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => UserModel.fromMap({
            ...doc.data(),
            'uid': (doc.data()['uid'] ?? doc.id).toString(),
          }),
        )
        .toList();
  }

  Future<UserModel?> getUserById(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(normalizedUid).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }

    return UserModel.fromMap({
      ...data,
      'uid': (data['uid'] ?? doc.id).toString(),
    });
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
    });
  }

  Future<void> updateCompanyApprovalStatus(String uid, String status) async {
    final normalizedStatus = _normalizeCompanyApprovalStatus(status);
    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Company not found');
    }

    final previousStatus = _normalizeCompanyApprovalStatus(
      snapshot.data()?['approvalStatus'],
    );

    if (previousStatus == normalizedStatus) {
      return;
    }

    await docRef.update({'approvalStatus': normalizedStatus});

    if (normalizedStatus == 'approved' || normalizedStatus == 'rejected') {
      await _notificationWorker.notifyCompanyApprovalStatusChanged(uid);
    }
  }

  Future<List<ProjectIdeaModel>> getAllProjectIdeas() async {
    final snapshot = await _firestore
        .collection('projectIdeas')
        .orderBy('createdAt', descending: true)
        .get();

    final ownerNames = await _fetchUserDisplayNames(
      snapshot.docs
          .map((doc) => (doc.data()['submittedBy'] ?? '').toString())
          .where((uid) => uid.isNotEmpty)
          .toSet(),
    );

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final ownerId = (data['submittedBy'] ?? '').toString();
      return ProjectIdeaModel.fromMap({
        ...data,
        'id': doc.id,
        'submittedByName':
            (data['submittedByName'] ?? '').toString().trim().isNotEmpty
            ? data['submittedByName']
            : (ownerNames[ownerId] ?? ''),
      });
    }).toList();
  }

  Future<List<AdminApplicationItemModel>> getAllApplications() async {
    final snapshot = await _firestore
        .collection('applications')
        .orderBy('appliedAt', descending: true)
        .get();

    final opportunityInfo = await _fetchOpportunityInfo(
      snapshot.docs
          .map((doc) => (doc.data()['opportunityId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet(),
    );

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final opportunityMeta =
          opportunityInfo[(data['opportunityId'] ?? '').toString()];

      return AdminApplicationItemModel(
        application: ApplicationModel.fromMap({...data, 'id': doc.id}),
        opportunityTitle: (opportunityMeta?['title'] ?? '').toString(),
        companyName: (opportunityMeta?['companyName'] ?? '').toString(),
        companyId: (opportunityMeta?['companyId'] ?? '').toString(),
        opportunityCreatedBy: (opportunityMeta?['createdBy'] ?? '').toString(),
        opportunityCreatedByRole: (opportunityMeta?['createdByRole'] ?? '')
            .toString(),
        opportunityCreatedAt: opportunityMeta?['createdAt'] as Timestamp?,
      );
    }).toList();
  }

  Future<void> updateAdminApplicationStatus({
    required String appId,
    required String status,
    required String adminId,
  }) async {
    final normalizedAdminId = adminId.trim();
    if (normalizedAdminId.isEmpty) {
      throw Exception('Admin account is required to update applications');
    }

    final appRef = _firestore.collection('applications').doc(appId);
    final appDoc = await appRef.get();
    if (!appDoc.exists) {
      throw Exception('Application not found');
    }

    final appData = appDoc.data() ?? const <String, dynamic>{};
    final opportunityId = (appData['opportunityId'] ?? '').toString().trim();
    if (opportunityId.isEmpty) {
      throw Exception('Application is not linked to an opportunity');
    }

    final opportunityDoc = await _firestore
        .collection('opportunities')
        .doc(opportunityId)
        .get();
    final opportunityData = opportunityDoc.data();
    final opportunityOwnerId = (opportunityData?['companyId'] ?? '')
        .toString()
        .trim();
    final opportunityRole = (opportunityData?['createdByRole'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (!opportunityDoc.exists ||
        opportunityOwnerId != normalizedAdminId ||
        opportunityRole != 'admin') {
      throw Exception(
        'Admins can only update applications for their own admin-posted opportunities',
      );
    }

    final currentStatus = ApplicationStatus.parse(appData['status']);
    final nextStatus = ApplicationStatus.parse(status);
    if (currentStatus == nextStatus) {
      return;
    }

    await appRef.update({'status': nextStatus});

    if (ApplicationStatus.shouldNotifyTransition(currentStatus, nextStatus)) {
      await _notificationWorker.notifyApplicationStatusChanged(appId);
    }
  }

  Future<bool> updateProjectIdeaStatus(String id, String status) async {
    final ideaRef = _firestore.collection('projectIdeas').doc(id);
    var didUpdate = false;
    var shouldNotify = false;

    await _firestore.runTransaction((transaction) async {
      final ideaDoc = await transaction.get(ideaRef);
      if (!ideaDoc.exists) {
        return;
      }

      final currentStatus = (ideaDoc.data()?['status'] ?? '').toString();
      if (currentStatus == status) {
        return;
      }

      transaction.update(ideaRef, {'status': status});
      didUpdate = true;
      shouldNotify =
          currentStatus == 'pending' &&
          (status == 'approved' || status == 'rejected');
    });

    if (shouldNotify) {
      await _notificationWorker.notifyProjectIdeaStatusChanged(id);
    }

    return didUpdate;
  }

  Future<ProjectIdeaModel> setProjectIdeaHidden(
    String id,
    bool isHidden,
  ) async {
    final docRef = _firestore.collection('projectIdeas').doc(id);
    await docRef.update({
      'isHidden': isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    return ProjectIdeaModel.fromMap({...?snapshot.data(), 'id': docRef.id});
  }

  Future<ProjectIdeaModel> createAdminProjectIdea(
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('projectIdeas').doc();
    final nextData = _normalizeProjectIdeaPayload(data, isCreate: true);
    nextData['id'] = docRef.id;
    nextData['createdAt'] = FieldValue.serverTimestamp();
    nextData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(nextData);

    final snapshot = await docRef.get();
    return ProjectIdeaModel.fromMap({...?snapshot.data(), 'id': docRef.id});
  }

  Future<ProjectIdeaModel> updateAdminProjectIdea(
    String id,
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('projectIdeas').doc(id);
    final nextData = _normalizeProjectIdeaPayload(data, isCreate: false);
    nextData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.update(nextData);

    final snapshot = await docRef.get();
    return ProjectIdeaModel.fromMap({...?snapshot.data(), 'id': docRef.id});
  }

  Future<void> deleteProjectIdea(String id) async {
    await _firestore.collection('projectIdeas').doc(id).delete();
  }

  Future<Map<String, dynamic>> createAdminOpportunity(
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('opportunities').doc();
    final nextData = CompanyService.normalizeOpportunityPayload(
      data,
      isCreate: true,
    );
    nextData['id'] = docRef.id;
    if (CompanyService.shouldForceClosedForExpiredDeadline(nextData)) {
      nextData['status'] = 'closed';
    }
    nextData['createdAt'] = FieldValue.serverTimestamp();
    nextData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(nextData);

    if (CompanyService.shouldNotifyStudentsAboutOpportunity(nextData)) {
      await _notificationWorker.notifyOpportunityCreated(docRef.id);
    }

    final snapshot = await docRef.get();
    return {...?snapshot.data(), 'id': docRef.id};
  }

  Future<Map<String, dynamic>> updateAdminOpportunity(
    String id,
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('opportunities').doc(id);
    final currentSnapshot = await docRef.get();
    final currentData = currentSnapshot.data() ?? const <String, dynamic>{};
    final nextData = CompanyService.normalizeOpportunityPayload(
      data,
      isCreate: false,
    );
    final mergedData = <String, dynamic>{...currentData, ...nextData};
    if (CompanyService.shouldForceClosedForExpiredDeadline({
      ...mergedData,
      'id': id,
    })) {
      nextData['status'] = 'closed';
      mergedData['status'] = 'closed';
    }
    nextData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.update(nextData);

    if (CompanyService.shouldNotifyStudentsAboutOpportunity(mergedData)) {
      await _notificationWorker.notifyOpportunityCreated(id);
    }

    final snapshot = await docRef.get();
    return {...?snapshot.data(), 'id': docRef.id};
  }

  Future<void> deleteOpportunity(String id) async {
    await _firestore.collection('opportunities').doc(id).delete();
  }

  Future<Map<String, dynamic>> setOpportunityHidden(
    String id,
    bool isHidden,
  ) async {
    final docRef = _firestore.collection('opportunities').doc(id);
    await docRef.update({
      'isHidden': isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    return {...?snapshot.data(), 'id': docRef.id};
  }

  Future<Map<String, dynamic>> createScholarship(
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('scholarships').doc();
    final nextData = _normalizeScholarshipPayload(data, isCreate: true);
    nextData['id'] = docRef.id;
    nextData['createdAt'] = FieldValue.serverTimestamp();

    await docRef.set(nextData);
    await _notificationWorker.notifyScholarshipCreated(docRef.id);

    final snapshot = await docRef.get();
    return {...?snapshot.data(), 'id': docRef.id};
  }

  Future<Map<String, dynamic>> updateScholarship(
    String id,
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('scholarships').doc(id);
    final nextData = _normalizeScholarshipPayload(data, isCreate: false);
    nextData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.update(nextData);

    final snapshot = await docRef.get();
    return {...?snapshot.data(), 'id': docRef.id};
  }

  Future<void> deleteScholarship(String id) async {
    await _firestore.collection('scholarships').doc(id).delete();
  }

  Future<Map<String, dynamic>> setScholarshipHidden(
    String id,
    bool isHidden,
  ) async {
    final docRef = _firestore.collection('scholarships').doc(id);
    await docRef.update({
      'isHidden': isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    return {...?snapshot.data(), 'id': docRef.id};
  }

  Future<List<Map<String, dynamic>>> getAllOpportunities() async {
    await _expireDeadlinesBestEffort();

    final snapshot = await _firestore
        .collection('opportunities')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<void> _expireDeadlinesBestEffort() async {
    try {
      await _workerApi.post('/api/deadlines/expire');
    } catch (_) {
      // Admin UI still uses effective status while backend reconciliation catches up.
    }
  }

  Future<List<Map<String, dynamic>>> getAllScholarships() async {
    final snapshot = await _firestore
        .collection('scholarships')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<TrainingModel>> getAllTrainings() async {
    final snapshot = await _firestore
        .collection('trainings')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TrainingModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<TrainingModel> setTrainingHidden(String id, bool isHidden) async {
    final docRef = _firestore.collection('trainings').doc(id);
    await docRef.update({'isHidden': isHidden});

    final snapshot = await docRef.get();
    return TrainingModel.fromMap({...?snapshot.data(), 'id': docRef.id});
  }

  Future<Map<String, String>> _fetchUserDisplayNames(
    Set<String> userIds,
  ) async {
    if (userIds.isEmpty) {
      return {};
    }

    final results = await Future.wait(
      userIds.map((uid) async {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          return MapEntry(uid, '');
        }

        final data = doc.data() ?? {};
        return MapEntry(
          uid,
          (data['fullName'] ?? data['companyName'] ?? data['email'] ?? '')
              .toString(),
        );
      }),
    );

    return Map<String, String>.fromEntries(results);
  }

  Future<Map<String, dynamic>?> _getDocumentData(
    String collection,
    String id,
  ) async {
    final normalizedCollection = collection.trim();
    final normalizedId = id.trim();
    if (normalizedCollection.isEmpty || normalizedId.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection(normalizedCollection)
        .doc(normalizedId)
        .get();
    if (!snapshot.exists) {
      return null;
    }

    return {...?snapshot.data(), 'id': snapshot.id};
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getActivitySnapshot({
    required String collection,
    required String orderField,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDocument,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(collection)
        .orderBy(orderField, descending: true)
        .limit(limit + 1);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    return query.get();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _pageDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int limit,
  ) {
    if (docs.length <= limit) {
      return docs;
    }

    return docs.take(limit).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchOpportunityInfo(
    Set<String> opportunityIds,
  ) async {
    if (opportunityIds.isEmpty) {
      return {};
    }

    final results = await Future.wait(
      opportunityIds.map((opportunityId) async {
        final doc = await _firestore
            .collection('opportunities')
            .doc(opportunityId)
            .get();
        return MapEntry(
          opportunityId,
          doc.data() == null
              ? <String, dynamic>{}
              : <String, dynamic>{...doc.data()!, 'id': doc.id},
        );
      }),
    );

    return Map<String, Map<String, dynamic>>.fromEntries(results);
  }

  int _compareByTimestampDesc(AdminActivityModel a, AdminActivityModel b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null && bTime == null) {
      return 0;
    }
    if (aTime == null) {
      return 1;
    }
    if (bTime == null) {
      return -1;
    }
    return bTime.compareTo(aTime);
  }

  Map<String, dynamic> _normalizeProjectIdeaPayload(
    Map<String, dynamic> data, {
    required bool isCreate,
  }) {
    final nextData = Map<String, dynamic>.from(data);

    for (final field in const [
      'title',
      'description',
      'domain',
      'level',
      'tools',
      'originalLanguage',
      'tagline',
      'shortDescription',
      'category',
      'stage',
      'targetAudience',
      'problemStatement',
      'solution',
      'resourcesNeeded',
      'benefits',
      'imageUrl',
      'attachmentUrl',
      'submittedBy',
      'submittedByName',
      'authorAvatar',
      'authorPhotoType',
      'authorAvatarId',
    ]) {
      if (!nextData.containsKey(field)) {
        continue;
      }
      nextData[field] = (nextData[field] ?? '').toString().trim();
    }

    if (nextData.containsKey('tags') || isCreate) {
      nextData['tags'] = _stringList(nextData['tags']);
    }

    if (nextData.containsKey('skillsNeeded') || isCreate) {
      nextData['skillsNeeded'] = _stringList(nextData['skillsNeeded']);
    }

    if (nextData.containsKey('teamNeeded') || isCreate) {
      nextData['teamNeeded'] = _stringList(nextData['teamNeeded']);
    }

    if (nextData.containsKey('isPublic') || isCreate) {
      nextData['isPublic'] = nextData['isPublic'] != false;
    }

    if (nextData.containsKey('isHidden')) {
      nextData['isHidden'] = nextData['isHidden'] == true;
    }

    if (nextData.containsKey('status') || isCreate) {
      nextData['status'] = _normalizeProjectIdeaStatus(nextData['status']);
    }

    return nextData;
  }

  Map<String, dynamic> _normalizeScholarshipPayload(
    Map<String, dynamic> data, {
    required bool isCreate,
  }) {
    final nextData = Map<String, dynamic>.from(data);

    for (final field in const [
      'title',
      'description',
      'provider',
      'eligibility',
      'originalLanguage',
      'deadline',
      'link',
      'createdBy',
      'createdByRole',
      'country',
      'city',
      'location',
      'imageUrl',
      'fundingType',
      'category',
      'level',
    ]) {
      if (!nextData.containsKey(field)) {
        continue;
      }
      nextData[field] = (nextData[field] ?? '').toString().trim();
    }

    if (nextData.containsKey('tags') || isCreate) {
      nextData['tags'] = _stringList(nextData['tags']);
    }

    if (nextData.containsKey('eligibilityItems') || isCreate) {
      final items = OpportunityMetadata.stringListFromValue(
        nextData['eligibilityItems'],
        maxItems: 12,
      );
      nextData['eligibilityItems'] = items.isNotEmpty
          ? items
          : OpportunityMetadata.stringListFromValue(
              nextData['eligibility'],
              maxItems: 12,
            );
    }

    if (nextData.containsKey('featured') || isCreate) {
      nextData['featured'] = nextData['featured'] == true;
    }

    if (nextData.containsKey('isHidden')) {
      nextData['isHidden'] = nextData['isHidden'] == true;
    }

    if (nextData.containsKey('amount') || isCreate) {
      nextData['amount'] = _parseAmount(nextData['amount']);
    }

    return nextData;
  }

  String _normalizeCompanyApprovalStatus(Object? rawStatus) {
    final normalized = (rawStatus ?? '').toString().trim().toLowerCase();
    if (normalized == 'pending' ||
        normalized == 'approved' ||
        normalized == 'rejected') {
      return normalized;
    }

    return 'approved';
  }

  String _normalizeProjectIdeaStatus(Object? rawStatus) {
    final normalized = (rawStatus ?? '').toString().trim().toLowerCase();
    if (normalized == 'pending' ||
        normalized == 'approved' ||
        normalized == 'rejected') {
      return normalized;
    }

    return 'approved';
  }

  String _resolveOpportunityTitle(Map<String, dynamic> data) {
    for (final key in const ['title', 'position', 'role', 'name']) {
      final value = _cleanLabel(data[key]);
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String _cleanLabel(Object? rawValue) {
    return (rawValue ?? '').toString().trim();
  }

  Map<String, dynamic>? _buildRankedOpportunityItem({
    required String id,
    required int count,
    required Map<String, String> liveTitles,
    required Map<String, String> liveTypes,
    required Map<String, String> savedTitles,
    required Map<String, String> savedTypes,
  }) {
    final resolvedTitle = liveTitles[id] ?? savedTitles[id] ?? '';
    if (resolvedTitle.trim().isEmpty) {
      return null;
    }

    return {
      'id': id,
      'title': resolvedTitle,
      'type': liveTypes[id] ?? savedTypes[id] ?? OpportunityType.job,
      'count': count,
    };
  }

  List<String> _stringList(Object? rawValue) {
    if (rawValue is Iterable) {
      return rawValue
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    final value = (rawValue ?? '').toString();
    return value
        .replaceAll('\n', ',')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  num _parseAmount(Object? rawValue) {
    if (rawValue is num) {
      return rawValue;
    }

    final normalized = (rawValue ?? '')
        .toString()
        .replaceAll(RegExp(r'[^0-9.\-]'), '')
        .trim();

    return num.tryParse(normalized) ?? 0;
  }
}
