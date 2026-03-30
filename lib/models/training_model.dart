import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingModel {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String duration;
  final String level;
  final String link;
  final String createdBy;
  final String createdByRole;
  final Timestamp? createdAt;

  final String type; // training, book, course, file, video
  final String source; // internal, google_books, youtube, etc
  final List<String> authors;
  final String thumbnail;
  final String domain;
  final String language;
  final String previewLink;
  final bool isApproved;
  final bool isFeatured;

  TrainingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    required this.duration,
    required this.level,
    required this.link,
    required this.createdBy,
    required this.createdByRole,
    this.createdAt,
    this.type = 'training',
    this.source = 'internal',
    this.authors = const [],
    this.thumbnail = '',
    this.domain = '',
    this.language = '',
    this.previewLink = '',
    this.isApproved = true,
    this.isFeatured = false,
  });

  factory TrainingModel.fromMap(Map<String, dynamic> map) {
    return TrainingModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      provider: (map['provider'] ?? '').toString(),
      duration: (map['duration'] ?? '').toString(),
      level: (map['level'] ?? '').toString(),
      link: (map['link'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByRole: (map['createdByRole'] ?? '').toString(),
      createdAt: map['createdAt'] as Timestamp?,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'provider': provider,
      'duration': duration,
      'level': level,
      'link': link,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'createdAt': createdAt,
      'type': type,
      'source': source,
      'authors': authors,
      'thumbnail': thumbnail,
      'domain': domain,
      'language': language,
      'previewLink': previewLink,
      'isApproved': isApproved,
      'isFeatured': isFeatured,
    };
  }

  String get displayLink => link.trim().isNotEmpty ? link : previewLink;

  TrainingModel copyWith({
    String? id,
    String? title,
    String? description,
    String? provider,
    String? duration,
    String? level,
    String? link,
    String? createdBy,
    String? createdByRole,
    Timestamp? createdAt,
    String? type,
    String? source,
    List<String>? authors,
    String? thumbnail,
    String? domain,
    String? language,
    String? previewLink,
    bool? isApproved,
    bool? isFeatured,
  }) {
    return TrainingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      provider: provider ?? this.provider,
      duration: duration ?? this.duration,
      level: level ?? this.level,
      link: link ?? this.link,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      source: source ?? this.source,
      authors: authors ?? this.authors,
      thumbnail: thumbnail ?? this.thumbnail,
      domain: domain ?? this.domain,
      language: language ?? this.language,
      previewLink: previewLink ?? this.previewLink,
      isApproved: isApproved ?? this.isApproved,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
