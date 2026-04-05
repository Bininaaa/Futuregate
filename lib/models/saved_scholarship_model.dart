import 'package:cloud_firestore/cloud_firestore.dart';

class SavedScholarshipModel {
  final String id;
  final String scholarshipId;
  final String studentId;
  final String title;
  final String provider;
  final String deadline;
  final String location;
  final String fundingType;
  final String level;
  final Timestamp? savedAt;

  const SavedScholarshipModel({
    required this.id,
    required this.scholarshipId,
    required this.studentId,
    required this.title,
    required this.provider,
    required this.deadline,
    required this.location,
    required this.fundingType,
    required this.level,
    this.savedAt,
  });

  factory SavedScholarshipModel.fromMap(Map<String, dynamic> map) {
    return SavedScholarshipModel(
      id: (map['id'] ?? '').toString(),
      scholarshipId: (map['scholarshipId'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      provider: (map['provider'] ?? '').toString(),
      deadline: (map['deadline'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      fundingType: (map['fundingType'] ?? '').toString(),
      level: (map['level'] ?? '').toString(),
      savedAt: map['savedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scholarshipId': scholarshipId,
      'studentId': studentId,
      'title': title,
      'provider': provider,
      'deadline': deadline,
      'location': location,
      'fundingType': fundingType,
      'level': level,
      'savedAt': savedAt,
    };
  }
}
