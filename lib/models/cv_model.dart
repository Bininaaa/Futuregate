import 'package:cloud_firestore/cloud_firestore.dart';

class CvModel {
  final String id;
  final String studentId;

  // Editable CV fields
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String summary;
  final List<Map<String, dynamic>> education;
  final List<Map<String, dynamic>> experience;
  final List<String> skills;
  final List<String> languages;

  // New CV system fields
  final String sourceType; // builder | uploaded | hybrid
  final String templateId; // classic | modern | minimal | ''
  final String primaryCvMode; // uploaded | builder_pdf | ''

  // Uploaded original CV
  final String uploadedCvUrl;
  final String uploadedCvPath;
  final String uploadedFileName;
  final String uploadedCvMimeType;
  final Timestamp? uploadedCvUploadedAt;

  // Exported builder CV PDF
  final String exportedPdfUrl;
  final String exportedPdfPath;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CvModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.summary,
    required this.education,
    required this.experience,
    required this.skills,
    required this.languages,
    required this.sourceType,
    required this.templateId,
    required this.primaryCvMode,
    required this.uploadedCvUrl,
    required this.uploadedCvPath,
    required this.uploadedFileName,
    required this.uploadedCvMimeType,
    this.uploadedCvUploadedAt,
    required this.exportedPdfUrl,
    required this.exportedPdfPath,
    this.createdAt,
    this.updatedAt,
  });

  factory CvModel.empty(String studentId) {
    return CvModel(
      id: '',
      studentId: studentId,
      fullName: '',
      email: '',
      phone: '',
      address: '',
      summary: '',
      education: const [],
      experience: const [],
      skills: const [],
      languages: const [],
      sourceType: '',
      templateId: '',
      primaryCvMode: '',
      uploadedCvUrl: '',
      uploadedCvPath: '',
      uploadedFileName: '',
      uploadedCvMimeType: '',
      uploadedCvUploadedAt: null,
      exportedPdfUrl: '',
      exportedPdfPath: '',
      createdAt: null,
      updatedAt: null,
    );
  }

  factory CvModel.fromMap(Map<String, dynamic> map) {
    return CvModel(
      id: (map['id'] ?? '') as String,
      studentId: (map['studentId'] ?? '') as String,
      fullName: (map['fullName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      summary: (map['summary'] ?? '') as String,
      education: List<Map<String, dynamic>>.from(map['education'] ?? const []),
      experience: List<Map<String, dynamic>>.from(
        map['experience'] ?? const [],
      ),
      skills: List<String>.from(map['skills'] ?? const []),
      languages: List<String>.from(map['languages'] ?? const []),
      sourceType: (map['sourceType'] ?? '') as String,
      templateId: (map['templateId'] ?? '') as String,
      primaryCvMode: (map['primaryCvMode'] ?? '') as String,
      uploadedCvUrl: (map['uploadedCvUrl'] ?? '') as String,
      uploadedCvPath: (map['uploadedCvPath'] ?? '') as String,
      uploadedFileName: (map['uploadedFileName'] ?? '') as String,
      uploadedCvMimeType: (map['uploadedCvMimeType'] ?? '') as String,
      uploadedCvUploadedAt: _parseTimestamp(map['uploadedCvCreatedAt']),
      exportedPdfUrl: (map['exportedPdfUrl'] ?? '') as String,
      exportedPdfPath: (map['exportedPdfPath'] ?? '') as String,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'sourceType': sourceType,
      'templateId': templateId,
      'primaryCvMode': primaryCvMode,
      'uploadedCvUrl': uploadedCvUrl,
      'uploadedCvPath': uploadedCvPath,
      'uploadedFileName': uploadedFileName,
      'uploadedCvMimeType': uploadedCvMimeType,
      'uploadedCvCreatedAt': uploadedCvUploadedAt,
      'exportedPdfUrl': exportedPdfUrl,
      'exportedPdfPath': exportedPdfPath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CvModel copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? summary,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<String>? skills,
    List<String>? languages,
    String? sourceType,
    String? templateId,
    String? primaryCvMode,
    String? uploadedCvUrl,
    String? uploadedCvPath,
    String? uploadedFileName,
    String? uploadedCvMimeType,
    Timestamp? uploadedCvUploadedAt,
    String? exportedPdfUrl,
    String? exportedPdfPath,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CvModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      summary: summary ?? this.summary,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      sourceType: sourceType ?? this.sourceType,
      templateId: templateId ?? this.templateId,
      primaryCvMode: primaryCvMode ?? this.primaryCvMode,
      uploadedCvUrl: uploadedCvUrl ?? this.uploadedCvUrl,
      uploadedCvPath: uploadedCvPath ?? this.uploadedCvPath,
      uploadedFileName: uploadedFileName ?? this.uploadedFileName,
      uploadedCvMimeType: uploadedCvMimeType ?? this.uploadedCvMimeType,
      uploadedCvUploadedAt: uploadedCvUploadedAt ?? this.uploadedCvUploadedAt,
      exportedPdfUrl: exportedPdfUrl ?? this.exportedPdfUrl,
      exportedPdfPath: exportedPdfPath ?? this.exportedPdfPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasUploadedCv =>
      uploadedCvPath.trim().isNotEmpty || uploadedCvUrl.trim().isNotEmpty;
  bool get hasExportedPdf =>
      exportedPdfPath.trim().isNotEmpty || exportedPdfUrl.trim().isNotEmpty;
  bool get isUploadedCvPdf {
    final mime = uploadedCvMimeType.trim().toLowerCase();
    if (mime == 'application/pdf') {
      return true;
    }

    return uploadedFileName.trim().toLowerCase().endsWith('.pdf');
  }

  String get uploadedCvDisplayName {
    final name = uploadedFileName.trim();
    if (name.isNotEmpty) {
      return name;
    }

    return 'primary_cv.pdf';
  }

  String get exportedPdfFileName {
    final safeTemplateId = templateId.trim().isEmpty ? 'builder' : templateId;
    return 'cv_$safeTemplateId.pdf';
  }

  bool get hasBuilderContent =>
      fullName.trim().isNotEmpty ||
      summary.trim().isNotEmpty ||
      education.isNotEmpty ||
      experience.isNotEmpty ||
      skills.isNotEmpty ||
      languages.isNotEmpty;

  static Timestamp? _parseTimestamp(dynamic value) {
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
}
