import 'package:flutter/foundation.dart';

import 'worker_api_service.dart';

class NotificationWorkerService {
  final WorkerApiService _workerApi = WorkerApiService();

  Future<void> notifyOpportunityCreated(String opportunityId) {
    return _postBestEffort(
      '/api/notify/opportunity',
      {'opportunityId': opportunityId},
      contextLabel: 'opportunity notification',
    );
  }

  Future<void> notifyScholarshipCreated(String scholarshipId) {
    return _postBestEffort(
      '/api/notify/scholarship',
      {'scholarshipId': scholarshipId},
      contextLabel: 'scholarship notification',
    );
  }

  Future<void> notifyApplicationSubmitted(String applicationId) {
    return _postBestEffort(
      '/api/notify/application-submitted',
      {'applicationId': applicationId},
      contextLabel: 'application submitted notification',
    );
  }

  Future<void> notifyApplicationStatusChanged(String applicationId) {
    return _postBestEffort(
      '/api/notify/application-status-changed',
      {'applicationId': applicationId},
      contextLabel: 'application status notification',
    );
  }

  Future<void> notifyProjectIdeaSubmitted(String ideaId) {
    return _postBestEffort(
      '/api/notify/project-idea-submitted',
      {'ideaId': ideaId},
      contextLabel: 'project idea submitted notification',
    );
  }

  Future<void> notifyProjectIdeaStatusChanged(String ideaId) {
    return _postBestEffort(
      '/api/notify/idea-status-changed',
      {'ideaId': ideaId},
      contextLabel: 'project idea status notification',
    );
  }

  Future<void> notifyChatMessage({
    required String conversationId,
    required String messageId,
    required String message,
  }) {
    return _postBestEffort(
      '/api/notify/chat-message',
      {
        'conversationId': conversationId,
        'messageId': messageId,
        'message': message,
      },
      contextLabel: 'chat notification',
    );
  }

  Future<void> _postBestEffort(
    String path,
    Map<String, dynamic> body, {
    required String contextLabel,
  }) async {
    try {
      await _workerApi.post(path, body: body);
    } catch (error) {
      debugPrint('Worker $contextLabel failed: $error');
    }
  }
}
