import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../services/opportunity_translation_service.dart';
import '../utils/content_language.dart';

enum TranslationStatus { idle, loading, ready, failed }

class OpportunityTranslationProvider extends ChangeNotifier {
  final OpportunityTranslationService _service =
      OpportunityTranslationService();

  static const int _maxConcurrentRequests = 2;

  // Per-content state: "${contentType}:${contentId}" -> status
  final Map<String, TranslationStatus> _statusMap = {};
  final Map<String, String> _localeMap = {};

  // Per-content translation data
  final Map<String, OpportunityTranslation> _translations = {};

  // Whether user wants to view translated or original per content item
  final Map<String, bool> _showTranslated = {};

  final Queue<_PendingTranslationRequest> _queue =
      Queue<_PendingTranslationRequest>();
  final Set<String> _queuedRequestKeys = <String>{};
  int _activeRequests = 0;

  TranslationStatus statusFor(String opportunityId) => statusForContent(
    contentType: ContentTranslationType.opportunity,
    contentId: opportunityId,
  );

  TranslationStatus statusForContent({
    required ContentTranslationType contentType,
    required String contentId,
  }) => _statusMap[_scopeKey(contentType, contentId)] ?? TranslationStatus.idle;

  OpportunityTranslation? translationFor(String opportunityId) =>
      translationForContent(
        contentType: ContentTranslationType.opportunity,
        contentId: opportunityId,
      );

  OpportunityTranslation? translationForContent({
    required ContentTranslationType contentType,
    required String contentId,
  }) => _translations[_scopeKey(contentType, contentId)];

  bool isShowingTranslated(String opportunityId) => isShowingTranslatedContent(
    contentType: ContentTranslationType.opportunity,
    contentId: opportunityId,
  );

  bool isShowingTranslatedContent({
    required ContentTranslationType contentType,
    required String contentId,
  }) => _showTranslated[_scopeKey(contentType, contentId)] ?? true;

  String resolvedField({
    required ContentTranslationType contentType,
    required String contentId,
    required String field,
    required String originalValue,
  }) {
    final translation = translationForContent(
      contentType: contentType,
      contentId: contentId,
    );
    final shouldUseTranslation =
        translation != null &&
        statusForContent(contentType: contentType, contentId: contentId) ==
            TranslationStatus.ready &&
        isShowingTranslatedContent(contentType: contentType, contentId: contentId);
    if (!shouldUseTranslation) {
      return originalValue;
    }

    final translatedValue = translation.field(field);
    return translatedValue.trim().isEmpty ? originalValue : translatedValue;
  }

  void toggleTranslated(String opportunityId) {
    toggleTranslatedContent(
      contentType: ContentTranslationType.opportunity,
      contentId: opportunityId,
    );
  }

  void toggleTranslatedContent({
    required ContentTranslationType contentType,
    required String contentId,
  }) {
    final scopeKey = _scopeKey(contentType, contentId);
    _showTranslated[scopeKey] = !(_showTranslated[scopeKey] ?? true);
    notifyListeners();
  }

  /// Load or request a translation for the given opportunity.
  /// [currentLocale] is the app's active locale code (e.g. 'ar').
  /// [originalLocale] is what the opportunity was written in.
  Future<void> ensureTranslation({
    required String opportunityId,
    required String title,
    required String description,
    required String requirements,
    required String currentLocale,
    required String originalLocale,
  }) {
    return ensureContentTranslation(
      contentType: ContentTranslationType.opportunity,
      contentId: opportunityId,
      fields: <String, String>{
        'title': title,
        'description': description,
        'requirements': requirements,
      },
      currentLocale: currentLocale,
      originalLocale: originalLocale,
    );
  }

