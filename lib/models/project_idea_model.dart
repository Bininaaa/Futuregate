import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/admin_identity.dart';

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
  final Timestamp? updatedAt;
  final String tagline;
  final String shortDescription;
  final String category;
  final List<String> tags;
  final String stage;
  final List<String> skillsNeeded;
  final List<String> teamNeeded;
  final String targetAudience;
  final String problemStatement;
  final String solution;
  final String resourcesNeeded;
  final String benefits;
  final String imageUrl;
  final String attachmentUrl;
  final bool isPublic;
  final bool isHidden;
  final String authorAvatarUrl;
  final String authorPhotoType;
  final String authorAvatarId;
  final int interestedCount;
  final bool isSavedByCurrentUser;
  final bool isJoinedByCurrentUser;
  final String originalLanguage;

  const ProjectIdeaModel({
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
    this.updatedAt,
    this.tagline = '',
    this.shortDescription = '',
    this.category = '',
    this.tags = const <String>[],
    this.stage = '',
    this.skillsNeeded = const <String>[],
    this.teamNeeded = const <String>[],
    this.targetAudience = '',
    this.problemStatement = '',
    this.solution = '',
    this.resourcesNeeded = '',
    this.benefits = '',
    this.imageUrl = '',
    this.attachmentUrl = '',
    this.isPublic = true,
    this.isHidden = false,
    this.authorAvatarUrl = '',
    this.authorPhotoType = '',
    this.authorAvatarId = '',
    this.interestedCount = 0,
    this.isSavedByCurrentUser = false,
    this.isJoinedByCurrentUser = false,
    this.originalLanguage = '',
  });

  factory ProjectIdeaModel.fromMap(Map<String, dynamic> map) {
    final toolsText = (map['tools'] ?? '').toString().trim();
    final skills = _parseStringList(map['skillsNeeded']);
    final team = _parseStringList(map['teamNeeded']);
    final tags = _parseStringList(map['tags']);
    final description = (map['description'] ?? '').toString().trim();
    final shortDescription = (map['shortDescription'] ?? '').toString().trim();

    return ProjectIdeaModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString().trim(),
      description: description,
      domain: (map['domain'] ?? '').toString().trim(),
      level: (map['level'] ?? '').toString().trim(),
      tools: toolsText,
      status: (map['status'] ?? 'pending').toString().trim(),
      submittedBy: (map['submittedBy'] ?? '').toString().trim(),
      submittedByName: AdminIdentity.sanitizeLegacyAdminLabel(
        (map['submittedByName'] ?? '').toString(),
      ),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      tagline: (map['tagline'] ?? '').toString().trim(),
      shortDescription: shortDescription,
      category: (map['category'] ?? '').toString().trim(),
      tags: tags,
      stage: (map['stage'] ?? '').toString().trim(),
      skillsNeeded: skills.isNotEmpty ? skills : _parseStringList(toolsText),
      teamNeeded: team,
      targetAudience: (map['targetAudience'] ?? '').toString().trim(),
      problemStatement: (map['problemStatement'] ?? '').toString().trim(),
      solution: (map['solution'] ?? '').toString().trim(),
      resourcesNeeded: (map['resourcesNeeded'] ?? '').toString().trim(),
      benefits: (map['benefits'] ?? map['impact'] ?? '').toString().trim(),
      imageUrl: (map['imageUrl'] ?? '').toString().trim(),
      attachmentUrl: (map['attachmentUrl'] ?? '').toString().trim(),
      isPublic: _parseBool(map['isPublic'], fallback: true),
      isHidden: _parseBool(map['isHidden']),
      authorAvatarUrl: (map['authorAvatar'] ?? map['authorAvatarUrl'] ?? '')
          .toString()
          .trim(),
      authorPhotoType: (map['authorPhotoType'] ?? '').toString().trim(),
      authorAvatarId: (map['authorAvatarId'] ?? '').toString().trim(),
      interestedCount:
          _parseInt(map['interestedCount']) +
          _parseInt(map['collaboratorsCount']),
      isSavedByCurrentUser: _parseBool(map['isSavedByCurrentUser']),
      isJoinedByCurrentUser: _parseBool(map['isJoinedByCurrentUser']),
      originalLanguage: (map['originalLanguage'] ?? '').toString().trim(),
    );
  }

  ProjectIdeaModel copyWith({
    String? id,
    String? title,
    String? description,
    String? domain,
    String? level,
    String? tools,
    String? status,
    String? submittedBy,
    String? submittedByName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? tagline,
    String? shortDescription,
    String? category,
    List<String>? tags,
    String? stage,
    List<String>? skillsNeeded,
    List<String>? teamNeeded,
    String? targetAudience,
    String? problemStatement,
    String? solution,
    String? resourcesNeeded,
    String? benefits,
    String? imageUrl,
    String? attachmentUrl,
    bool? isPublic,
    bool? isHidden,
    String? authorAvatarUrl,
    String? authorPhotoType,
    String? authorAvatarId,
    int? interestedCount,
    bool? isSavedByCurrentUser,
    bool? isJoinedByCurrentUser,
    String? originalLanguage,
  }) {
    return ProjectIdeaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      domain: domain ?? this.domain,
      level: level ?? this.level,
      tools: tools ?? this.tools,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedByName: submittedByName ?? this.submittedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tagline: tagline ?? this.tagline,
      shortDescription: shortDescription ?? this.shortDescription,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      stage: stage ?? this.stage,
      skillsNeeded: skillsNeeded ?? this.skillsNeeded,
      teamNeeded: teamNeeded ?? this.teamNeeded,
      targetAudience: targetAudience ?? this.targetAudience,
      problemStatement: problemStatement ?? this.problemStatement,
      solution: solution ?? this.solution,
      resourcesNeeded: resourcesNeeded ?? this.resourcesNeeded,
      benefits: benefits ?? this.benefits,
      imageUrl: imageUrl ?? this.imageUrl,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isPublic: isPublic ?? this.isPublic,
      isHidden: isHidden ?? this.isHidden,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorPhotoType: authorPhotoType ?? this.authorPhotoType,
      authorAvatarId: authorAvatarId ?? this.authorAvatarId,
      interestedCount: interestedCount ?? this.interestedCount,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
      isJoinedByCurrentUser:
          isJoinedByCurrentUser ?? this.isJoinedByCurrentUser,
      originalLanguage: originalLanguage ?? this.originalLanguage,
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
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (tagline.isNotEmpty) 'tagline': tagline,
      if (shortDescription.isNotEmpty) 'shortDescription': shortDescription,
      if (category.isNotEmpty) 'category': category,
      if (tags.isNotEmpty) 'tags': tags,
      if (stage.isNotEmpty) 'stage': stage,
      if (skillsNeeded.isNotEmpty) 'skillsNeeded': skillsNeeded,
      if (teamNeeded.isNotEmpty) 'teamNeeded': teamNeeded,
      if (targetAudience.isNotEmpty) 'targetAudience': targetAudience,
      if (problemStatement.isNotEmpty) 'problemStatement': problemStatement,
      if (solution.isNotEmpty) 'solution': solution,
      if (resourcesNeeded.isNotEmpty) 'resourcesNeeded': resourcesNeeded,
      if (benefits.isNotEmpty) 'benefits': benefits,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (attachmentUrl.isNotEmpty) 'attachmentUrl': attachmentUrl,
      'isPublic': isPublic,
      'isHidden': isHidden,
      if (authorAvatarUrl.isNotEmpty) 'authorAvatar': authorAvatarUrl,
      if (authorPhotoType.isNotEmpty) 'authorPhotoType': authorPhotoType,
      if (authorAvatarId.isNotEmpty) 'authorAvatarId': authorAvatarId,
      if (interestedCount > 0) 'interestedCount': interestedCount,
      if (originalLanguage.isNotEmpty) 'originalLanguage': originalLanguage,
    };
  }

  String get displayCategory {
    if (category.trim().isNotEmpty) {
      return category.trim();
    }
    if (domain.trim().isNotEmpty) {
      return domain.trim();
    }
    return 'Innovation';
  }

  String get creatorName {
    final name = AdminIdentity.sanitizeLegacyAdminLabel(submittedByName);
    if (name.isNotEmpty) {
      return name;
    }
    return 'Student Innovator';
  }

  String get displayStage {
    if (stage.trim().isNotEmpty) {
      return stage.trim();
    }
    return 'Concept';
  }

  String get statusLabel {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'Pending';
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String get overviewText {
    for (final value in <String>[
      shortDescription,
      tagline,
      description,
      solution,
      problemStatement,
    ]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'This idea is getting ready for its next breakthrough.';
  }

  String get cardSummary => _truncate(overviewText, 96);

  String get featuredSummary => _truncate(
    description.trim().isNotEmpty ? description : overviewText,
    180,
  );

  List<String> get cardTags {
    final candidates = <String>[
      ...tags,
      ...displaySkills,
      ...displayTeamNeeded,
    ].where((value) => value.trim().isNotEmpty).toList();
    return candidates.take(2).toList(growable: false);
  }

  List<String> get displaySkills {
    if (skillsNeeded.isNotEmpty) {
      return skillsNeeded;
    }
    if (tools.trim().isEmpty) {
      return const <String>[];
    }
    return _parseStringList(tools);
  }

  List<String> get displayTeamNeeded => teamNeeded;

  String get problemText {
    if (problemStatement.trim().isNotEmpty) {
      return problemStatement.trim();
    }
    return '';
  }

  String get solutionText {
    if (solution.trim().isNotEmpty) {
      return solution.trim();
    }
    if (description.trim().isNotEmpty) {
      return description.trim();
    }
    return '';
  }

  String get impactText {
    if (benefits.trim().isNotEmpty) {
      return benefits.trim();
    }
    return '';
  }

  String get creatorHeadline {
    if (displayCategory.trim().isNotEmpty && displayStage.trim().isNotEmpty) {
      return '$displayCategory · $displayStage';
    }
    return displayCategory;
  }

  String get lastUpdatedLabel {
    final timestamp = updatedAt ?? createdAt;
    if (timestamp == null) {
      return 'Updated recently';
    }

    final date = timestamp.toDate();
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes <= 1 ? 1 : difference.inMinutes;
      return 'Updated $minutes min ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours <= 1 ? 1 : difference.inHours;
      return 'Updated $hours hr ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays <= 1 ? 1 : difference.inDays;
      return 'Updated $days day${days == 1 ? '' : 's'} ago';
    }

    return 'Updated ${date.day}/${date.month}/${date.year}';
  }

  static Timestamp? _parseTimestamp(Object? value) {
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

  static List<String> _parseStringList(Object? value) {
    if (value is List) {
      final results = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      return results;
    }

    if (value is String) {
      final normalized = value
          .replaceAll('\n', ',')
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      return normalized;
    }

    return const <String>[];
  }

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  static bool _parseBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }

  static String _truncate(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxLength).trimRight()}...';
  }
}
