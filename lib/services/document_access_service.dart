import '../models/secure_document_link.dart';
import 'worker_api_service.dart';

class DocumentAccessService {
  final WorkerApiService _workerApi = WorkerApiService();

  Future<SecureDocumentLink> getApplicationCvDocument({
    required String applicationId,
    required String variant,
  }) async {
    final result = await _workerApi.get(
      '/api/applications/${Uri.encodeComponent(applicationId)}/cv/access?variant=${Uri.encodeQueryComponent(variant)}',
    );

    return _parseDocument(result);
  }

  Future<SecureDocumentLink> getUserCvDocument({
    required String userId,
    required String variant,
  }) async {
    final result = await _workerApi.get(
      '/api/users/${Uri.encodeComponent(userId)}/cv/access?variant=${Uri.encodeQueryComponent(variant)}',
    );

    return _parseDocument(result);
  }

  Future<SecureDocumentLink> getCompanyCommercialRegister({
    required String companyId,
  }) async {
    final result = await _workerApi.get(
      '/api/companies/${Uri.encodeComponent(companyId)}/commercial-register/access',
    );

    return _parseDocument(result);
  }

  Future<SecureDocumentLink> getChatAttachmentDocument({
    required String conversationId,
    required String messageId,
  }) async {
    final result = await _workerApi.get(
      '/api/conversations/${Uri.encodeComponent(conversationId)}/messages/${Uri.encodeComponent(messageId)}/attachment/access',
    );

    return _parseDocument(result);
  }

  SecureDocumentLink _parseDocument(Map<String, dynamic> payload) {
    final document = payload['document'];
    if (document is! Map<String, dynamic>) {
      throw Exception('Document access response is invalid.');
    }

    return SecureDocumentLink.fromMap(document);
  }
}
