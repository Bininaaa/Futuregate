import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_worker_service.dart';

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

  Future<ApplicationEligibilityStatus> getEligibility({
    required String studentId,
    required String opportunityId,
  }) async {
    if (studentId.isEmpty) {
      return ApplicationEligibilityStatus.requiresLogin;
    }

    final opportunitySnapshot =
        await _firestore.collection('opportunities').doc(opportunityId).get();

    if (!opportunitySnapshot.exists) {
      return ApplicationEligibilityStatus.unavailable;
    }

    final opportunityData = opportunitySnapshot.data();
    final status = opportunityData?['status'] as String? ?? '';

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
    required String companyId,
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

    final opportunityRef = _firestore.collection('opportunities').doc(opportunityId);
    final applicationRef =
        _firestore.collection('applications').doc('${studentId}_$opportunityId');

    await _firestore.runTransaction((transaction) async {
      final opportunitySnapshot = await transaction.get(opportunityRef);

      if (!opportunitySnapshot.exists) {
        throw Exception('This opportunity is no longer available');
      }

      final opportunityData = opportunitySnapshot.data();
      final status = opportunityData?['status'] as String? ?? '';

      if (status != 'open') {
        throw Exception('This opportunity is closed');
      }

      transaction.set(applicationRef, {
        'id': applicationRef.id,
        'studentId': studentId,
        'studentName': studentName,
        'opportunityId': opportunityId,
        'companyId': companyId,
        'cvId': cvId,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });
    });

    await _notificationWorker.notifyApplicationSubmitted(applicationRef.id);
  }
}
