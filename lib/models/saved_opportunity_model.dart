import 'package:cloud_firestore/cloud_firestore.dart';

class SavedOpportunityModel {
  final String id;
  final String opportunityId;
  final String studentId;
  final String title;
  final String companyName;
  final String type;
  final String location;
  final String deadline;
  final Timestamp? savedAt;

  SavedOpportunityModel({
    required this.id,
    required this.opportunityId,
    required this.studentId,
    required this.title,
    required this.companyName,
    required this.type,
    required this.location,
    required this.deadline,
    this.savedAt,
  });

  factory SavedOpportunityModel.fromMap(Map<String, dynamic> map) {
    return SavedOpportunityModel(
      id: map['id'] ?? '',
      opportunityId: map['opportunityId'] ?? '',
      studentId: map['studentId'] ?? '',
      title: map['title'] ?? '',
      companyName: map['companyName'] ?? '',
      type: map['type'] ?? '',
      location: map['location'] ?? '',
      deadline: map['deadline'] ?? '',
      savedAt: map['savedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opportunityId': opportunityId,
      'studentId': studentId,
      'title': title,
      'companyName': companyName,
      'type': type,
      'location': location,
      'deadline': deadline,
      'savedAt': savedAt,
    };
  }
}
