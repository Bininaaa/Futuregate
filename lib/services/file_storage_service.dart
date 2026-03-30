import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/cloudflare_storage_config.dart';

class StoredFileUploadResult {
  final String objectKey;
  final String bucketName;
  final String fileName;
  final String fileUrl;
  final String storagePath;
  final String mimeType;
  final int sizeOriginal;
  final String fileType;

  const StoredFileUploadResult({
    required this.objectKey,
    required this.bucketName,
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
    required this.mimeType,
    required this.sizeOriginal,
    required this.fileType,
  });
}

typedef UploadedCvFile = StoredFileUploadResult;

class FileStorageService {
  FileStorageService({http.Client? httpClient, FirebaseAuth? auth})
    : _httpClient = httpClient ?? http.Client(),
      _auth = auth ?? FirebaseAuth.instance;

  final http.Client _httpClient;
  final FirebaseAuth _auth;

  Future<StoredFileUploadResult> uploadOriginalCv({
    required String userId,
    required String filePath,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    final sanitizedFileName = _sanitizeFileName(fileName);
    final mimeType = _resolveMimeType(
      fileName: sanitizedFileName,
      fallback: 'application/pdf',
    );

    return _uploadFile(
      userId: userId,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: sanitizedFileName,
      mimeType: mimeType,
      fileType: 'original_cv',
    );
  }

  Future<StoredFileUploadResult> uploadGeneratedPdf({
    required String userId,
    required Uint8List bytes,
    required String templateId,
  }) async {
    final safeTemplateId = templateId.trim().isEmpty
        ? 'default'
        : _sanitizeFileName(templateId);
    final fileName = 'cv_$safeTemplateId.pdf';

    return _uploadFile(
      userId: userId,
      filePath: '',
      fileBytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
      fileType: 'generated_cv',
      templateId: safeTemplateId,
    );
  }

  Future<StoredFileUploadResult> uploadProfilePhoto({
    required String userId,
    required String fileName,
    Uint8List? fileBytes,
    String filePath = '',
  }) async {
    final sanitizedFileName = _sanitizeFileName(fileName);
    final mimeType = _resolveMimeType(
      fileName: sanitizedFileName,
      fallback: 'image/jpeg',
    );

    return _uploadFile(
      userId: userId,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: sanitizedFileName,
      mimeType: mimeType,
      fileType: 'profile_photo',
    );
  }

  Future<StoredFileUploadResult> uploadCommercialRegister({
    required String userId,
    required String filePath,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    final sanitizedFileName = _sanitizeFileName(fileName);
    final mimeType = _resolveMimeType(
      fileName: sanitizedFileName,
      fallback: 'application/pdf',
    );

    return _uploadFile(
      userId: userId,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: sanitizedFileName,
      mimeType: mimeType,
      fileType: 'commercial_register',
    );
  }

  Future<void> deleteFileByPath(String storagePath) async {
    var objectKey = storagePath.trim();
    if (objectKey.startsWith('http://') || objectKey.startsWith('https://')) {
      objectKey = _extractObjectKeyFromUrl(objectKey);
    }
    if (objectKey.isEmpty || objectKey.startsWith('buckets/')) return;

    final response = await _httpClient.delete(
      _buildFileUri(objectKey),
      headers: await _buildAuthHeaders(),
    );
    try {
      await _parseSuccessResponse(response);
    } on Exception catch (error) {
      throw Exception('Failed to delete file from Cloudflare R2: $error');
    }
  }

  Future<StoredFileUploadResult> _uploadFile({
    required String userId,
    required String filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String mimeType,
    required String fileType,
    String templateId = '',
  }) {
    if (fileBytes == null && filePath.trim().isEmpty) {
      throw ArgumentError(
        'filePath is required when fileBytes is not provided.',
      );
    }

    if (kIsWeb) {
      if (fileBytes == null) {
        throw ArgumentError(
          'Web uploads require fileBytes because file paths are not available.',
        );
      }
    }

    return _sendUploadRequest(
      userId: userId,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
      fileType: fileType,
      templateId: templateId,
    );
  }

  Future<StoredFileUploadResult> _sendUploadRequest({
    required String userId,
    required String filePath,
    required Uint8List? fileBytes,
    required String fileName,
    required String mimeType,
    required String fileType,
    required String templateId,
  }) async {
    final uri = _buildUploadUri();
    final authHeaders = await _buildAuthHeaders();

    final request = http.MultipartRequest('POST', uri)
      ..fields['userId'] = userId
      ..fields['fileName'] = fileName
      ..fields['mimeType'] = mimeType
      ..fields['fileType'] = fileType;

    if (templateId.trim().isNotEmpty) {
      request.fields['templateId'] = templateId.trim();
    }

    request.headers.addAll(authHeaders);

    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );
    }

    debugPrint(
      '[FileStorageService] POST $uri (fileType=$fileType, fileName=$fileName)',
    );

    final http.Response response;
    try {
      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } catch (e) {
      debugPrint('[FileStorageService] Network error: $e');
      throw Exception('Network error while uploading: $e');
    }

    debugPrint(
      '[FileStorageService] Response ${response.statusCode}: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
    );

    final responseBody = await _parseSuccessResponse(response);

    return StoredFileUploadResult(
      objectKey: (responseBody['objectKey'] ?? '') as String,
      bucketName:
          (responseBody['bucketName'] ?? CloudflareStorageConfig.bucketName)
              as String,
      fileName: (responseBody['fileName'] ?? fileName) as String,
      fileUrl: (responseBody['url'] ?? '') as String,
      storagePath: (responseBody['objectKey'] ?? '') as String,
      mimeType: (responseBody['mimeType'] ?? mimeType) as String,
      sizeOriginal: _parseInt(responseBody['sizeOriginal']),
      fileType: (responseBody['fileType'] ?? fileType) as String,
    );
  }

