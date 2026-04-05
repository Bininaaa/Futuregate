import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application_model.dart';
import '../models/opportunity_model.dart';
import '../models/student_application_item_model.dart';
import 'notification_worker_service.dart';
import 'cv_service.dart';
import '../utils/application_status.dart';

enum ApplicationEligibilityStatus {
  requiresLogin,
  available,
  alreadyApplied,
  closed,
  unavailable,
}

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();
  final CvService _cvService = CvService();

  Future<int> getApplicationsCount(String studentId) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return 0;
    }

    final snapshot = await _firestore
        .collection('applications')
        .where('studentId', isEqualTo: normalizedStudentId)
        .get();

    return snapshot.docs.length;
  }

  Future<List<StudentApplicationItemModel>> getSubmittedApplications(
    String studentId,
  ) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return const [];
    }

    final snapshot = await _firestore
        .collection('applications')
        .where('studentId', isEqualTo: normalizedStudentId)
        .get();

    final applications =
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = data['id'] ?? doc.id;
          return ApplicationModel.fromMap(data);
        }).toList()..sort((first, second) {
          final firstTime = first.appliedAt?.millisecondsSinceEpoch ?? 0;
          final secondTime = second.appliedAt?.millisecondsSinceEpoch ?? 0;
          return secondTime.compareTo(firstTime);
        });

    final opportunityIds = applications
        .map((application) => application.opportunityId.trim())
        .where((opportunityId) => opportunityId.isNotEmpty)
        .toSet();

    final opportunityDocs = await Future.wait(
      opportunityIds.map(
        (opportunityId) =>
            _firestore.collection('opportunities').doc(opportunityId).get(),
      ),
    );

    final opportunitiesById = <String, OpportunityModel>{};
    for (final doc in opportunityDocs) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        continue;
      }

      data['id'] = doc.id;
      opportunitiesById[doc.id] = OpportunityModel.fromMap(data);
    }

    return applications
        .map(
          (application) => StudentApplicationItemModel(
            application: application,
            opportunity: opportunitiesById[application.opportunityId.trim()],
          ),
        )
        .toList(growable: false);
  }

  Future<ApplicationEligibilityStatus> getEligibility({
    required String studentId,
    required String opportunityId,
  }) async {
    if (studentId.isEmpty) {
      return ApplicationEligibilityStatus.requiresLogin;
    }

    final opportunitySnapshot = await _firestore
        .collection('opportunities')
        .doc(opportunityId)
        .get();

    if (!opportunitySnapshot.exists) {
      return ApplicationEligibilityStatus.unavailable;
    }

    final opportunityData = opportunitySnapshot.data();
    final status = opportunityData?['status'] as String? ?? '';
    final isHidden = opportunityData?['isHidden'] == true;

    if (isHidden) {
      return ApplicationEligibilityStatus.unavailable;
    }

    if (status != 'open') {
      return ApplicationEligibilityStatus.closed;
    }

    final existingApplication = await _firestore
        .collection('applications')
        .where('studentId', isEqualTo: studentId)
        .where('opportunityId', isEqualTo: opportunityId)
        .limit(1)
        .get();

    if (existingApplication.docs.isNotEmpty) {
      return ApplicationEligibilityStatus.alreadyApplied;
    }

    return ApplicationEligibilityStatus.available;
  }

  Future<void> applyToOpportunity({
    required String studentId,
    required String studentName,
    required String opportunityId,
    required String cvId,
  }) async {
    final eligibility = await getEligibility(
      studentId: studentId,
      opportunityId: opportunityId,
    );

    switch (eligibility) {
      case ApplicationEligibilityStatus.requiresLogin:
        throw Exception('You must be logged in to apply');
      case ApplicationEligibilityStatus.alreadyApplied:
        throw Exception('You have already applied to this opportunity');
      case ApplicationEligibilityStatus.closed:
        throw Exception('This opportunity is closed');
      case ApplicationEligibilityStatus.unavailable:
        throw Exception('This opportunity is no longer available');
      case ApplicationEligibilityStatus.available:
        break;
    }

    final requestedCvId = cvId.trim();
    final resolvedCvId = requestedCvId.isEmpty
        ? ''
        : await _cvService.resolveCanonicalCvId(
                studentId: studentId,
                preferredCvId: requestedCvId,
              ) ??
              '';

    if (requestedCvId.isNotEmpty && resolvedCvId.isEmpty) {
      throw Exception(
        'Your CV could not be matched to your account. Please open My CV and try again.',
      );
    }

    final opportunityRef = _firestore
        .collection('opportunities')
        .doc(opportunityId);
    final applicationRef = _firestore
        .collection('applications')
        .doc('${studentId}_$opportunityId');

    final opportunitySnapshot = await opportunityRef.get();
    if (!opportunitySnapshot.exists) {
      throw Exception('This opportunity is no longer available');
    }

    final opportunityData = opportunitySnapshot.data();
    final status = opportunityData?['status'] as String? ?? '';
    final isHidden = opportunityData?['isHidden'] == true;
    final resolvedCompanyId = (opportunityData?['companyId'] ?? '')
        .toString()
        .trim();

    if (isHidden) {
      throw Exception('This opportunity is no longer available');
    }

    if (status != 'open') {
      throw Exception('This opportunity is closed');
    }

    if (resolvedCompanyId.isEmpty) {
      throw Exception('This opportunity is no longer available');
    }

    try {
      await applicationRef.set({
        'id': applicationRef.id,
        'studentId': studentId,
        'studentName': studentName.trim(),
        'opportunityId': opportunityId,
        'companyId': resolvedCompanyId,
        'cvId': resolvedCvId,
        'status': ApplicationStatus.pending,
        'appliedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        final latestEligibility = await getEligibility(
          studentId: studentId,
          opportunityId: opportunityId,
        );

        switch (latestEligibility) {
          case ApplicationEligibilityStatus.alreadyApplied:
            throw Exception('You have already applied to this opportunity');
          case ApplicationEligibilityStatus.closed:
            throw Exception('This opportunity is closed');
          case ApplicationEligibilityStatus.unavailable:
            throw Exception('This opportunity is no longer available');
          case ApplicationEligibilityStatus.requiresLogin:
            throw Exception('You must be logged in to apply');
          case ApplicationEligibilityStatus.available:
            break;
        }
      }

      rethrow;
    }

    await _notificationWorker.notifyApplicationSubmitted(applicationRef.id);
  }
}