  Future<void> ensureContentTranslation({
    required ContentTranslationType contentType,
    required String contentId,
    required Map<String, String> fields,
    required String currentLocale,
    required String originalLocale,
  }) async {
    final normalizedContentId = contentId.trim();
    final normalizedCurrentLocale = ContentLanguage.normalizeCode(
      currentLocale,
    );
    final normalizedOriginalLocale = ContentLanguage.normalizeCode(
      originalLocale,
    );
    final scopeKey = _scopeKey(contentType, normalizedContentId);
    final requestKey = '$scopeKey:$normalizedCurrentLocale';

    if (normalizedContentId.isEmpty ||
        normalizedCurrentLocale.isEmpty ||
        normalizedOriginalLocale.isEmpty ||
        normalizedCurrentLocale == normalizedOriginalLocale) {
      return;
    }

    if (_statusMap[scopeKey] == TranslationStatus.ready &&
        _localeMap[scopeKey] == normalizedCurrentLocale) {
      return;
    }

    if ((_statusMap[scopeKey] == TranslationStatus.loading &&
            _localeMap[scopeKey] == normalizedCurrentLocale) ||
        _queuedRequestKeys.contains(requestKey)) {
      return;
    }

    _statusMap[scopeKey] = TranslationStatus.loading;
    _localeMap[scopeKey] = normalizedCurrentLocale;
    notifyListeners();

    final completer = Completer<void>();
    _queue.add(
      _PendingTranslationRequest(
        contentType: contentType,
        contentId: normalizedContentId,
        fields: Map<String, String>.from(fields),
        targetLocale: normalizedCurrentLocale,
        originalLocale: normalizedOriginalLocale,
        completer: completer,
      ),
    );
    _queuedRequestKeys.add(requestKey);
    _pumpQueue();
    await completer.future;
  }

  void reset(String opportunityId) {
    resetContent(
      contentType: ContentTranslationType.opportunity,
      contentId: opportunityId,
    );
  }

  void resetContent({
    required ContentTranslationType contentType,
    required String contentId,
  }) {
    final scopeKey = _scopeKey(contentType, contentId);
    _statusMap.remove(scopeKey);
    _translations.remove(scopeKey);
    _showTranslated.remove(scopeKey);
    _localeMap.remove(scopeKey);
    notifyListeners();
  }

  String _scopeKey(ContentTranslationType contentType, String contentId) =>
      '${contentType.value}:${contentId.trim()}';

  void _pumpQueue() {
    while (_activeRequests < _maxConcurrentRequests && _queue.isNotEmpty) {
      final request = _queue.removeFirst();
      _queuedRequestKeys.remove(request.requestKey);
      unawaited(_runRequest(request));
    }
  }

  Future<void> _runRequest(_PendingTranslationRequest request) async {
    _activeRequests++;
    final scopeKey = _scopeKey(request.contentType, request.contentId);

    try {
      final cached = await _service.getCached(
        contentType: request.contentType,
        contentId: request.contentId,
        locale: request.targetLocale,
      );
      if (cached != null) {
        if (_localeMap[scopeKey] == request.targetLocale) {
          _translations[scopeKey] = cached;
          _statusMap[scopeKey] = TranslationStatus.ready;
          _showTranslated.putIfAbsent(scopeKey, () => true);
          notifyListeners();
        }
        return;
      }

      final result = await _service.translateContent(
        contentType: request.contentType,
        contentId: request.contentId,
        fields: request.fields,
        targetLocale: request.targetLocale,
        originalLocale: request.originalLocale,
      );

      if (_localeMap[scopeKey] != request.targetLocale) {
        return;
      }

      if (result != null) {
        _translations[scopeKey] = result;
        _statusMap[scopeKey] = TranslationStatus.ready;
        _showTranslated.putIfAbsent(scopeKey, () => true);
      } else {
        _statusMap[scopeKey] = TranslationStatus.failed;
      }
      notifyListeners();
    } finally {
      _activeRequests--;
      request.completer.complete();
      _pumpQueue();
    }
  }
}

class _PendingTranslationRequest {
  final ContentTranslationType contentType;
  final String contentId;
  final Map<String, String> fields;
  final String targetLocale;
  final String originalLocale;
  final Completer<void> completer;

  const _PendingTranslationRequest({
    required this.contentType,
    required this.contentId,
    required this.fields,
    required this.targetLocale,
    required this.originalLocale,
    required this.completer,
  });

  String get requestKey => '${contentType.value}:${contentId.trim()}:$targetLocale';
}
