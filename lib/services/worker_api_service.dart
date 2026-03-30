import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class WorkerApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> get(String path) {
    return _request('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _request('POST', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _request('DELETE', path);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final idToken = await user.getIdToken();
    final uri = Uri.parse('${AppConstants.workerBaseUrl}$path');
    final headers = <String, String>{
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

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
      throw Exception(
        payload['error'] ?? 'Request failed with status ${response.statusCode}',
      );
    }

    return payload;
  }
}