  Future<Map<String, dynamic>> _parseSuccessResponse(
    http.Response response,
  ) async {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      } else {
        throw Exception(
          'Server returned unexpected format (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('Server returned unexpected')) {
        rethrow;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'Authentication failed (HTTP ${response.statusCode}). Please sign in again.',
        );
      }

      final bodyPreview = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw Exception(
        'Server error (HTTP ${response.statusCode}): $bodyPreview',
      );
    }

    final isSuccess =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        payload['success'] == true;

    if (!isSuccess) {
      final serverError = (payload['error'] ?? payload['message'] ?? '')
          .toString();

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          serverError.isNotEmpty
              ? 'Auth error: $serverError'
              : 'Authentication failed. Please sign in again.',
        );
      }

      throw Exception(
        serverError.isNotEmpty
            ? serverError
            : 'Upload failed (HTTP ${response.statusCode})',
      );
    }

    return payload;
  }

  String _resolveMimeType({
    required String fileName,
    required String fallback,
  }) {
    final extension = fileName.toLowerCase().split('.').length > 1
        ? fileName.toLowerCase().split('.').last
        : '';

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return fallback;
    }
  }

  String _sanitizeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[^\w\.\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  Future<Map<String, String>> _buildAuthHeaders() async {
    final headers = <String, String>{'Accept': 'application/json'};

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[FileStorageService] Warning: No authenticated user');
      return headers;
    }

    try {
      final idToken = await currentUser.getIdToken();
      if ((idToken ?? '').trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $idToken';
      }
    } catch (e) {
      debugPrint('[FileStorageService] Failed to get ID token: $e');
    }

    return headers;
  }

  Uri _buildUploadUri() {
    return Uri.parse(CloudflareStorageConfig.workerUrl).resolve('upload');
  }

  Uri _buildFileUri(String objectKey) {
    final encodedObjectKey = objectKey
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');

    return Uri.parse(
      CloudflareStorageConfig.workerUrl,
    ).resolve('file/$encodedObjectKey');
  }

  int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  String _extractObjectKeyFromUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return '';
    }

    final segments = uri.pathSegments;
    final fileSegmentIndex = segments.indexOf('file');
    if (fileSegmentIndex == -1 || fileSegmentIndex == segments.length - 1) {
      return '';
    }

    return segments
        .skip(fileSegmentIndex + 1)
        .map(Uri.decodeComponent)
        .join('/');
  }
}

class StorageService extends FileStorageService {
  StorageService({super.httpClient, super.auth});
}
