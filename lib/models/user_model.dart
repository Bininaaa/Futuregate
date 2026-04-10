import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String phone;
  final String location;
  final String profileImage;
  final String? academicLevel;
  final String? university;
  final String? fieldOfStudy;
  final String? bio;
  final String? companyName;
  final String? sector;
  final String? description;
  final String? website;
  final String? logo;
  final String? adminLevel;
  final String? researchTopic;
  final String? laboratory;
  final String? supervisor;
  final String? researchDomain;
  final String? photoType; // 'avatar' | 'upload' | null
  final String? avatarId; // 'avatar_1' .. 'avatar_8' | null
  final String commercialRegisterUrl;
  final String commercialRegisterFileName;
  final String commercialRegisterMimeType;
  final String commercialRegisterStoragePath;
  final Timestamp? commercialRegisterUploadedAt;
  final String approvalStatus;
  final bool isOnline;
  final Timestamp? lastSeenAt;
  final bool isActive;
  final String provider; // 'email' or 'google'
  final bool studentOnboardingPending;

  bool get isEmailProvider => provider == 'email';
  bool get isGoogleProvider => provider == 'google';
  bool get isAdmin => role == 'admin';
  bool get isCompany => role == 'company';
  bool get needsStudentOnboarding =>
      role == 'student' && studentOnboardingPending;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.phone,
    required this.location,
    required this.profileImage,
    required this.isActive,
    this.provider = 'email',
    this.academicLevel,
    this.university,
    this.fieldOfStudy,
    this.bio,
    this.companyName,
    this.sector,
    this.description,
    this.website,
    this.logo,
    this.adminLevel,
    this.researchTopic,
    this.laboratory,
    this.supervisor,
    this.researchDomain,
    this.photoType,
    this.avatarId,
    this.commercialRegisterUrl = '',
    this.commercialRegisterFileName = '',
    this.commercialRegisterMimeType = '',
    this.commercialRegisterStoragePath = '',
    this.commercialRegisterUploadedAt,
    this.approvalStatus = '',
    this.isOnline = false,
    this.lastSeenAt,
    this.studentOnboardingPending = false,
  });

  bool get needsAcademicLevel =>
      role == 'student' && (academicLevel == null || academicLevel!.isEmpty);

  String get normalizedApprovalStatus {
    final normalized = approvalStatus.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    return isCompany ? 'approved' : '';
  }

  bool get isCompanyApproved =>
      !isCompany || normalizedApprovalStatus == 'approved';

  bool get isCompanyPendingApproval =>
      isCompany && normalizedApprovalStatus == 'pending';

  bool get isCompanyRejected =>
      isCompany && normalizedApprovalStatus == 'rejected';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = (map['role'] ?? '').toString();

    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: role,
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      profileImage: map['profileImage'] ?? '',
      academicLevel: map['academicLevel'],
      university: map['university'],
      fieldOfStudy: map['fieldOfStudy'],
      bio: map['bio'],
      companyName: map['companyName'],
      sector: map['sector'],
      description: map['description'],
      website: map['website'],
      logo: map['logo'],
      adminLevel: map['adminLevel'],
      researchTopic: map['researchTopic'],
      laboratory: map['laboratory'],
      supervisor: map['supervisor'],
      researchDomain: map['researchDomain'],
      photoType: map['photoType'],
      avatarId: map['avatarId'],
      commercialRegisterUrl: map['commercialRegisterUrl'] ?? '',
      commercialRegisterFileName: map['commercialRegisterFileName'] ?? '',
      commercialRegisterMimeType: map['commercialRegisterMimeType'] ?? '',
      commercialRegisterStoragePath: map['commercialRegisterStoragePath'] ?? '',
      commercialRegisterUploadedAt: _parseTimestamp(
        map['commercialRegisterUploadedAt'],
      ),
      approvalStatus: _normalizeApprovalStatus(
        map['approvalStatus'],
        role: role,
      ),
      isOnline: map['isOnline'] == true,
      lastSeenAt: _parseTimestamp(map['lastSeenAt']),
      isActive: map['isActive'] ?? true,
      provider: map['provider'] ?? 'email',
      studentOnboardingPending: map['studentOnboardingPending'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'location': location,
      'profileImage': profileImage,
      'academicLevel': academicLevel,
      'university': university,
      'fieldOfStudy': fieldOfStudy,
      'bio': bio,
      'companyName': companyName,
      'sector': sector,
      'description': description,
      'website': website,
      'logo': logo,
      'adminLevel': adminLevel,
      'researchTopic': researchTopic,
      'laboratory': laboratory,
      'supervisor': supervisor,
      'researchDomain': researchDomain,
      'photoType': photoType,
      'avatarId': avatarId,
      'commercialRegisterUrl': commercialRegisterUrl,
      'commercialRegisterFileName': commercialRegisterFileName,
      'commercialRegisterMimeType': commercialRegisterMimeType,
      'commercialRegisterStoragePath': commercialRegisterStoragePath,
      'commercialRegisterUploadedAt': commercialRegisterUploadedAt,
      'approvalStatus': approvalStatus,
      'isOnline': isOnline,
      'lastSeenAt': lastSeenAt,
      'isActive': isActive,
      'provider': provider,
      'studentOnboardingPending': studentOnboardingPending,
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? location,
    String? profileImage,
    String? academicLevel,
    String? university,
    String? fieldOfStudy,
    String? bio,
    String? companyName,
    String? sector,
    String? description,
    String? website,
    String? logo,
    String? adminLevel,
    String? researchTopic,
    String? laboratory,
    String? supervisor,
    String? researchDomain,
    String? photoType,
    String? avatarId,
    String? commercialRegisterUrl,
    String? commercialRegisterFileName,
    String? commercialRegisterMimeType,
    String? commercialRegisterStoragePath,
    Timestamp? commercialRegisterUploadedAt,
    String? approvalStatus,
    bool? isOnline,
    Timestamp? lastSeenAt,
    bool? isActive,
    String? provider,
    bool? studentOnboardingPending,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      academicLevel: academicLevel ?? this.academicLevel,
      university: university ?? this.university,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      bio: bio ?? this.bio,
      companyName: companyName ?? this.companyName,
      sector: sector ?? this.sector,
      description: description ?? this.description,
      website: website ?? this.website,
      logo: logo ?? this.logo,
      adminLevel: adminLevel ?? this.adminLevel,
      researchTopic: researchTopic ?? this.researchTopic,
      laboratory: laboratory ?? this.laboratory,
      supervisor: supervisor ?? this.supervisor,
      researchDomain: researchDomain ?? this.researchDomain,
      photoType: photoType ?? this.photoType,
      avatarId: avatarId ?? this.avatarId,
      commercialRegisterUrl:
          commercialRegisterUrl ?? this.commercialRegisterUrl,
      commercialRegisterFileName:
          commercialRegisterFileName ?? this.commercialRegisterFileName,
      commercialRegisterMimeType:
          commercialRegisterMimeType ?? this.commercialRegisterMimeType,
      commercialRegisterStoragePath:
          commercialRegisterStoragePath ?? this.commercialRegisterStoragePath,
      commercialRegisterUploadedAt:
          commercialRegisterUploadedAt ?? this.commercialRegisterUploadedAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isActive: isActive ?? this.isActive,
      provider: provider ?? this.provider,
      studentOnboardingPending:
          studentOnboardingPending ?? this.studentOnboardingPending,
    );
  }

  bool get hasCommercialRegister =>
      commercialRegisterStoragePath.trim().isNotEmpty ||
      commercialRegisterUrl.trim().isNotEmpty;

  bool get commercialRegisterIsPdf {
    final mime = commercialRegisterMimeType.trim().toLowerCase();
    if (mime == 'application/pdf') {
      return true;
    }

    return commercialRegisterFileName.trim().toLowerCase().endsWith('.pdf');
  }

  bool get commercialRegisterIsImage {
    final mime = commercialRegisterMimeType.trim().toLowerCase();
    if (mime.startsWith('image/')) {
      return true;
    }

    final fileName = commercialRegisterFileName.trim().toLowerCase();
    return fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg');
  }

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

  static String _normalizeApprovalStatus(
    dynamic value, {
    required String role,
  }) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    if (normalized == 'pending' ||
        normalized == 'approved' ||
        normalized == 'rejected') {
      return normalized;
    }

    return role == 'company' ? 'approved' : '';
  }
}
