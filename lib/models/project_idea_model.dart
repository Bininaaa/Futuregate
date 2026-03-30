import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectIdeaModel {
  final String id;
  final String title;
  final String description;
  final String domain;
  final String level;
  final String tools;
  final String status;
  final String submittedBy;
  final String submittedByName;
  final Timestamp? createdAt;

  ProjectIdeaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.level,
    required this.tools,
    required this.status,
    required this.submittedBy,
    this.submittedByName = '',
    this.createdAt,
  });

  factory ProjectIdeaModel.fromMap(Map<String, dynamic> map) {
    return ProjectIdeaModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      domain: map['domain'] ?? '',
      level: map['level'] ?? '',
      tools: map['tools'] ?? '',
      status: map['status'] ?? 'pending',
      submittedBy: map['submittedBy'] ?? '',
      submittedByName: map['submittedByName'] ?? '',
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'domain': domain,
      'level': level,
      'tools': tools,
      'status': status,
      'submittedBy': submittedBy,
      if (submittedByName.isNotEmpty) 'submittedByName': submittedByName,
      'createdAt': createdAt,
    };
  }
}
