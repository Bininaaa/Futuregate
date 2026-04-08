import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/training_model.dart';
import '../utils/constants.dart';

class GoogleBooksService {
  Future<List<TrainingModel>> searchBooks({
    required String query,
    int maxResults = 20,
    String langRestrict = '',
  }) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final token = await _getIdToken();

    final uri = Uri.parse(
      '${AppConstants.workerBaseUrl}/api/search/google-books',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': trimmedQuery,
        'maxResults': maxResults,
        'langRestrict': langRestrict,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        data['error'] ?? 'Google Books search failed: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items.map((item) {
      final map = item as Map<String, dynamic>;

      final authors =
          (map['authors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      final pageCount = map['pageCount'] as int?;
      final durationText = pageCount != null && pageCount > 0
          ? '$pageCount pages'
          : 'Book';

      return TrainingModel(
        id: (map['googleBookId'] ?? '').toString(),
        title: (map['title'] ?? 'Untitled Book').toString(),
        description: (map['description'] ?? '').toString(),
        provider: (map['provider'] ?? 'Google Books').toString(),
        duration: durationText,
        level: 'general',
        link: (map['infoLink'] ?? map['previewLink'] ?? '').toString(),
        createdBy: '',
        createdByRole: 'admin',
        type: 'book',
        source: 'google_books',
        authors: authors,
        thumbnail: (map['thumbnail'] ?? '').toString(),
        domain: '',
        language: (map['language'] ?? '').toString(),
        previewLink: (map['previewLink'] ?? '').toString(),
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
