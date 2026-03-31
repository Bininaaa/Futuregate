import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/opportunity_type.dart';

class OpportunityModel {
  final String id;
  final String companyId;
  final String companyName;
  final String companyLogo;
  final String title;
  final String description;
  final String type;
  final String location;
  final String requirements;
  final String status;
  final String deadline;
  final Timestamp? createdAt;
  final bool isFeatured;
  final Map<String, dynamic> rawData;

  OpportunityModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.companyLogo,
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    required this.requirements,
    required this.status,
    required this.deadline,
    this.createdAt,
    this.isFeatured = false,
    this.rawData = const {},
  });

  factory OpportunityModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map);

    return OpportunityModel(
      id: data['id'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      companyLogo: data['companyLogo'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: OpportunityType.parse(data['type']),
      location: data['location'] ?? '',
      requirements: data['requirements'] ?? '',
      status: data['status'] ?? '',
      deadline: data['deadline'] ?? '',
      createdAt: data['createdAt'],
      isFeatured: data['isFeatured'] ?? false,
      rawData: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...rawData,
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'title': title,
      'description': description,
      'type': type,
      'location': location,
      'requirements': requirements,
      'status': status,
      'deadline': deadline,
      'createdAt': createdAt,
      'isFeatured': isFeatured,
    };
  }

  dynamic firstValue(List<String> keys) {
    for (final key in keys) {
      if (!rawData.containsKey(key)) {
        continue;
      }

      final value = rawData[key];
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String? readString(List<String> keys) {
    return _stringFromValue(firstValue(keys));
  }

  bool? readBool(List<String> keys) {
    final value = firstValue(keys);

    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) {
        return null;
      }
      if (['true', 'yes', 'y', '1', 'paid'].contains(normalized)) {
        return true;
      }
      if (['false', 'no', 'n', '0', 'unpaid'].contains(normalized)) {
        return false;
      }
    }

    return null;
  }

  DateTime? readDateTime(List<String> keys) {
    final value = firstValue(keys);

    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return DateTime.tryParse(trimmed);
    }

    return null;
  }

  String? _stringFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is num) {
      return value.toString();
    }

    if (value is List) {
      final parts = value
          .map(_stringFromValue)
          .whereType<String>()
          .where((part) => part.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    }

    if (value is Map) {
      final display = _stringFromValue(
        value['display'] ?? value['label'] ?? value['text'] ?? value['value'],
      );
      if (display != null) {
        return display;
      }

      final currency = _stringFromValue(value['currency'] ?? value['unit']);
      final amount = _stringFromValue(value['amount']);
      if (amount != null) {
        return currency == null ? amount : '$currency $amount';
      }

      final min = _stringFromValue(
        value['min'] ?? value['from'] ?? value['start'],
      );
      final max = _stringFromValue(value['max'] ?? value['to'] ?? value['end']);
      if (min != null && max != null) {
        final range = '$min - $max';
        return currency == null ? range : '$currency $range';
      }
    }

    return null;
  }
}
