import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/cv_model.dart';
import '../services/cv_pdf_service.dart';
import '../services/cv_service.dart';
import '../services/storage_service.dart';

class CvProvider extends ChangeNotifier {
  final CvService _service = CvService();
  final StorageService _storageService = StorageService();

  CvModel? _cv;
  bool _isLoading = false;
  bool _isExporting = false;

  CvModel? get cv => _cv;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;

  Future<void> loadCv(String studentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _cv = await _service.getCvByStudentId(studentId);
    } catch (e) {
      debugPrint('loadCv error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> saveCv({
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
    try {
      _isLoading = true;
      notifyListeners();

      await _service.saveCv(
        studentId: studentId,
        fullName: fullName,
        email: email,
        phone: phone,
        address: address,
        summary: summary,
        education: education,
        experience: experience,
        skills: skills,
        languages: languages,
        templateId: templateId,
      );

      await loadCv(studentId);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadCvFile({
    required String studentId,
    required String filePath,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.attachUploadedCv(
        studentId: studentId,
        filePath: filePath,
        fileName: fileName,
        fileBytes: fileBytes,
      );

      await loadCv(studentId);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> setPrimaryCvMode({
    required String studentId,
    required String primaryCvMode,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.setPrimaryCvMode(
        studentId: studentId,
        primaryCvMode: primaryCvMode,
      );

      await loadCv(studentId);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportCvAsPdf({required String studentId}) async {
    if (_cv == null || !_cv!.hasBuilderContent) {
      return 'No CV content to export. Please fill in your CV first.';
    }

    try {
      _isExporting = true;
      notifyListeners();

      final pdfBytes = await CvPdfService.generatePdf(_cv!);
      final templateId = _cv!.templateId.trim().isEmpty
          ? 'classic'
          : _cv!.templateId;

      final uploadResult = await _storageService.uploadGeneratedPdf(
        userId: studentId,
        bytes: pdfBytes,
        templateId: templateId,
      );

      await _service.attachExportedPdf(
        studentId: studentId,
        exportedPdfUrl: uploadResult.fileUrl,
        exportedPdfPath: uploadResult.objectKey,
        templateId: templateId,
      );

      await loadCv(studentId);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void clearCv() {
    _cv = null;
    _isLoading = false;
    _isExporting = false;
    notifyListeners();
  }
}
