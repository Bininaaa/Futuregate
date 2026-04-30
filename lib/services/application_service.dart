import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application_model.dart';
import '../models/opportunity_model.dart';
import '../models/student_application_item_model.dart';
import '../models/subscription_model.dart';
import 'notification_worker_service.dart';
import 'cv_service.dart';
import 'subscription_service.dart';
import '../utils/application_status.dart';
import 'interfaces/i_application_service.dart';
import '../utils/crashlytics_logger.dart';

enum ApplicationEligibilityStatus {
  requiresLogin,
  available,
  alreadyApplied,
  closed,
  unavailable,
}

class ApplicationService implements IApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();
  final CvService _cvService = CvService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  Future<int> getApplicationsCount(String studentId) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return 0;
    }

    return (await getSubmittedApplications(normalizedStudentId)).length;
  }

  @override
  Future<List<StudentApplicationItemModel>> getSubmittedApplications(
    String studentId, {
    bool onlyVisibleOpportunities = true,
  }) async {
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
      final opportunity = OpportunityModel.fromMap(data);
      if (!onlyVisibleOpportunities || opportunity.isVisibleToStudents()) {
        opportunitiesById[doc.id] = opportunity;
      }
    }

    return applications
        .where(
          (application) =>
              !onlyVisibleOpportunities ||
              opportunitiesById.containsKey(application.opportunityId.trim()),
        )
        .map(
          (application) => StudentApplicationItemModel(
            application: application,
            opportunity: opportunitiesById[application.opportunityId.trim()],
          ),
        )
        .toList(growable: false);
  }

  @override
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

    if (opportunityData == null) {
      return ApplicationEligibilityStatus.unavailable;
    }

    final opportunity = OpportunityModel.fromMap({
      ...opportunityData,
      'id': opportunitySnapshot.id,
    });

    if (opportunity.isHidden) {
      return ApplicationEligibilityStatus.unavailable;
    }

    if (opportunity.effectiveStatus() != 'open') {
      return ApplicationEligibilityStatus.closed;
    }

    final existingApplication = await _firestore
        .collection('applications')
        .where('studentId', isEqualTo: studentId)
        .where('opportunityId', isEqualTo: opportunityId)
        .limit(1)
        .get();

    if (existingApplication.docs.isNotEmpty) {
      final existingStatus =
          existingApplication.docs.first.data()['status'] as String? ?? '';
      if (ApplicationStatus.parse(existingStatus) !=
          ApplicationStatus.withdrawn) {
        return ApplicationEligibilityStatus.alreadyApplied;
      }
    }

    return ApplicationEligibilityStatus.available;
  }

  @override
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
    final resolvedCompanyId = (opportunityData?['companyId'] ?? '')
        .toString()
        .trim();

    if (opportunityData == null) {
      throw Exception('This opportunity is no longer available');
    }

    final opportunity = OpportunityModel.fromMap({
      ...opportunityData,
      'id': opportunitySnapshot.id,
    });

    if (opportunity.isHidden) {
      throw Exception('This opportunity is no longer available');
    }

    if (opportunity.effectiveStatus() != 'open') {
      throw Exception('This opportunity is closed');
    }

    // Early-access lock: free users cannot apply during the premium window
    if (opportunity.isEarlyAccessActive) {
      final sub = await _subscriptionService.getSubscription(studentId);
      final isPremium = sub?.isActive ?? false;
      if (!isPremium) {
        throw EarlyAccessLockedException(
          'This opportunity is in early access. Upgrade to Premium Pass to apply now.',
          publicVisibleAt: opportunity.publicVisibleAt,
        );
      }
    }

    if (resolvedCompanyId.isEmpty) {
      throw Exception('This opportunity is no longer available');
    }

    // Fetch subscription for priority snapshot (best-effort, don't block apply)
    SubscriptionModel? sub;
    try {
      sub = await _subscriptionService.getSubscription(studentId);
    } catch (_) {}
    final isPremiumAtApply = sub?.isActive ?? false;

    final createData = {
      'id': applicationRef.id,
      'studentId': studentId,
      'studentName': studentName.trim(),
      'opportunityId': opportunityId,
      'companyId': resolvedCompanyId,
      'cvId': resolvedCvId,
      'status': ApplicationStatus.pending,
      'appliedAt': FieldValue.serverTimestamp(),
      'isPremiumAtApply': isPremiumAtApply,
      'priorityApplication': isPremiumAtApply,
      if (isPremiumAtApply && sub != null)
        'subscriptionSnapshot': {
          'plan': sub.plan,
          'status': sub.status,
          'expiresAt': sub.expiresAt,
        },
    };

    try {
      await applicationRef.set(createData);
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

        if (await _tryRestoreWithdrawnApplication(
          applicationRef: applicationRef,
          studentId: studentId,
          studentName: studentName,
          resolvedCompanyId: resolvedCompanyId,
          resolvedCvId: resolvedCvId,
          isPremiumAtApply: isPremiumAtApply,
          sub: sub,
        )) {
          await _notificationWorker.notifyApplicationSubmitted(
            applicationRef.id,
          );
          return;
        }
      }

      recordNonFatal(e, StackTrace.current, context: 'apply_to_opportunity');
      rethrow;
    }

    await _notificationWorker.notifyApplicationSubmitted(applicationRef.id);
  }

  Future<bool> _tryRestoreWithdrawnApplication({
    required DocumentReference<Map<String, dynamic>> applicationRef,
    required String studentId,
    required String studentName,
    required String resolvedCompanyId,
    required String resolvedCvId,
    bool isPremiumAtApply = false,
    SubscriptionModel? sub,
  }) async {
    final applicationSnapshot = await applicationRef.get();
    if (!applicationSnapshot.exists) {
      return false;
    }

    final data = applicationSnapshot.data();
    if ((data?['studentId'] ?? '').toString().trim() != studentId) {
      return false;
    }

    final existingStatus = ApplicationStatus.parse(
      data?['status'] as String? ?? '',
    );
    if (existingStatus != ApplicationStatus.withdrawn) {
      return false;
    }

    final updateData = <String, dynamic>{
      'studentName': studentName.trim(),
      'companyId': resolvedCompanyId,
      'cvId': resolvedCvId,
      'status': ApplicationStatus.pending,
      'appliedAt': FieldValue.serverTimestamp(),
      'withdrawnAt': FieldValue.delete(),
      'hadWithdrawnBefore': true,
      'isPremiumAtApply': isPremiumAtApply,
      'priorityApplication': isPremiumAtApply,
      if (isPremiumAtApply && sub != null)
        'subscriptionSnapshot': {
          'plan': sub.plan,
          'status': sub.status,
          'expiresAt': sub.expiresAt,
        },
    };

    final previousWithdrawnAt = data?['withdrawnAt'];
    if (previousWithdrawnAt is Timestamp) {
      updateData['lastWithdrawnAt'] = previousWithdrawnAt;
    }

    await applicationRef.update(updateData);
    return true;
  }

  @override
  Future<void> withdrawApplication({
    required String studentId,
    required String opportunityId,
  }) async {
    if (studentId.isEmpty || opportunityId.isEmpty) {
      throw Exception('Invalid application reference.');
    }

    final applicationRef = _firestore
        .collection('applications')
        .doc('${studentId}_$opportunityId');

    final snapshot = await applicationRef.get();
    if (!snapshot.exists) {
      throw Exception('Application not found.');
    }

    final currentStatus = ApplicationStatus.parse(
      snapshot.data()?['status'] as String? ?? '',
    );
    if (currentStatus != ApplicationStatus.pending) {
      throw Exception('Only pending applications can be withdrawn.');
    }

    await applicationRef.update({
      'status': ApplicationStatus.withdrawn,
      'withdrawnAt': FieldValue.serverTimestamp(),
    });
  }
}

class EarlyAccessLockedException implements Exception {
  final String message;
  final DateTime? publicVisibleAt;

  const EarlyAccessLockedException(this.message, {this.publicVisibleAt});

  @override
  String toString() => message;
}
