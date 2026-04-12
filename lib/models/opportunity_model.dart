import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/opportunity_metadata.dart';
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
  final Timestamp? updatedAt;
  final bool isFeatured;
  final bool isHidden;
  final num? salaryMin;
  final num? salaryMax;
  final String? salaryCurrency;
  final String? salaryPeriod;
  final String? compensationText;
  final String? employmentType;
  final String? workMode;
  final bool? isPaid;
  final String? duration;
  final DateTime? applicationDeadline;
  final List<String> tags;
  final List<String> requirementItems;
  final List<String> benefits;
  final Map<String, dynamic> rawData;

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
    this.updatedAt,
    this.isFeatured = false,
    this.isHidden = false,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.salaryPeriod,
    this.compensationText,
    this.employmentType,
    this.workMode,
    this.isPaid,
    this.duration,
    this.applicationDeadline,
    this.tags = const [],
    this.requirementItems = const [],
    this.benefits = const [],
    this.rawData = const {},
  });

  factory OpportunityModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map);

    return OpportunityModel(
      id: (data['id'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      companyName: (data['companyName'] ?? '').toString(),
      companyLogo: (data['companyLogo'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      type: OpportunityType.parse(data['type']?.toString()),
      location: (data['location'] ?? '').toString(),
      requirements: (data['requirements'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      deadline: OpportunityMetadata.stringFromValue(data['deadline']) ?? '',
      createdAt: _timestampFromValue(data['createdAt']),
      updatedAt: _timestampFromValue(data['updatedAt']),
      isFeatured: data['isFeatured'] == true,
      isHidden: data['isHidden'] == true,
      salaryMin: OpportunityMetadata.extractSalaryMin(data),
      salaryMax: OpportunityMetadata.extractSalaryMax(data),
      salaryCurrency: OpportunityMetadata.extractSalaryCurrency(data),
      salaryPeriod: OpportunityMetadata.extractSalaryPeriod(data),
      compensationText: OpportunityMetadata.extractCompensationText(data),
      employmentType: OpportunityMetadata.extractEmploymentType(data),
      workMode: OpportunityMetadata.extractWorkMode(data),
      isPaid: OpportunityMetadata.extractIsPaid(data),
      duration: OpportunityMetadata.extractDuration(data),
      applicationDeadline: OpportunityMetadata.extractApplicationDeadline(data),
      tags: OpportunityMetadata.extractTags(
        data,
        type: data['type']?.toString(),
        employmentType: OpportunityMetadata.extractEmploymentType(data),
        workMode: OpportunityMetadata.extractWorkMode(data),
        isFeatured: data['isFeatured'] == true,
        compensationText: OpportunityMetadata.extractCompensationText(data),
      ),
      requirementItems: OpportunityMetadata.extractRequirementItems(
        data,
        fallbackText: (data['requirements'] ?? '').toString(),
      ),
      benefits: OpportunityMetadata.extractBenefits(
        data,
        type: data['type']?.toString() ?? '',
        workMode: OpportunityMetadata.extractWorkMode(data),
        isFeatured: data['isFeatured'] == true,
        isPaid: OpportunityMetadata.extractIsPaid(data),
        compensationText: OpportunityMetadata.extractCompensationText(data),
      ),
      rawData: data,
    );
  }

  Map<String, dynamic> toMap() {
    final normalizedDeadline = deadlineLabel.isNotEmpty
        ? deadlineLabel
        : deadline.trim();

    return {
      ...rawData,
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
      'deadline': normalizedDeadline,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isFeatured': isFeatured,
      'isHidden': isHidden,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'salaryPeriod': salaryPeriod,
      'compensationText': compensationText,
      'employmentType': employmentType,
      'workMode': workMode,
      'isPaid': isPaid,
      'duration': duration,
      'applicationDeadline': OpportunityMetadata.toTimestampOrNull(
        applicationDeadline,
      ),
      'tags': tags,
      'requirementItems': requirementItems,
      'benefits': benefits,
    };
  }

  bool get usesStructuredMetadata =>
      OpportunityMetadata.usesStructuredFields(type);

  String get createdByRole =>
      (readString(<String>['createdByRole']) ?? '').trim().toLowerCase();

  bool get isAdminPosted => createdByRole == 'admin';

  String get deadlineLabel {
    if (applicationDeadline != null) {
      return OpportunityMetadata.formatDateForStorage(applicationDeadline!);
    }

    return deadline.trim();
  }

  dynamic firstValue(List<String> keys) {
    return OpportunityMetadata.firstValue(rawData, keys);
  }

  String? readString(List<String> keys) {
    return OpportunityMetadata.stringFromValue(firstValue(keys));
  }

  num? readNum(List<String> keys) {
    return OpportunityMetadata.parseNullableNum(firstValue(keys));
  }

  bool? readBool(List<String> keys) {
    return OpportunityMetadata.parseNullableBool(firstValue(keys));
  }

  DateTime? readDateTime(List<String> keys) {
    return OpportunityMetadata.parseDateTimeLike(firstValue(keys));
  }

  static Timestamp? _timestampFromValue(dynamic value) {
    if (value is Timestamp) {
      return value;
    }

    final parsed = OpportunityMetadata.parseDateTimeLike(value);
    if (parsed == null) {
      return null;
    }

    return Timestamp.fromDate(parsed);
  }
}
