import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  Future<UserModel?> getStudentProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateStudentProfile({
    required String uid,
    required String phone,
    required String location,
    required String university,
    required String fieldOfStudy,
    required String bio,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'phone': phone,
      'location': location,
      'university': university,
      'fieldOfStudy': fieldOfStudy,
      'bio': bio,
    });
  }

  Future<void> updateStudentAvatar({
    required String uid,
    required String avatarId,
  }) async {
    if (!_isValidAvatarId(avatarId)) {
      throw Exception('Invalid avatar selected.');
    }

    await _firestore.collection('users').doc(uid).update({
      'photoType': 'avatar',
      'avatarId': avatarId,
    });
  }

  Future<String> uploadAndSetProfilePhoto({
    required String uid,
    required String fileName,
    String filePath = '',
    Uint8List? fileBytes,
  }) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final existingData = doc.data() ?? const <String, dynamic>{};
    final previousManagedUrl = _extractManagedProfileUrl(
      existingData['profileImage'],
    );

    final result = await _storageService.uploadProfilePhoto(
      userId: uid,
      fileName: fileName,
      filePath: filePath,
      fileBytes: fileBytes,
    );

    await _firestore.collection('users').doc(uid).update({
      'photoType': 'upload',
      'avatarId': null,
      'profileImage': result.fileUrl,
    });

    if (previousManagedUrl.isNotEmpty && previousManagedUrl != result.fileUrl) {
      try {
        await _storageService.deleteFileByPath(previousManagedUrl);
      } catch (_) {}
    }

    return result.fileUrl;
  }

  Future<void> useUploadedProfilePhoto(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final existingData = doc.data() ?? const <String, dynamic>{};
    final existingProfileImage = (existingData['profileImage'] ?? '')
        .toString()
        .trim();

    if (existingProfileImage.isEmpty) {
      throw Exception('No uploaded profile photo is available.');
    }

    await _firestore.collection('users').doc(uid).update({
      'photoType': 'upload',
      'avatarId': null,
    });
  }

  Future<void> removeProfilePhoto(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final existingData = doc.data() ?? const <String, dynamic>{};
    final previousManagedUrl = _extractManagedProfileUrl(
      existingData['profileImage'],
    );

    await _firestore.collection('users').doc(uid).update({
      'photoType': null,
      'avatarId': null,
      'profileImage': '',
    });

    if (previousManagedUrl.isNotEmpty) {
      try {
        await _storageService.deleteFileByPath(previousManagedUrl);
      } catch (_) {}
    }
  }

  bool _isValidAvatarId(String avatarId) {
    return const {
      'avatar_1',
      'avatar_2',
      'avatar_3',
      'avatar_4',
      'avatar_5',
      'avatar_6',
      'avatar_7',
      'avatar_8',
    }.contains(avatarId.trim());
  }

  String _extractManagedProfileUrl(Object? rawUrl) {
    final url = (rawUrl ?? '').toString().trim();
    if (url.isEmpty || !url.contains('/file/')) {
      return '';
    }
    return url;
  }
}
