import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/opportunity_type.dart';

class OpportunityModel {
  final String id;
  final String companyId;
  final String companyName;
  final String companyLogo;
  final String title;
  final String description;
  final String type;
  final String location;
  final String requirements;
  final String status;
  final String deadline;
  final Timestamp? createdAt;
  final bool isFeatured;

  OpportunityModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.companyLogo,
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    required this.requirements,
    required this.status,
    required this.deadline,
    this.createdAt,
    this.isFeatured = false,
  });

  factory OpportunityModel.fromMap(Map<String, dynamic> map) {
    return OpportunityModel(
      id: map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      companyLogo: map['companyLogo'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: OpportunityType.parse(map['type']),
      location: map['location'] ?? '',
      requirements: map['requirements'] ?? '',
      status: map['status'] ?? '',
      deadline: map['deadline'] ?? '',
      createdAt: map['createdAt'],
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'title': title,
      'description': description,
      'type': type,
      'location': location,
      'requirements': requirements,
      'status': status,
      'deadline': deadline,
      'createdAt': createdAt,
      'isFeatured': isFeatured,
    };
  }
}
