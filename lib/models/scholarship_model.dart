import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/opportunity_metadata.dart';

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
  final String? country;
  final String? city;
  final String? location;
  final String? imageUrl;
  final String? fundingType;
  final String? category;
  final String? level;
  final bool isFeatured;
  final bool isHidden;
  final String originalLanguage;
  final List<String> tags;
  final List<String> eligibilityItems;
  final Map<String, dynamic> rawData;

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
    this.country,
    this.city,
    this.location,
    this.imageUrl,
    this.fundingType,
    this.category,
    this.level,
    this.isFeatured = false,
    this.isHidden = false,
    this.originalLanguage = '',
    this.tags = const [],
    this.eligibilityItems = const [],
    this.rawData = const {},
  });

  factory ScholarshipModel.fromMap(Map<String, dynamic> map) {
    final rawData = Map<String, dynamic>.from(map);
    final eligibilityItems = OpportunityMetadata.stringListFromValue(
      rawData['eligibilityItems'] ?? rawData['eligibility_items'],
      maxItems: 10,
    );

    return ScholarshipModel(
      id: _readString(rawData['id']) ?? '',
      title: _readString(rawData['title']) ?? '',
      description: _readString(rawData['description']) ?? '',
      provider: _readString(rawData['provider']) ?? '',
      eligibility: _readString(rawData['eligibility']) ?? '',
      amount: rawData['amount'] ?? 0,
      deadline: _readString(rawData['deadline']) ?? '',
      link: _readString(rawData['link']) ?? '',
      createdBy: _readString(rawData['createdBy']) ?? '',
      createdByRole: _readString(rawData['createdByRole']) ?? '',
      createdAt: _parseTimestamp(rawData['createdAt']),
      country: _readFirstString(rawData, const [
        'country',
        'destinationCountry',
        'studyCountry',
      ]),
      city: _readFirstString(rawData, const [
        'city',
        'destinationCity',
        'studyCity',
      ]),
      location: _readFirstString(rawData, const [
        'location',
        'destination',
        'cityCountry',
        'campusLocation',
      ]),
      imageUrl: _readFirstString(rawData, const [
        'imageUrl',
        'bannerUrl',
        'image',
        'coverImage',
        'heroImage',
        'thumbnailUrl',
        'photoUrl',
      ]),
      fundingType: _readFirstString(rawData, const [
        'fundingType',
        'funding',
        'fundingLabel',
        'status',
        'badge',
      ]),
      category: _readFirstString(rawData, const [
        'category',
        'type',
        'programType',
      ]),
      level: _readFirstString(rawData, const [
        'level',
        'studyLevel',
        'degreeLevel',
      ]),
      originalLanguage: _readFirstString(rawData, const [
            'originalLanguage',
            'sourceLanguage',
          ]) ??
          '',
      isFeatured: _readBool(rawData['featured']) ?? false,
      isHidden: _readBool(rawData['isHidden']) ?? false,
      tags: _readStringList(rawData['tags']),
      eligibilityItems: eligibilityItems.isNotEmpty
          ? eligibilityItems
          : OpportunityMetadata.stringListFromValue(
              rawData['eligibility'],
              maxItems: 10,
            ),
      rawData: rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...rawData,
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
      'country': country,
      'city': city,
      'location': location,
      'imageUrl': imageUrl,
      'fundingType': fundingType,
      'category': category,
      'level': level,
      'originalLanguage': originalLanguage,
      'featured': isFeatured,
      'isHidden': isHidden,
      'tags': tags,
      'eligibilityItems': eligibilityItems,
    };
  }

  DateTime? get deadlineDate => OpportunityMetadata.normalizeDeadline(deadline);

  bool isDeadlineExpired({DateTime? now}) =>
      OpportunityMetadata.isDeadlineExpired(deadlineDate, now: now);

  bool isVisibleToStudents({DateTime? now}) =>
      !isHidden && !isDeadlineExpired(now: now);

  static String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _readFirstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = _readString(map[key]);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'no' || normalized == '0') {
        return false;
      }
    }

    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map(_readString)
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final single = _readString(value);
    if (single == null) {
      return const [];
    }

    return <String>[single];
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value;
    }

    if (value is DateTime) {
      return Timestamp.fromDate(value);
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
