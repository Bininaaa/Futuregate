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
  final Timestamp? withdrawnAt;
  final bool hadWithdrawnBefore;
  final bool isPremiumAtApply;
  final bool priorityApplication;
  final Map<String, dynamic> subscriptionSnapshot;

  ApplicationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.opportunityId,
    required this.companyId,
    required this.cvId,
    required this.status,
    this.appliedAt,
    this.withdrawnAt,
    this.hadWithdrawnBefore = false,
    this.isPremiumAtApply = false,
    this.priorityApplication = false,
    this.subscriptionSnapshot = const {},
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'] ?? '',
      studentId: (map['studentId'] ?? map['applicantUid'] ?? '').toString(),
      studentName: map['studentName'] ?? '',
      opportunityId: map['opportunityId'] ?? '',
      companyId: map['companyId'] ?? '',
      cvId: map['cvId'] ?? '',
      status: ApplicationStatus.parse(map['status']),
      appliedAt: map['appliedAt'],
      withdrawnAt: map['withdrawnAt'],
      hadWithdrawnBefore: map['hadWithdrawnBefore'] == true,
      isPremiumAtApply: map['isPremiumAtApply'] == true,
      priorityApplication: map['priorityApplication'] == true,
      subscriptionSnapshot: map['subscriptionSnapshot'] is Map
          ? Map<String, dynamic>.from(map['subscriptionSnapshot'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'opportunityId': opportunityId,
      'companyId': companyId,
      'cvId': cvId,
      'status': status,
      'appliedAt': appliedAt,
      'withdrawnAt': withdrawnAt,
      'hadWithdrawnBefore': hadWithdrawnBefore,
      'isPremiumAtApply': isPremiumAtApply,
      'priorityApplication': priorityApplication,
    };

    if (subscriptionSnapshot.isNotEmpty) {
      data['subscriptionSnapshot'] = subscriptionSnapshot;
    }

    return data;
  }

  bool get shouldPrioritizeApplication =>
      ApplicationStatus.parse(status) == ApplicationStatus.pending &&
      (priorityApplication || isPremiumAtApply);

  static int comparePriorityThenRecent(
    ApplicationModel first,
    ApplicationModel second,
  ) {
    final firstPriority = first.shouldPrioritizeApplication ? 0 : 1;
    final secondPriority = second.shouldPrioritizeApplication ? 0 : 1;
    if (firstPriority != secondPriority) {
      return firstPriority.compareTo(secondPriority);
    }

    final firstTime = first.appliedAt?.millisecondsSinceEpoch ?? 0;
    final secondTime = second.appliedAt?.millisecondsSinceEpoch ?? 0;
    return secondTime.compareTo(firstTime);
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
    Timestamp? withdrawnAt,
    bool? hadWithdrawnBefore,
    bool? isPremiumAtApply,
    bool? priorityApplication,
    Map<String, dynamic>? subscriptionSnapshot,
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
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      hadWithdrawnBefore: hadWithdrawnBefore ?? this.hadWithdrawnBefore,
      isPremiumAtApply: isPremiumAtApply ?? this.isPremiumAtApply,
      priorityApplication: priorityApplication ?? this.priorityApplication,
      subscriptionSnapshot: subscriptionSnapshot ?? this.subscriptionSnapshot,
    );
  }
}
