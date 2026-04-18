import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/content_language.dart';

class TrainingModel {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String providerLogo;
  final String duration;
  final String level;
  final String link;
  final String createdBy;
  final String createdByRole;
  final Timestamp? createdAt;
  final Timestamp? savedAt;

  final String type; // training, book, course, file, video
  final String source; // internal, google_books, youtube, etc
  final List<String> authors;
  final String thumbnail;
  final String domain;
  final String language;
  final String previewLink;
  final bool isApproved;
  final bool isFeatured;
  final bool isHidden;
  final double? rating;
  final int? learnerCount;
  final String learnerCountLabel;
  final bool? isFree;
  final bool? hasCertificate;

  TrainingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    this.providerLogo = '',
    required this.duration,
    required this.level,
    required this.link,
    required this.createdBy,
    required this.createdByRole,
    this.createdAt,
    this.savedAt,
    this.type = 'training',
    this.source = 'internal',
    this.authors = const [],
    this.thumbnail = '',
    this.domain = '',
    this.language = '',
    this.previewLink = '',
    this.isApproved = true,
    this.isFeatured = false,
    this.isHidden = false,
    this.rating,
    this.learnerCount,
    this.learnerCountLabel = '',
    this.isFree,
    this.hasCertificate,
  });

  factory TrainingModel.fromMap(Map<String, dynamic> map) {
    final rawLearnerCount =
        map['learnerCount'] ?? map['enrolledCount'] ?? map['studentsCount'];
    final parsedLearnerCount = _parseLearnerCount(rawLearnerCount);

    return TrainingModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      provider: (map['provider'] ?? '').toString(),
      providerLogo: (map['providerLogo'] ?? map['providerLogoUrl'] ?? '')
          .toString(),
      duration: (map['duration'] ?? '').toString(),
      level: (map['level'] ?? '').toString(),
      link: (map['link'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByRole: (map['createdByRole'] ?? '').toString(),
      createdAt: map['createdAt'] as Timestamp?,
      savedAt: map['savedAt'] as Timestamp?,
      type: (map['type'] ?? 'training').toString(),
      source: (map['source'] ?? 'internal').toString(),
      authors:
          (map['authors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      thumbnail: (map['thumbnail'] ?? '').toString(),
      domain: (map['domain'] ?? '').toString(),
      language: (map['language'] ?? '').toString(),
      previewLink: (map['previewLink'] ?? '').toString(),
      isApproved: map['isApproved'] is bool ? map['isApproved'] as bool : true,
      isFeatured: map['isFeatured'] is bool ? map['isFeatured'] as bool : false,
      isHidden: map['isHidden'] is bool ? map['isHidden'] as bool : false,
      rating: _parseDouble(map['rating']),
      learnerCount: parsedLearnerCount,
      learnerCountLabel: _parseLearnerCountLabel(
        map['learnerCountLabel'] ??
            map['enrolledCountLabel'] ??
            rawLearnerCount,
        fallbackCount: parsedLearnerCount,
      ),
      isFree: _parseBool(map['isFree'] ?? map['free']),
      hasCertificate: _parseBool(
        map['hasCertificate'] ?? map['isCertified'] ?? map['certified'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'provider': provider,
      'providerLogo': providerLogo,
      'duration': duration,
      'level': level,
      'link': link,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'createdAt': createdAt,
      'savedAt': savedAt,
      'type': type,
      'source': source,
      'authors': authors,
      'thumbnail': thumbnail,
      'domain': domain,
      'language': language,
      'previewLink': previewLink,
      'isApproved': isApproved,
      'isFeatured': isFeatured,
      'isHidden': isHidden,
      'rating': rating,
      'learnerCount': learnerCount,
      'learnerCountLabel': learnerCountLabel,
      'isFree': isFree,
      'hasCertificate': hasCertificate,
    };
  }

  String get displayLink => link.trim().isNotEmpty ? link : previewLink;

  String get sourceLanguage => ContentLanguage.normalizeCode(language);

  TrainingModel copyWith({
    String? id,
    String? title,
    String? description,
    String? provider,
    String? providerLogo,
    String? duration,
    String? level,
    String? link,
    String? createdBy,
    String? createdByRole,
    Timestamp? createdAt,
    Timestamp? savedAt,
    String? type,
    String? source,
    List<String>? authors,
    String? thumbnail,
    String? domain,
    String? language,
    String? previewLink,
    bool? isApproved,
    bool? isFeatured,
    bool? isHidden,
    double? rating,
    int? learnerCount,
    String? learnerCountLabel,
    bool? isFree,
    bool? hasCertificate,
  }) {
    return TrainingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      provider: provider ?? this.provider,
      providerLogo: providerLogo ?? this.providerLogo,
      duration: duration ?? this.duration,
      level: level ?? this.level,
      link: link ?? this.link,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      createdAt: createdAt ?? this.createdAt,
      savedAt: savedAt ?? this.savedAt,
      type: type ?? this.type,
      source: source ?? this.source,
      authors: authors ?? this.authors,
      thumbnail: thumbnail ?? this.thumbnail,
      domain: domain ?? this.domain,
      language: language ?? this.language,
      previewLink: previewLink ?? this.previewLink,
      isApproved: isApproved ?? this.isApproved,
      isFeatured: isFeatured ?? this.isFeatured,
      isHidden: isHidden ?? this.isHidden,
      rating: rating ?? this.rating,
      learnerCount: learnerCount ?? this.learnerCount,
      learnerCountLabel: learnerCountLabel ?? this.learnerCountLabel,
      isFree: isFree ?? this.isFree,
      hasCertificate: hasCertificate ?? this.hasCertificate,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().trim());
  }

  static int? _parseLearnerCount(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    final normalized = value.toString().trim().toLowerCase();
    if (RegExp(r'[a-z]').hasMatch(normalized)) {
      return null;
    }

    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    return int.tryParse(digitsOnly);
  }

  static String _parseLearnerCountLabel(dynamic value, {int? fallbackCount}) {
    final direct = value?.toString().trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    if (fallbackCount == null || fallbackCount <= 0) {
      return '';
    }
    if (fallbackCount >= 1000000) {
      return '${(fallbackCount / 1000000).toStringAsFixed(1)}m+';
    }
    if (fallbackCount >= 1000) {
      final inThousands = fallbackCount / 1000;
      final hasFraction = fallbackCount % 1000 != 0;
      return '${inThousands.toStringAsFixed(hasFraction ? 1 : 0)}k+';
    }
    return '$fallbackCount+';
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }

    return null;
  }
}
