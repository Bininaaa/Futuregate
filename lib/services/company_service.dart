import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';
import '../models/application_model.dart';
import '../models/cv_model.dart';
import '../utils/application_status.dart';
import '../utils/opportunity_metadata.dart';
import '../utils/opportunity_type.dart';
import 'notification_worker_service.dart';
import 'storage_service.dart';
import 'worker_api_service.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWorkerService _notificationWorker =
      NotificationWorkerService();
  final WorkerApiService _workerApi = WorkerApiService();
  final StorageService _storageService = StorageService();

  Future<List<OpportunityModel>> getCompanyOpportunities(
    String companyId,
  ) async {
    await _expireDeadlinesBestEffort();

    final snapshot = await _firestore
        .collection('opportunities')
        .where('companyId', isEqualTo: companyId)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return OpportunityModel.fromMap(data);
    }).toList();

    list.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return list;
  }

  Future<void> createOpportunity(Map<String, dynamic> data) async {
    final docRef = _firestore.collection('opportunities').doc();
    final docData = normalizeOpportunityPayload(data, isCreate: true);
    docData['id'] = docRef.id;
    if (shouldForceClosedForExpiredDeadline(docData)) {
      docData['status'] = 'closed';
    }
    docData['createdAt'] = FieldValue.serverTimestamp();
    docData['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(docData);
    if (shouldNotifyStudentsAboutOpportunity(docData)) {
      await _notificationWorker.notifyOpportunityCreated(docRef.id);
    }
  }

  Future<void> updateOpportunity(
    String oppId,
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection('opportunities').doc(oppId);
    final currentSnapshot = await docRef.get();
    final currentData = currentSnapshot.data() ?? const <String, dynamic>{};
    final nextData = normalizeOpportunityPayload(data, isCreate: false);
    final mergedData = <String, dynamic>{...currentData, ...nextData};
    if (shouldForceClosedForExpiredDeadline({...mergedData, 'id': oppId})) {
      nextData['status'] = 'closed';
      mergedData['status'] = 'closed';
    }
    nextData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.update(nextData);

    if (shouldNotifyStudentsAboutOpportunity(mergedData)) {
      await _notificationWorker.notifyOpportunityCreated(oppId);
    }
  }

  Future<bool> deleteOpportunity(String oppId) async {
    final result = await _workerApi.delete(
      '/api/company/opportunities/${Uri.encodeComponent(oppId)}',
    );
    return result['closedInsteadOfDeleted'] == true;
  }

  Future<List<ApplicationModel>> getCompanyApplications(
    String companyId,
  ) async {
    final snapshot = await _firestore
        .collection('applications')
        .where('companyId', isEqualTo: companyId)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ApplicationModel.fromMap(data);
    }).toList();

    list.sort((a, b) {
      final aTime = a.appliedAt;
      final bTime = b.appliedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return list;
  }

  Future<void> updateApplicationStatus({
    required String appId,
    required String status,
  }) async {
    final appDoc = await _firestore.collection('applications').doc(appId).get();
    if (!appDoc.exists) return;

    final currentStatus = ApplicationStatus.parse(appDoc.data()?['status']);
    final nextStatus = ApplicationStatus.parse(status);

    if (currentStatus == nextStatus) {
      return;
    }

    await _firestore.collection('applications').doc(appId).update({
      'status': nextStatus,
    });

    if (ApplicationStatus.shouldNotifyTransition(currentStatus, nextStatus)) {
      await _notificationWorker.notifyApplicationStatusChanged(appId);
    }
  }

  Future<CvModel?> getApplicationCv(String applicationId) async {
    final result = await _workerApi.get(
      '/api/applications/${Uri.encodeComponent(applicationId)}/cv',
    );

    final payload = result['cv'];
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    return CvModel.fromMap(_normalizeCvPayload(payload));
  }

  Future<Map<String, dynamic>> getDashboardStats(String companyId) async {
    final opps = await getCompanyOpportunities(companyId);
    final apps = await getCompanyApplications(companyId);

    int pendingCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;

    for (final app in apps) {
      switch (ApplicationStatus.parse(app.status)) {
        case ApplicationStatus.pending:
          pendingCount++;
          break;
        case ApplicationStatus.accepted:
          approvedCount++;
          break;
        case ApplicationStatus.rejected:
          rejectedCount++;
          break;
      }
    }

    return {
      'totalOpportunities': opps.length,
      'totalApplications': apps.length,
      'pendingApplications': pendingCount,
      'approvedApplications': approvedCount,
      'acceptedApplications': approvedCount,
      'rejectedApplications': rejectedCount,
      'openOpportunities': opps
          .where((o) => o.effectiveStatus() == 'open')
          .length,
      'closedOpportunities': opps
          .where((o) => o.effectiveStatus() == 'closed')
          .length,
    };
  }

  Future<OpportunityModel?> getOpportunityById(String oppId) async {
    final doc = await _firestore.collection('opportunities').doc(oppId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return OpportunityModel.fromMap(data);
  }

  Future<Map<String, dynamic>?> getCompanyProfile(String companyId) async {
    final doc = await _firestore.collection('users').doc(companyId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> _expireDeadlinesBestEffort() async {
    try {
      await _workerApi.post('/api/deadlines/expire');
    } catch (_) {
      // The UI still treats expired opportunities as closed immediately.
    }
  }

  Future<String> uploadAndSetCompanyLogo({
    required String uid,
    required String fileName,
    String filePath = '',
    Uint8List? fileBytes,
  }) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final existingData = doc.data() ?? const <String, dynamic>{};
    final previousManagedLogo = _extractManagedLogoUrl(existingData['logo']);

    final result = await _storageService.uploadProfilePhoto(
      userId: uid,
      fileName: fileName,
      filePath: filePath,
      fileBytes: fileBytes,
    );

    await _firestore.collection('users').doc(uid).update({
      'logo': result.fileUrl,
      'photoType': 'upload',
      'avatarId': null,
    });

    await _syncCompanyLogoToOpportunities(uid, result.fileUrl);

    if (previousManagedLogo.isNotEmpty &&
        previousManagedLogo != result.fileUrl) {
      try {
        await _storageService.deleteFileByPath(previousManagedLogo);
      } catch (_) {
        // Ignore cleanup failures to avoid blocking a successful save.
      }
    }

    return result.fileUrl;
  }

  Future<void> removeCompanyLogo(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final existingData = doc.data() ?? const <String, dynamic>{};
    final previousManagedLogo = _extractManagedLogoUrl(existingData['logo']);

    await _firestore.collection('users').doc(uid).update({
      'logo': '',
      'photoType': null,
      'avatarId': null,
    });

    await _syncCompanyLogoToOpportunities(uid, '');

    if (previousManagedLogo.isNotEmpty) {
      try {
        await _storageService.deleteFileByPath(previousManagedLogo);
      } catch (_) {
        // Ignore cleanup failures after a successful remove.
      }
    }
  }

  Future<void> updateCompanyProfile(
    String uid,
    Map<String, dynamic> data, {
    String commercialRegisterFilePath = '',
    String commercialRegisterFileName = '',
    Uint8List? commercialRegisterBytes,
  }) async {
    final nextData = Map<String, dynamic>.from(data);
    StoredFileUploadResult? uploadedCommercialRegister;
    String previousStoragePath = '';

    if (commercialRegisterFileName.trim().isNotEmpty) {
      final existingProfile = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      final existingData = existingProfile.data() ?? const <String, dynamic>{};
      previousStoragePath =
          (existingData['commercialRegisterStoragePath'] ??
                  existingData['commercialRegisterUrl'] ??
                  '')
              .toString();

      uploadedCommercialRegister = await _storageService
          .uploadCommercialRegister(
            userId: uid,
            filePath: commercialRegisterFilePath,
            fileName: commercialRegisterFileName,
            fileBytes: commercialRegisterBytes,
          );

      nextData.addAll({
        'commercialRegisterUrl': uploadedCommercialRegister.fileUrl,
        'commercialRegisterFileName': uploadedCommercialRegister.fileName,
        'commercialRegisterMimeType': uploadedCommercialRegister.mimeType,
        'commercialRegisterStoragePath': uploadedCommercialRegister.objectKey,
        'commercialRegisterUploadedAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      await _firestore.collection('users').doc(uid).update(nextData);
    } catch (e) {
      if (uploadedCommercialRegister != null &&
          uploadedCommercialRegister.storagePath.trim().isNotEmpty) {
        try {
          await _storageService.deleteFileByPath(
            uploadedCommercialRegister.storagePath,
          );
        } catch (_) {
          // Ignore cleanup failures when profile save fails.
        }
      }
      rethrow;
    }

    if (uploadedCommercialRegister != null &&
        previousStoragePath.trim().isNotEmpty &&
        previousStoragePath != uploadedCommercialRegister.objectKey) {
      try {
        await _storageService.deleteFileByPath(previousStoragePath);
      } catch (_) {
        // Ignore cleanup failures to avoid blocking successful updates.
      }
    }
  }

  Map<String, dynamic> _normalizeCvPayload(Map<String, dynamic> payload) {
    final normalized = Map<String, dynamic>.from(payload);

    for (final field in const ['createdAt', 'updatedAt']) {
      normalized[field] = _parseTimestamp(normalized[field]);
    }

    return normalized;
  }

  Timestamp? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return Timestamp.fromDate(parsed);
      }
    }

    return null;
  }

  Future<void> _syncCompanyLogoToOpportunities(
    String companyId,
    String companyLogo,
  ) async {
    final snapshot = await _firestore
        .collection('opportunities')
        .where('companyId', isEqualTo: companyId)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'companyLogo': companyLogo});
    }
    await batch.commit();
  }

  String _extractManagedLogoUrl(Object? rawUrl) {
    final url = (rawUrl ?? '').toString().trim();
    if (url.isEmpty || !url.contains('/file/')) {
      return '';
    }
    return url;
  }

  static bool shouldNotifyStudentsAboutOpportunity(Map<String, dynamic> data) {
    final type = OpportunityType.parse(data['type']?.toString());
    final status = normalizeOpportunityStatus(data['status']);

    return OpportunityType.supportsStudentPostNotification(type) &&
        status == 'open';
  }

  static String normalizeOpportunityStatus(Object? rawStatus) {
    final normalized = (rawStatus ?? '').toString().trim().toLowerCase();
    return normalized == 'closed' ? 'closed' : 'open';
  }

  static bool shouldForceClosedForExpiredDeadline(
    Map<String, dynamic> data, {
    DateTime? now,
  }) {
    if (normalizeOpportunityStatus(data['status']) != 'open') {
      return false;
    }

    return OpportunityModel.fromMap(data).isDeadlineExpired(now: now);
  }

  static Map<String, dynamic> normalizeOpportunityPayload(
    Map<String, dynamic> data, {
    required bool isCreate,
  }) {
    final nextData = Map<String, dynamic>.from(data);

    for (final field in const [
      'title',
      'description',
      'location',
      'requirements',
      'companyId',
      'companyName',
      'companyLogo',
      'createdBy',
      'createdByRole',
      'deadline',
      'fundingNote',
    ]) {
      if (!nextData.containsKey(field)) {
        continue;
      }

      nextData[field] = (nextData[field] ?? '').toString().trim();
    }

    if (nextData.containsKey('type') || isCreate) {
      nextData['type'] = OpportunityType.parse(nextData['type']?.toString());
    }

    if (nextData.containsKey('status') || isCreate) {
      nextData['status'] = normalizeOpportunityStatus(nextData['status']);
    }

    if (nextData.containsKey('requirementItems') || isCreate) {
      nextData['requirementItems'] =
          OpportunityMetadata.extractRequirementItems(
            nextData,
            fallbackText: nextData['requirements']?.toString(),
            maxItems: 12,
          );
    }

    if (nextData.containsKey('salaryMin')) {
      nextData['salaryMin'] = OpportunityMetadata.parseNullableNum(
        nextData['salaryMin'],
      );
    }

    if (nextData.containsKey('salaryMax')) {
      nextData['salaryMax'] = OpportunityMetadata.parseNullableNum(
        nextData['salaryMax'],
      );
    }

    if (nextData.containsKey('salaryCurrency')) {
      nextData['salaryCurrency'] = OpportunityMetadata.normalizeCurrency(
        nextData['salaryCurrency']?.toString(),
      );
    }

    if (nextData.containsKey('salaryPeriod')) {
      nextData['salaryPeriod'] = OpportunityMetadata.normalizeSalaryPeriod(
        nextData['salaryPeriod']?.toString(),
      );
    }

    if (nextData.containsKey('compensationText')) {
      nextData['compensationText'] = OpportunityMetadata.sanitizeText(
        nextData['compensationText']?.toString(),
      );
    }

    if (nextData.containsKey('fundingAmount')) {
      nextData['fundingAmount'] = OpportunityMetadata.parseNullableNum(
        nextData['fundingAmount'],
      );
    }

    if (nextData.containsKey('fundingCurrency')) {
      nextData['fundingCurrency'] = OpportunityMetadata.normalizeCurrency(
        nextData['fundingCurrency']?.toString(),
      );
    }

    if (nextData.containsKey('fundingNote')) {
      nextData['fundingNote'] = OpportunityMetadata.sanitizeText(
        nextData['fundingNote']?.toString(),
      );
    }

    if (nextData.containsKey('employmentType')) {
      nextData['employmentType'] = OpportunityMetadata.normalizeEmploymentType(
        nextData['employmentType']?.toString(),
      );
    }

    if (nextData.containsKey('workMode')) {
      nextData['workMode'] = OpportunityMetadata.normalizeWorkMode(
        nextData['workMode']?.toString(),
      );
    }

    if (nextData.containsKey('isPaid')) {
      nextData['isPaid'] = OpportunityMetadata.parseNullableBool(
        nextData['isPaid'],
      );
    }

    if (nextData.containsKey('duration')) {
      nextData['duration'] = OpportunityMetadata.normalizeDuration(
        nextData['duration']?.toString(),
      );
    }

    final normalizedType = OpportunityType.parse(nextData['type']?.toString());
    if (normalizedType == OpportunityType.sponsoring) {
      nextData['salaryMin'] = null;
      nextData['salaryMax'] = null;
      nextData['salaryCurrency'] = null;
      nextData['salaryPeriod'] = null;
      nextData['compensationText'] = null;
      nextData['employmentType'] = null;
      nextData['workMode'] = null;
      nextData['isPaid'] = null;
      nextData['duration'] = null;
      if ((nextData['fundingCurrency'] ?? '').toString().trim().isEmpty &&
          nextData['fundingAmount'] != null) {
        nextData['fundingCurrency'] =
            OpportunityMetadata.supportedCurrencies.first;
      }
    } else if (nextData.containsKey('fundingAmount') ||
        nextData.containsKey('fundingCurrency') ||
        nextData.containsKey('fundingNote') ||
        isCreate) {
      nextData['fundingAmount'] = null;
      nextData['fundingCurrency'] = null;
      nextData['fundingNote'] = null;
    }

    final shouldNormalizeDeadline =
        isCreate ||
        nextData.containsKey('applicationDeadline') ||
        nextData.containsKey('deadline');
    if (shouldNormalizeDeadline) {
      final rawDeadline = nextData.containsKey('applicationDeadline')
          ? nextData['applicationDeadline']
          : nextData['deadline'];
      final parsedDeadline = OpportunityMetadata.parseDateTimeLike(rawDeadline);

      nextData['applicationDeadline'] = parsedDeadline == null
          ? null
          : Timestamp.fromDate(
              OpportunityMetadata.normalizeDateToEndOfDay(parsedDeadline),
            );
      nextData['deadline'] = parsedDeadline == null
          ? ((nextData['deadline'] ?? '').toString().trim())
          : OpportunityMetadata.formatDateForStorage(parsedDeadline);
    }

    if (nextData['earlyAccessRequested'] == true &&
        (nextData['earlyAccessStatus'] ?? '')
                .toString()
                .trim()
                .toLowerCase() ==
            'pending' &&
        !nextData.containsKey('requestedEarlyAccessAt')) {
      nextData['requestedEarlyAccessAt'] = FieldValue.serverTimestamp();
    }

    return nextData;
  }
}
