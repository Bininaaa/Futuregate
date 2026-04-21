import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/training_model.dart';
import '../utils/constants.dart';
import '../utils/content_language.dart';

class YoutubeService {
  Future<List<TrainingModel>> searchVideos({
    required String query,
    int maxResults = 12,
    String language = '',
  }) async {
    final trimmedQuery = query.trim();
    final normalizedLanguage = ContentLanguage.normalizeCode(language);

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final token = await _getIdToken();

    final uri = Uri.parse('${AppConstants.workerBaseUrl}/api/search/youtube');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': trimmedQuery,
        'maxResults': maxResults,
        'language': normalizedLanguage,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        data['error'] ??
            'Could not complete YouTube search. Please try again later.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final videoId = (map['youtubeVideoId'] ?? '').toString().trim();

      return TrainingModel(
        id: videoId,
        title: (map['title'] ?? 'Untitled Video').toString().trim().isEmpty
            ? 'Untitled Video'
            : (map['title'] ?? 'Untitled Video').toString().trim(),
        description: (map['description'] ?? '').toString().trim(),
        provider: (map['provider'] ?? 'YouTube').toString(),
        duration: 'Video',
        level: 'general',
        link: (map['link'] ?? 'https://www.youtube.com/watch?v=$videoId')
            .toString(),
        createdBy: '',
        createdByRole: 'admin',
        type: 'video',
        source: 'youtube',
        thumbnail: (map['thumbnail'] ?? '').toString(),
        domain: '',
        language: '',
        previewLink: 'https://www.youtube.com/watch?v=$videoId',
        isApproved: true,
        isFeatured: false,
      );
    }).toList();
  }

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    return await user.getIdToken() ?? '';
  }
}
