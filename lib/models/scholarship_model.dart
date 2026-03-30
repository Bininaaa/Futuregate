import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarshipModel {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String eligibility;
  final num amount;
  final String deadline;
  final String link;
  final String createdBy;
  final String createdByRole;
  final Timestamp? createdAt;

  ScholarshipModel({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    required this.eligibility,
    required this.amount,
    required this.deadline,
    required this.link,
    required this.createdBy,
    required this.createdByRole,
    this.createdAt,
  });

  factory ScholarshipModel.fromMap(Map<String, dynamic> map) {
    return ScholarshipModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      provider: map['provider'] ?? '',
      eligibility: map['eligibility'] ?? '',
      amount: map['amount'] ?? 0,
      deadline: map['deadline'] ?? '',
      link: map['link'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByRole: map['createdByRole'] ?? '',
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'provider': provider,
      'eligibility': eligibility,
      'amount': amount,
      'deadline': deadline,
      'link': link,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'createdAt': createdAt,
    };
  }
}