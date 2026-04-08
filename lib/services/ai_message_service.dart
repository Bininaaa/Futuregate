import '../services/worker_api_service.dart';

class AiMessageService {
  final WorkerApiService _api = WorkerApiService();

  /// Formalize, correct, or translate a chat message via the backend.
  ///
  /// [task] must be one of: `formal`, `correct`, `translate`.
  /// [text] is the raw user message.
  /// [targetLanguage] is required only when [task] is `translate`.
  Future<String> processMessage({
    required String task,
    required String text,
    String? targetLanguage,
  }) async {
    final body = <String, dynamic>{'task': task, 'text': text};
    if (targetLanguage != null) {
      body['targetLanguage'] = targetLanguage;
    }

    final response = await _api.post('/api/ai/message', body: body);

    if (response['success'] == true && response['result'] is String) {
      return response['result'] as String;
    }

    throw Exception(response['error'] ?? 'AI processing failed');
  }
}
