import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class WorkerApiException implements Exception {
  const WorkerApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class WorkerApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> get(String path) {
    return _request('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _request('POST', path, body: body);
  }

  Future<Map<String, dynamic>> postPublic(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _request('POST', path, body: body, requireAuth: false);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _request('DELETE', path);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    String? idToken;
    if (requireAuth) {
      final user = _auth.currentUser;
      if (user == null) {
        throw const WorkerApiException(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }
      idToken = await user.getIdToken();
    }
    final uri = Uri.parse('${AppConstants.workerBaseUrl}$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idToken != null && idToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    Map<String, dynamic> payload = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WorkerApiException(
        message:
            (payload['error'] ??
                    'Request failed with status ${response.statusCode}')
                .toString(),
        statusCode: response.statusCode,
      );
    }

    return payload;
  }
}
