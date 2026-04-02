import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/application_status.dart';

class ApplicationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String opportunityId;
  final String companyId;
  final String cvId;
  final String status;
  final Timestamp? appliedAt;

  ApplicationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.opportunityId,
    required this.companyId,
    required this.cvId,
    required this.status,
    this.appliedAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      opportunityId: map['opportunityId'] ?? '',
      companyId: map['companyId'] ?? '',
      cvId: map['cvId'] ?? '',
      status: ApplicationStatus.parse(map['status']),
      appliedAt: map['appliedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'opportunityId': opportunityId,
      'companyId': companyId,
      'cvId': cvId,
      'status': status,
      'appliedAt': appliedAt,
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? opportunityId,
    String? companyId,
    String? cvId,
    String? status,
    Timestamp? appliedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      opportunityId: opportunityId ?? this.opportunityId,
      companyId: companyId ?? this.companyId,
      cvId: cvId ?? this.cvId,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
