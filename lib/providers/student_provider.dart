import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _studentService = StudentService();

  UserModel? _student;
  bool _isLoading = false;

  UserModel? get student => _student;
  bool get isLoading => _isLoading;

  Future<void> loadStudentProfile(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      _student = await _studentService.getStudentProfile(uid);
    } catch (e) {
      debugPrint('loadStudentProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateStudentProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String location,
    required String university,
    required String fieldOfStudy,
    required String bio,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _studentService.updateStudentProfile(
        uid: uid,
        fullName: fullName,
        phone: phone,
        location: location,
        university: university,
        fieldOfStudy: fieldOfStudy,
        bio: bio,
      );

      _student = await _studentService.getStudentProfile(uid);

      return null;
    } catch (e) {
      debugPrint('updateStudentProfile error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> selectAvatar({
    required String uid,
    required String avatarId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _studentService.updateStudentAvatar(uid: uid, avatarId: avatarId);
      _student = await _studentService.getStudentProfile(uid);

      return null;
    } catch (e) {
      debugPrint('selectAvatar error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadProfilePhoto({
    required String uid,
    required String fileName,
    String filePath = '',
    Uint8List? fileBytes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _studentService.uploadAndSetProfilePhoto(
        uid: uid,
        fileName: fileName,
        filePath: filePath,
        fileBytes: fileBytes,
      );

      _student = await _studentService.getStudentProfile(uid);

      return null;
    } catch (e) {
      debugPrint('uploadProfilePhoto error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> useUploadedProfilePhoto(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _studentService.useUploadedProfilePhoto(uid);
      _student = await _studentService.getStudentProfile(uid);

      return null;
    } catch (e) {
      debugPrint('useUploadedProfilePhoto error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> removeProfilePhoto(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _studentService.removeProfilePhoto(uid);
      _student = await _studentService.getStudentProfile(uid);

      return null;
    } catch (e) {
      debugPrint('removeProfilePhoto error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearStudent() {
    _student = null;
    _isLoading = false;
    notifyListeners();
  }
}
