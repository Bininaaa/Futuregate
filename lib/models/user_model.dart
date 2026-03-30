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
  final bool isActive;
  final String provider; // 'email' or 'google'

  bool get isEmailProvider => provider == 'email';
  bool get isGoogleProvider => provider == 'google';
  bool get isAdmin => role == 'admin';

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
  });

  bool get needsAcademicLevel =>
      role == 'student' && (academicLevel == null || academicLevel!.isEmpty);

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
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
      isActive: map['isActive'] ?? true,
      provider: map['provider'] ?? 'email',
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
      'isActive': isActive,
      'provider': provider,
    };
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
}
