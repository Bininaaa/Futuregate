import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/admin_identity.dart';
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
  final num? fundingAmount;
  final String? fundingCurrency;
  final String? fundingNote;
  final String? employmentType;
  final String? workMode;
  final bool? isPaid;
  final String? duration;
  final DateTime? applicationDeadline;
  final List<String> tags;
  final List<String> requirementItems;
  final List<String> benefits;
  final Map<String, dynamic> rawData;
  final String? originalLanguage;

  // Early access fields
  final bool earlyAccessRequested;
  final String earlyAccessStatus; // none, pending, approved, rejected, expired
  final bool premiumEarlyAccess;
  final DateTime? publicVisibleAt;
  final int? earlyAccessDurationHours;
  final String? earlyAccessRejectedReason;

  // Stats fields
  final int viewsCount;
  final int applicationsCount;
  final int premiumApplicationsCount;
  final int freeApplicationsCount;
  final int lockedApplyClicks;
  final int upgradeModalViews;
  final int upgradeClicks;

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
    this.fundingAmount,
    this.fundingCurrency,
    this.fundingNote,
    this.employmentType,
    this.workMode,
    this.isPaid,
    this.duration,
    this.applicationDeadline,
    this.tags = const [],
    this.requirementItems = const [],
    this.benefits = const [],
    this.rawData = const {},
    this.originalLanguage,
    // Early access
    this.earlyAccessRequested = false,
    this.earlyAccessStatus = 'none',
    this.premiumEarlyAccess = false,
    this.publicVisibleAt,
    this.earlyAccessDurationHours,
    this.earlyAccessRejectedReason,
    // Stats
    this.viewsCount = 0,
    this.applicationsCount = 0,
    this.premiumApplicationsCount = 0,
    this.freeApplicationsCount = 0,
    this.lockedApplyClicks = 0,
    this.upgradeModalViews = 0,
    this.upgradeClicks = 0,
  });

  factory OpportunityModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map);
    final createdByRole = (data['createdByRole'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final rawCompanyName = (data['companyName'] ?? '').toString();

    return OpportunityModel(
      id: (data['id'] ?? '').toString(),
      companyId: (data['companyId'] ?? '').toString(),
      companyName: createdByRole == 'admin'
          ? AdminIdentity.publisherLabel(rawCompanyName)
          : rawCompanyName,
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
      fundingAmount: OpportunityMetadata.extractFundingAmount(data),
      fundingCurrency: OpportunityMetadata.extractFundingCurrency(data),
      fundingNote: OpportunityMetadata.extractFundingNote(data),
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
      originalLanguage: data['originalLanguage']?.toString(),
      // Early access
      earlyAccessRequested: data['earlyAccessRequested'] == true,
      earlyAccessStatus: _normalizeEarlyAccessStatus(data['earlyAccessStatus']),
      premiumEarlyAccess: data['premiumEarlyAccess'] == true,
      publicVisibleAt: OpportunityMetadata.parseDateTimeLike(
        data['publicVisibleAt'],
      ),
      earlyAccessDurationHours: data['earlyAccessDurationHours'] is num
          ? (data['earlyAccessDurationHours'] as num).toInt()
          : null,
      earlyAccessRejectedReason: data['earlyAccessRejectedReason']?.toString(),
      // Stats
      viewsCount: _parseInt(data['viewsCount']),
      applicationsCount: _parseInt(data['applicationsCount']),
      premiumApplicationsCount: _parseInt(data['premiumApplicationsCount']),
      freeApplicationsCount: _parseInt(data['freeApplicationsCount']),
      lockedApplyClicks: _parseInt(data['lockedApplyClicks']),
      upgradeModalViews: _parseInt(data['upgradeModalViews']),
      upgradeClicks: _parseInt(data['upgradeClicks']),
    );
  }

  static String _normalizeEarlyAccessStatus(dynamic value) {
    const valid = {'none', 'pending', 'approved', 'rejected', 'expired'};
    final s = (value ?? 'none').toString().trim().toLowerCase();
    return valid.contains(s) ? s : 'none';
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
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
      'fundingAmount': fundingAmount,
      'fundingCurrency': fundingCurrency,
      'fundingNote': fundingNote,
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
      if (originalLanguage != null) 'originalLanguage': originalLanguage,
      'earlyAccessRequested': earlyAccessRequested,
      'earlyAccessStatus': earlyAccessStatus,
      'premiumEarlyAccess': premiumEarlyAccess,
      'publicVisibleAt': publicVisibleAt != null
          ? OpportunityMetadata.toTimestampOrNull(publicVisibleAt)
          : null,
      if (earlyAccessDurationHours != null)
        'earlyAccessDurationHours': earlyAccessDurationHours,
      if (earlyAccessRejectedReason != null)
        'earlyAccessRejectedReason': earlyAccessRejectedReason,
      'viewsCount': viewsCount,
      'applicationsCount': applicationsCount,
      'premiumApplicationsCount': premiumApplicationsCount,
      'freeApplicationsCount': freeApplicationsCount,
      'lockedApplyClicks': lockedApplyClicks,
      'upgradeModalViews': upgradeModalViews,
      'upgradeClicks': upgradeClicks,
    };
  }

  bool get isEarlyAccessActive {
    if (!premiumEarlyAccess) return false;
    if (earlyAccessStatus != 'approved') return false;
    if (publicVisibleAt == null) return false;
    return DateTime.now().isBefore(publicVisibleAt!);
  }

  bool get isPendingEarlyAccessReview => earlyAccessStatus == 'pending';

  bool get usesStructuredMetadata =>
      OpportunityMetadata.usesStructuredFields(type);

  String? fundingLabel({bool preferFundingNote = false}) {
    return OpportunityMetadata.buildFundingLabel(
      fundingAmount: fundingAmount,
      fundingCurrency: fundingCurrency,
      fundingNote: fundingNote,
      legacySalaryMin: salaryMin,
      legacySalaryMax: salaryMax,
      legacySalaryCurrency: salaryCurrency,
      legacyCompensationText: compensationText,
      preferFundingNote: preferFundingNote,
    );
  }

  String get createdByRole =>
      (readString(<String>['createdByRole']) ?? '').trim().toLowerCase();

  bool get isAdminPosted => createdByRole == 'admin';

  DateTime? get effectiveDeadline =>
      OpportunityMetadata.normalizeDeadline(applicationDeadline ?? deadline);

  bool isDeadlineExpired({DateTime? now}) =>
      OpportunityMetadata.isDeadlineExpired(effectiveDeadline, now: now);

  String effectiveStatus({DateTime? now}) {
    final normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus == 'closed' || isDeadlineExpired(now: now)) {
      return 'closed';
    }

    return 'open';
  }

  String publisherStatus({DateTime? now}) {
    final availabilityStatus = effectiveStatus(now: now);
    if (availabilityStatus == 'closed') {
      return 'closed';
    }
    if (isPendingEarlyAccessReview) {
      return 'pending';
    }

    return availabilityStatus;
  }

  bool isVisibleToStudents({DateTime? now}) =>
      !isHidden &&
      effectiveStatus(now: now) == 'open' &&
      !isPendingEarlyAccessReview;

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
