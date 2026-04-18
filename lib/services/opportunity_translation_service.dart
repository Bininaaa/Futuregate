import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/content_language.dart';
import 'worker_api_service.dart';

enum ContentTranslationType { opportunity, scholarship, training, idea }

extension ContentTranslationTypeValue on ContentTranslationType {
  String get value => switch (this) {
    ContentTranslationType.opportunity => 'opportunity',
    ContentTranslationType.scholarship => 'scholarship',
    ContentTranslationType.training => 'training',
    ContentTranslationType.idea => 'idea',
  };
}

class OpportunityTranslation {
  final Map<String, String> translatedFields;
  final String targetLocale;
  final String sourceLocale;
  final DateTime translatedAt;

  const OpportunityTranslation({
    required this.translatedFields,
    required this.targetLocale,
    required this.sourceLocale,
    required this.translatedAt,
  });

  String get title => field('title');
  String get description => field('description');
  String get requirements => field('requirements');
  String get locale => targetLocale;

  String field(String key) => translatedFields[key]?.trim() ?? '';

  factory OpportunityTranslation.fromMap(Map<String, dynamic> map) {
    final rawFields = map['translatedFields'];
    final translatedFields = <String, String>{};

    if (rawFields is Map) {
      for (final entry in rawFields.entries) {
        final key = entry.key.toString().trim();
        if (key.isEmpty) {
          continue;
        }

        translatedFields[key] = entry.value?.toString().trim() ?? '';
      }
    }

    if (translatedFields.isEmpty) {
      for (final field in const <String>[
        'title',
        'description',
        'requirements',
        'eligibility',
        'shortDescription',
        'tagline',
        'problemStatement',
        'solution',
        'targetAudience',
        'resourcesNeeded',
        'benefits',
      ]) {
        if (!map.containsKey(field)) {
          continue;
        }

        translatedFields[field] = map[field]?.toString().trim() ?? '';
      }
    }

    return OpportunityTranslation(
      translatedFields: translatedFields,
      targetLocale: ContentLanguage.normalizeCode(
        map['targetLocale']?.toString() ?? map['locale']?.toString(),
      ),
      sourceLocale: ContentLanguage.normalizeCode(
        map['sourceLocale']?.toString() ?? map['originalLocale']?.toString(),
      ),
      translatedAt: map['translatedAt'] is Timestamp
          ? (map['translatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({
    required ContentTranslationType contentType,
    required String contentId,
  }) => {
    'contentType': contentType.value,
    'contentId': contentId,
    'sourceLocale': sourceLocale,
    'targetLocale': targetLocale,
    'translatedFields': translatedFields,
    'translatedAt': Timestamp.fromDate(translatedAt),
  };
}

class OpportunityTranslationService {
  static final OpportunityTranslationService _instance =
      OpportunityTranslationService._();
  factory OpportunityTranslationService() => _instance;
  OpportunityTranslationService._();

  final WorkerApiService _api = WorkerApiService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory cache: "${contentType}_${contentId}_${locale}" -> translation
  final Map<String, OpportunityTranslation> _cache = {};

  String _cacheKey({
    required ContentTranslationType contentType,
    required String contentId,
    required String locale,
  }) => '${contentType.value}_${_sanitizeDocKey(contentId)}_$locale';

  String _legacyOpportunityCacheKey(String opportunityId, String locale) =>
      '${_sanitizeDocKey(opportunityId)}_$locale';

  CollectionReference<Map<String, dynamic>> get _contentTranslations =>
      _db.collection('content_translations');

  CollectionReference<Map<String, dynamic>> get _legacyOpportunityTranslations =>
      _db.collection('opportunity_translations');

  /// Fetch cached translation from Firestore, or null if not yet translated.
  Future<OpportunityTranslation?> getCached({
    required ContentTranslationType contentType,
    required String contentId,
    required String locale,
  }) async {
    final normalizedLocale = ContentLanguage.normalizeCode(locale);
    final key = _cacheKey(
      contentType: contentType,
      contentId: contentId,
      locale: normalizedLocale,
    );
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final doc = await _contentTranslations.doc(key).get();
      if (doc.exists && doc.data() != null) {
        final translation = OpportunityTranslation.fromMap(doc.data()!);
        _cache[key] = translation;
        return translation;
      }

      if (contentType == ContentTranslationType.opportunity) {
        final legacyKey = _legacyOpportunityCacheKey(contentId, normalizedLocale);
        final legacyDoc = await _legacyOpportunityTranslations.doc(legacyKey).get();
        if (legacyDoc.exists && legacyDoc.data() != null) {
          final translation = OpportunityTranslation.fromMap(legacyDoc.data()!);
          _cache[key] = translation;
          return translation;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Translate content text fields and persist to Firestore.
  Future<OpportunityTranslation?> translateContent({
    required ContentTranslationType contentType,
    required String contentId,
    required Map<String, String> fields,
    required String targetLocale,
    required String originalLocale,
  }) async {
    final normalizedTargetLocale = ContentLanguage.normalizeCode(targetLocale);
    final normalizedOriginalLocale = ContentLanguage.normalizeCode(
      originalLocale,
    );
    final key = _cacheKey(
      contentType: contentType,
      contentId: contentId,
      locale: normalizedTargetLocale,
    );

    // Check memory cache first
    if (_cache.containsKey(key)) return _cache[key];

    final cleanFields = <String, String>{};
    for (final entry in fields.entries) {
      final fieldKey = entry.key.trim();
      if (fieldKey.isEmpty) {
        continue;
      }

      final value = entry.value.trim();
      if (value.isEmpty) {
        continue;
      }

      cleanFields[fieldKey] = value;
    }

    if (cleanFields.isEmpty) {
      return null;
    }

    final targetLangName = ContentLanguage.englishName(normalizedTargetLocale);
    final originalLangName = ContentLanguage.englishName(
      normalizedOriginalLocale,
    );

    try {
      final translatedEntries = await Future.wait(
        cleanFields.entries.map((entry) async {
          final translatedValue = await _translateText(
            entry.value,
            targetLangName,
            originalLangName,
          );
          return MapEntry(entry.key, translatedValue);
        }),
      );

      final translation = OpportunityTranslation(
        translatedFields: Map<String, String>.fromEntries(translatedEntries),
        targetLocale: normalizedTargetLocale,
        sourceLocale: normalizedOriginalLocale,
        translatedAt: DateTime.now(),
      );

      await _contentTranslations.doc(key).set(
        translation.toMap(contentType: contentType, contentId: contentId),
      );

      _cache[key] = translation;
      return translation;
    } catch (_) {
      return null;
    }
  }

  Future<OpportunityTranslation?> translate({
    required String opportunityId,
    required String title,
    required String description,
    required String requirements,
    required String targetLocale,
    required String originalLocale,
  }) {
    return translateContent(
      contentType: ContentTranslationType.opportunity,
      contentId: opportunityId,
      fields: <String, String>{
        'title': title,
        'description': description,
        'requirements': requirements,
      },
      targetLocale: targetLocale,
      originalLocale: originalLocale,
    );
  }

  Future<String> _translateText(
    String text,
    String targetLangName,
    String originalLangName,
  ) async {
    if (text.trim().isEmpty) return text;
    try {
      final response = await _api.post('/api/ai/message', body: {
        'task': 'translate',
        'text': text,
        'targetLanguage': targetLangName,
        'sourceLanguage': originalLangName,
      });
      if (response['success'] == true && response['result'] is String) {
        return response['result'] as String;
      }
    } catch (_) {}
    return text;
  }

  String _sanitizeDocKey(String value) => value.trim().replaceAll('/', '_');
}
