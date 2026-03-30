import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cv_model.dart';
import 'storage_service.dart';

class CvService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Future<CvModel?> getCvByStudentId(String studentId) async {
    final snapshot = await _firestore
        .collection('cvs')
        .where('studentId', isEqualTo: studentId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final preferredDoc = _selectBestCvDoc(snapshot.docs);
    final data = Map<String, dynamic>.from(preferredDoc.data());
    if ((data['id'] ?? '').toString().trim().isEmpty) {
      data['id'] = preferredDoc.id;
    }

    return CvModel.fromMap(data);
  }

  Future<void> saveCv({
    required String studentId,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String summary,
    required List<Map<String, dynamic>> education,
    required List<Map<String, dynamic>> experience,
    required List<String> skills,
    required List<String> languages,
    String templateId = '',
  }) async {
    final existingDoc = await _getExistingCvDoc(studentId);

    if (existingDoc != null) {
      final existingData = existingDoc.data();
      final currentSourceType = (existingData['sourceType'] ?? '') as String;

      await existingDoc.reference.update({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'summary': summary,
        'education': education,
        'experience': experience,
        'skills': skills,
        'languages': languages,
        'templateId': templateId,
        'sourceType': _mergeSourceType(
          currentSourceType: currentSourceType,
          incomingType: 'builder',
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final docRef = _firestore.collection('cvs').doc();

      await docRef.set({
        'id': docRef.id,
        'studentId': studentId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'summary': summary,
        'education': education,
        'experience': experience,
        'skills': skills,
        'languages': languages,
        'sourceType': 'builder',
        'templateId': templateId,
        'primaryCvMode': '',
        ..._emptyUploadedCvData(),
        'exportedPdfUrl': '',
        'exportedPdfPath': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> attachUploadedCv({
    required String studentId,
    required String filePath,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    final existingDoc = await _getExistingCvDoc(studentId);
    final existingData = existingDoc?.data();

    final previousStorageProvider =
        (existingData?['uploadedCvStorageProvider'] ?? '') as String;
    final previousObjectKey =
        (existingData?['uploadedCvObjectKey'] ??
                existingData?['uploadedCvPath'] ??
                '')
            as String;

    final uploadedFile = await _storageService.uploadOriginalCv(
      userId: studentId,
      filePath: filePath,
      fileName: fileName,
      fileBytes: fileBytes,
    );
    final uploadedCvData = _uploadedCvData(
      studentId: studentId,
      uploadedFile: uploadedFile,
    );

    if (existingDoc != null) {
      final currentSourceType = (existingData?['sourceType'] ?? '') as String;

      await existingDoc.reference.update({
        'sourceType': _mergeSourceType(
          currentSourceType: currentSourceType,
          incomingType: 'uploaded',
        ),
        ...uploadedCvData,
        ..._legacyStorageCleanupData(),
        'primaryCvMode': 'uploaded',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final docRef = _firestore.collection('cvs').doc();

      await docRef.set({
        'id': docRef.id,
        'studentId': studentId,
        'fullName': '',
        'email': '',
        'phone': '',
        'address': '',
        'summary': '',
        'education': <Map<String, dynamic>>[],
        'experience': <Map<String, dynamic>>[],
        'skills': <String>[],
        'languages': <String>[],
        'sourceType': 'uploaded',
        'templateId': '',
        'primaryCvMode': 'uploaded',
        ...uploadedCvData,
        'exportedPdfUrl': '',
        'exportedPdfPath': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (previousStorageProvider == 'cloudflare_r2' &&
        previousObjectKey.trim().isNotEmpty &&
        previousObjectKey != uploadedFile.objectKey) {
      try {
        await _storageService.deleteFileByPath(previousObjectKey);
      } catch (_) {
        // Ignore deletion failure to avoid blocking the upload flow.
      }
    }
  }

  Future<void> attachExportedPdf({
    required String studentId,
    required String exportedPdfUrl,
    required String exportedPdfPath,
    required String templateId,
  }) async {
    final existingDoc = await _getExistingCvDoc(studentId);

    if (existingDoc != null) {
      final existingData = existingDoc.data();
      final currentSourceType = (existingData['sourceType'] ?? '') as String;

      await existingDoc.reference.update({
        'sourceType': _mergeSourceType(
          currentSourceType: currentSourceType,
          incomingType: 'builder',
        ),
        'templateId': templateId,
        'exportedPdfUrl': exportedPdfUrl,
        'exportedPdfPath': exportedPdfPath,
        'primaryCvMode': 'builder_pdf',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final docRef = _firestore.collection('cvs').doc();

      await docRef.set({
        'id': docRef.id,
        'studentId': studentId,
        'fullName': '',
        'email': '',
        'phone': '',
        'address': '',
        'summary': '',
        'education': <Map<String, dynamic>>[],
        'experience': <Map<String, dynamic>>[],
        'skills': <String>[],
        'languages': <String>[],
        'sourceType': 'builder',
        'templateId': templateId,
        'primaryCvMode': 'builder_pdf',
        ..._emptyUploadedCvData(),
        'exportedPdfUrl': exportedPdfUrl,
        'exportedPdfPath': exportedPdfPath,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> setPrimaryCvMode({
    required String studentId,
    required String primaryCvMode,
  }) async {
    final existingDoc = await _getExistingCvDoc(studentId);

    if (existingDoc == null) {
      throw Exception('CV not found for this student');
    }

    await existingDoc.reference.update({
      'primaryCvMode': primaryCvMode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getExistingCvDoc(
    String studentId,
  ) async {
    final snapshot = await _firestore
        .collection('cvs')
        .where('studentId', isEqualTo: studentId)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return _selectBestCvDoc(snapshot.docs);
  }

  QueryDocumentSnapshot<Map<String, dynamic>> _selectBestCvDoc(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final rankedDocs = [...docs]..sort(_compareCvDocs);
    return rankedDocs.first;
  }

  int _compareCvDocs(
    QueryDocumentSnapshot<Map<String, dynamic>> left,
    QueryDocumentSnapshot<Map<String, dynamic>> right,
  ) {
    final leftData = left.data();
    final rightData = right.data();

    final availabilityComparison = _documentAvailabilityScore(
      rightData,
    ).compareTo(_documentAvailabilityScore(leftData));
    if (availabilityComparison != 0) {
      return availabilityComparison;
    }

    final updatedAtComparison = _timestampToMillis(
      rightData['updatedAt'],
    ).compareTo(_timestampToMillis(leftData['updatedAt']));
    if (updatedAtComparison != 0) {
      return updatedAtComparison;
    }

    return _timestampToMillis(
      rightData['createdAt'],
    ).compareTo(_timestampToMillis(leftData['createdAt']));
  }

  int _documentAvailabilityScore(Map<String, dynamic> data) {
    var score = 0;

    if (_hasAnyValue([
      data['uploadedCvPath'],
      data['uploadedCvObjectKey'],
      data['uploadedCvUrl'],
    ])) {
      score += 2;
    }

    if (_hasAnyValue([
      data['exportedPdfPath'],
      data['exportedPdfObjectKey'],
      data['exportedPdfUrl'],
    ])) {
      score += 2;
    }

    if ((data['primaryCvMode'] ?? '').toString().trim().isNotEmpty) {
      score += 1;
    }

    return score;
  }

  bool _hasAnyValue(List<Object?> values) {
    return values.any((value) => value?.toString().trim().isNotEmpty ?? false);
  }

  int _timestampToMillis(Object? value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    final parsed = DateTime.tryParse((value ?? '').toString());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String _mergeSourceType({
    required String currentSourceType,
    required String incomingType,
  }) {
    final current = currentSourceType.trim();

    if (current.isEmpty) return incomingType;
    if (current == incomingType) return current;
    if (current == 'hybrid') return 'hybrid';

    if ((current == 'builder' && incomingType == 'uploaded') ||
        (current == 'uploaded' && incomingType == 'builder')) {
      return 'hybrid';
    }

    return incomingType;
  }

  Map<String, dynamic> _emptyUploadedCvData() {
    return {
      'uploadedCvUrl': '',
      'uploadedCvPath': '',
      'uploadedFileName': '',
      'uploadedCvObjectKey': '',
      'uploadedCvUserId': '',
      'uploadedCvBucketName': '',
      'uploadedCvMimeType': '',
      'uploadedCvSizeOriginal': 0,
      'uploadedCvFileType': '',
      'uploadedCvCreatedAt': null,
      'uploadedCvStorageProvider': '',
    };
  }

  Map<String, dynamic> _uploadedCvData({
    required String studentId,
    required UploadedCvFile uploadedFile,
  }) {
    return {
      'uploadedCvUrl': uploadedFile.fileUrl,
      'uploadedCvPath': uploadedFile.objectKey,
      'uploadedFileName': uploadedFile.fileName,
      'uploadedCvObjectKey': uploadedFile.objectKey,
      'uploadedCvUserId': studentId,
      'uploadedCvBucketName': uploadedFile.bucketName,
      'uploadedCvMimeType': uploadedFile.mimeType,
      'uploadedCvSizeOriginal': uploadedFile.sizeOriginal,
      'uploadedCvFileType': uploadedFile.fileType,
      'uploadedCvCreatedAt': FieldValue.serverTimestamp(),
      'uploadedCvStorageProvider': 'cloudflare_r2',
    };
  }

  Map<String, dynamic> _legacyStorageCleanupData() {
    return {
      'uploadedCvFileId': FieldValue.delete(),
      'uploadedCvBucketId': FieldValue.delete(),
    };
  }
}
