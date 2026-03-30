import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'worker_api_service.dart';

class PublicProfileService {
  PublicProfileService._();

  static final PublicProfileService instance = PublicProfileService._();

  final WorkerApiService _workerApi = WorkerApiService();
  final Map<String, Future<UserModel?>> _inFlightRequests = {};

  Future<UserModel?> fetchPublicProfile(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Future.value(null);
    }

    final existingRequest = _inFlightRequests[normalizedUserId];
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _loadPublicProfile(normalizedUserId);
    _inFlightRequests[normalizedUserId] = request;
    request.whenComplete(() {
      _inFlightRequests.remove(normalizedUserId);
    });

    return request;
  }

  Future<UserModel?> _loadPublicProfile(String userId) async {
    try {
      final response = await _workerApi.get(
        '/api/users/${Uri.encodeComponent(userId)}/public-profile',
      );
      final payload = response['user'];
      if (payload is Map<String, dynamic>) {
        return UserModel.fromMap(payload);
      }
    } catch (e) {
      debugPrint('fetchPublicProfile error for $userId: $e');
    }

    return null;
  }
}
