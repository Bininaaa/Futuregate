import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'opportunity_type.dart';

class OpportunityMetadata {
  OpportunityMetadata._();

  static const List<String> employmentTypes = [
    'full_time',
    'part_time',
    'internship',
    'contract',
    'temporary',
    'freelance',
  ];

  static const List<String> jobEmploymentTypes = [
    'full_time',
    'part_time',
    'contract',
    'temporary',
    'freelance',
  ];

  static const List<String> internshipEmploymentTypes = ['internship'];

  static const List<String> workModes = ['onsite', 'remote', 'hybrid'];

  static const List<String> salaryPeriods = [
    'hour',
    'day',
    'week',
    'month',
    'year',
  ];

  static const List<String> supportedCurrencies = ['DZD', 'USD', 'EUR'];

  static bool usesStructuredFields(String? type) {
    final normalizedType = OpportunityType.parse(type);
    return normalizedType == OpportunityType.job ||
        normalizedType == OpportunityType.internship;
  }

  static bool usesFundingFields(String? type) {
    return OpportunityType.parse(type) == OpportunityType.sponsoring;
  }

  static List<String> employmentTypesForOpportunityType(String? type) {
    return switch (OpportunityType.parse(type)) {
      OpportunityType.internship => internshipEmploymentTypes,
      OpportunityType.job => jobEmploymentTypes,
      OpportunityType.sponsoring => const <String>[],
      _ => employmentTypes,
    };
  }

  static dynamic firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (!data.containsKey(key)) {
        continue;
      }

      final value = data[key];
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static String? stringFromValue(dynamic value) {
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
          .map(stringFromValue)
          .whereType<String>()
          .where((part) => part.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    }

    if (value is Map) {
      final display = stringFromValue(
        value['display'] ?? value['label'] ?? value['text'] ?? value['value'],
      );
      if (display != null) {
        return display;
      }

      final currency = stringFromValue(value['currency'] ?? value['unit']);
      final amount = stringFromValue(value['amount']);
      if (amount != null) {
        return currency == null ? amount : '$currency $amount';
      }

      final min = stringFromValue(
        value['min'] ?? value['from'] ?? value['start'],
      );
      final max = stringFromValue(value['max'] ?? value['to'] ?? value['end']);
      if (min != null && max != null) {
        final range = '$min - $max';
        return currency == null ? range : '$currency $range';
      }
    }

    return null;
  }

  static List<String> stringListFromValue(
    dynamic value, {
    int maxItems = 12,
    bool splitOnCommas = true,
  }) {
    if (value == null) {
      return const [];
    }

    final items = <String>[];

    void addValue(dynamic next) {
      if (next == null) {
        return;
      }

      if (next is List) {
        for (final item in next) {
          addValue(item);
        }
        return;
      }

      if (next is Map) {
        final nested =
            next['items'] ??
            next['values'] ??
            next['list'] ??
            next['data'] ??
            next['tags'] ??
            next['benefits'] ??
            next['requirements'];
        if (nested != null) {
          addValue(nested);
          return;
        }

        final display = stringFromValue(next);
        if (display != null) {
          addValue(display);
        }
        return;
      }

      final text = stringFromValue(next);
      if (text == null) {
        return;
      }

      final normalized = text.replaceAll('\r', '\n').trim();
      if (normalized.isEmpty) {
        return;
      }

      final separatorPattern = splitOnCommas
          ? RegExp('\\n+|;|\\||(?<!\\d),(?!\\d)|\\u2022')
          : RegExp('\\n+|;|\\||\\u2022');
      final splitCandidates = normalized
          .split(separatorPattern)
          .map(_normalizeListItem)
          .whereType<String>()
          .toList();

      if (splitCandidates.length > 1) {
        items.addAll(splitCandidates);
        return;
      }

      final single = _normalizeListItem(normalized);
      if (single != null) {
        items.add(single);
      }
    }

    addValue(value);
    return uniqueNonEmpty(items).take(maxItems).toList();
  }

  static String? sanitizeText(String? rawValue) {
    final trimmed = rawValue?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static List<String> extractTags(
    Map<String, dynamic> data, {
    String? type,
    String? employmentType,
    String? workMode,
    bool isFeatured = false,
    String? compensationText,
  }) {
    final explicitTags = stringListFromValue(
      firstValue(data, [
        'tags',
        'tag',
        'labels',
        'badges',
        'badgeLabels',
        'highlightTags',
        'pills',
      ]),
      maxItems: 6,
    );
    if (explicitTags.isNotEmpty) {
      return explicitTags;
    }

    final tags = <String>[];
    final normalizedType = OpportunityType.parse(type);
    final employmentLabel = formatEmploymentType(employmentType);
    final workModeLabel = formatWorkMode(workMode);
    final lowerCompensation = compensationText?.trim().toLowerCase();

    if (employmentLabel != null) {
      tags.add(employmentLabel.toUpperCase());
    }
    if (workModeLabel != null) {
      tags.add(workModeLabel.toUpperCase());
    }

    switch (normalizedType) {
      case OpportunityType.internship:
        tags.addAll(const ['INTERNSHIP', 'LEARNING']);
        break;
      case OpportunityType.sponsoring:
        if (isFeatured) {
          tags.add('FEATURED');
        } else {
          tags.add('SPONSORED');
        }
        break;
      case OpportunityType.job:
        break;
    }

    if (lowerCompensation != null) {
      if (lowerCompensation.contains('fully funded') ||
          lowerCompensation.contains('full funding')) {
        tags.add('FULLY FUNDED');
      } else if (lowerCompensation.contains('stipend')) {
        tags.add('STIPEND');
      }
    }

    return uniqueNonEmpty(tags).take(6).toList();
  }

  static List<String> extractRequirementItems(
    Map<String, dynamic> data, {
    String? fallbackText,
    int maxItems = 8,
  }) {
    final explicitItems = stringListFromValue(
      firstValue(data, [
        'requirementsList',
        'requirements_list',
        'requirementItems',
        'requirement_items',
        'eligibilityItems',
        'eligibility_items',
        'skills',
        'qualifications',
        'mustHaves',
        'must_haves',
        'criteria',
      ]),
      maxItems: maxItems,
      splitOnCommas: false,
    );
    if (explicitItems.isNotEmpty) {
      return explicitItems;
    }

    return stringListFromValue(
      fallbackText,
      maxItems: maxItems,
      splitOnCommas: false,
    );
  }

  static List<String> extractBenefits(
    Map<String, dynamic> data, {
    required String type,
    String? workMode,
    bool isFeatured = false,
    bool? isPaid,
    String? compensationText,
  }) {
    final explicitBenefits = stringListFromValue(
      firstValue(data, [
        'benefits',
        'benefitList',
        'benefit_list',
        'perks',
        'perkList',
        'perk_list',
        'advantages',
        'offerings',
        'whatYouGet',
        'support',
      ]),
      maxItems: 8,
    );
    if (explicitBenefits.isNotEmpty) {
      return explicitBenefits;
    }

    final benefits = <String>[];
    final normalizedType = OpportunityType.parse(type);
    final normalizedWorkMode = normalizeWorkMode(workMode);
    final normalizedCompensation = sanitizeText(compensationText);

    if (normalizedCompensation != null) {
      benefits.add(normalizedCompensation);
    } else if (isPaid == true) {
      benefits.add(
        normalizedType == OpportunityType.sponsoring
            ? 'Funding included'
            : 'Paid opportunity',
      );
    }

    switch (normalizedWorkMode) {
      case 'remote':
        benefits.add('Remote-friendly setup');
        break;
      case 'hybrid':
        benefits.add('Hybrid work format');
        break;
      case 'onsite':
      case null:
        break;
    }

    if (normalizedType == OpportunityType.sponsoring && isFeatured) {
      benefits.add('Featured sponsored placement');
    }

    return uniqueNonEmpty(benefits).take(6).toList();
  }

  static String? normalizeCurrency(String? rawValue) {
    final trimmed = rawValue?.trim().toUpperCase();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static String? normalizeEmploymentType(String? rawValue) {
    final normalized = rawValue
        ?.trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return switch (normalized) {
      'full_time' || 'fulltime' => 'full_time',
      'part_time' || 'parttime' => 'part_time',
      'intern' || 'internship' => 'internship',
      'contract' => 'contract',
      'temporary' || 'temp' => 'temporary',
      'freelance' || 'freelancer' => 'freelance',
      _ => employmentTypes.contains(normalized) ? normalized : null,
    };
  }

  static String? normalizeWorkMode(String? rawValue) {
    final normalized = rawValue
        ?.trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return switch (normalized) {
      'onsite' || 'onsiteonly' || 'office' => 'onsite',
      'remote' || 'remotefriendly' => 'remote',
      'hybrid' => 'hybrid',
      _ => null,
    };
  }

  static String? normalizeSalaryPeriod(String? rawValue) {
    final normalized = rawValue
        ?.trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return switch (normalized) {
      'hour' || 'hourly' || 'per_hour' => 'hour',
      'day' || 'daily' || 'per_day' => 'day',
      'week' || 'weekly' || 'per_week' => 'week',
      'month' || 'monthly' || 'per_month' => 'month',
      'year' || 'yearly' || 'annually' || 'annual' || 'per_year' => 'year',
      _ => salaryPeriods.contains(normalized) ? normalized : null,
    };
  }

  static String? normalizeDuration(String? rawValue) {
    final trimmed = rawValue?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static num? parseNullableNum(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final normalized = trimmed.replaceAll(RegExp(r'[^0-9.\-]'), '');
      if (normalized.isEmpty ||
          normalized == '-' ||
          normalized == '.' ||
          normalized == '-.') {
        return null;
      }

      return num.tryParse(normalized);
    }

    return null;
  }

  static bool? parseNullableBool(Object? value) {
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

  static DateTime? parseDateTimeLike(Object? value) {
    if (value == null) {
      return null;
    }

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

      final direct = DateTime.tryParse(trimmed);
      if (direct != null) {
        return direct;
      }

      final formats = [
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('dd-MM-yyyy'),
        DateFormat('MMM d, yyyy'),
        DateFormat('d MMM yyyy'),
        DateFormat('MMMM d, yyyy'),
        DateFormat('d MMMM yyyy'),
      ];

      for (final format in formats) {
        try {
          return format.parseStrict(trimmed);
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  static Timestamp? toTimestampOrNull(DateTime? value) {
    if (value == null) {
      return null;
    }

    return Timestamp.fromDate(value);
  }

  static DateTime normalizeDateToEndOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999, 999);
  }

  static DateTime? normalizeDeadline(Object? value) {
    final parsed = parseDateTimeLike(value);
    if (parsed == null) {
      return null;
    }

    final isDateOnly =
        parsed.hour == 0 &&
        parsed.minute == 0 &&
        parsed.second == 0 &&
        parsed.millisecond == 0 &&
        parsed.microsecond == 0;
    return isDateOnly ? normalizeDateToEndOfDay(parsed) : parsed;
  }

  static bool isDeadlineExpired(Object? value, {DateTime? now}) {
    final deadline = normalizeDeadline(value);
    if (deadline == null) {
      return false;
    }

    final currentTime = now ?? DateTime.now();
    return !deadline.isAfter(currentTime);
  }

  static String formatDateForStorage(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  static String formatDateLabel(
    DateTime value, {
    String pattern = 'MMM d, yyyy',
  }) {
    return DateFormat(pattern).format(value);
  }

  static num? extractSalaryMin(Map<String, dynamic> data) {
    final salaryObject = data['salary'];
    return parseNullableNum(
      firstValue(data, ['salaryMin', 'salary_min']) ??
          (salaryObject is Map
              ? salaryObject['min'] ?? salaryObject['from']
              : null),
    );
  }

  static num? extractSalaryMax(Map<String, dynamic> data) {
    final salaryObject = data['salary'];
    return parseNullableNum(
      firstValue(data, ['salaryMax', 'salary_max']) ??
          (salaryObject is Map
              ? salaryObject['max'] ?? salaryObject['to']
              : null),
    );
  }

  static String? extractSalaryCurrency(Map<String, dynamic> data) {
    final salaryObject = data['salary'];
    return normalizeCurrency(
      stringFromValue(
        firstValue(data, ['salaryCurrency', 'currency']) ??
            (salaryObject is Map ? salaryObject['currency'] : null),
      ),
    );
  }

  static String? extractSalaryPeriod(Map<String, dynamic> data) {
    final salaryObject = data['salary'];
    return normalizeSalaryPeriod(
      stringFromValue(
        firstValue(data, [
              'salaryPeriod',
              'payPeriod',
              'salaryFrequency',
              'compensationPeriod',
            ]) ??
            (salaryObject is Map ? salaryObject['period'] : null),
      ),
    );
  }

  static String? extractCompensationText(Map<String, dynamic> data) {
    final salaryObject = data['salary'];
    return sanitizeText(
      stringFromValue(
        firstValue(data, [
              'compensationText',
              'salaryText',
              'salaryRange',
              'salary_range',
              'stipend',
              'stipendAmount',
              'stipend_amount',
              'compensation',
              'payment',
              'pay',
              'payRange',
              'pay_range',
              'amount',
              'budget',
              'reward',
            ]) ??
            (salaryObject is Map
                ? salaryObject['display'] ??
                      salaryObject['label'] ??
                      salaryObject['text']
                : null),
      ),
    );
  }

  static num? extractFundingAmount(Map<String, dynamic> data) {
    final fundingObject = data['funding'];
    return parseNullableNum(
      firstValue(data, [
            'fundingAmount',
            'funding_amount',
            'fundAmount',
            'fund_amount',
            'sponsorshipAmount',
            'sponsorship_amount',
            'companyFundingAmount',
            'company_funding_amount',
          ]) ??
          (fundingObject is Map
              ? fundingObject['amount'] ??
                    fundingObject['value'] ??
                    fundingObject['total']
              : null),
    );
  }

  static String? extractFundingCurrency(Map<String, dynamic> data) {
    final fundingObject = data['funding'];
    return normalizeCurrency(
      stringFromValue(
        firstValue(data, [
              'fundingCurrency',
              'funding_currency',
              'fundCurrency',
              'fund_currency',
              'sponsorshipCurrency',
              'sponsorship_currency',
            ]) ??
            (fundingObject is Map ? fundingObject['currency'] : null),
      ),
    );
  }

  static String? extractFundingNote(Map<String, dynamic> data) {
    final fundingObject = data['funding'];
    return sanitizeText(
      stringFromValue(
        firstValue(data, [
              'fundingNote',
              'funding_note',
              'fundingText',
              'funding_text',
              'fundingDescription',
              'funding_description',
              'fundingDetails',
              'funding_details',
              'sponsorshipNote',
              'sponsorship_note',
              'supportDetails',
              'support_details',
            ]) ??
            (fundingObject is Map
                ? fundingObject['note'] ??
                      fundingObject['display'] ??
                      fundingObject['label'] ??
                      fundingObject['text']
                : null),
      ),
    );
  }

  static String? extractEmploymentType(Map<String, dynamic> data) {
    return normalizeEmploymentType(
      stringFromValue(
        firstValue(data, [
          'employmentType',
          'jobType',
          'positionType',
          'contractType',
          'timeCommitment',
          'schedule',
          'commitment',
        ]),
      ),
    );
  }

  static String? extractWorkMode(Map<String, dynamic> data) {
    final explicitRemote = parseNullableBool(
      firstValue(data, [
        'remote',
        'isRemote',
        'remoteFriendly',
        'isRemoteFriendly',
      ]),
    );
    if (explicitRemote == true) {
      return 'remote';
    }

    return normalizeWorkMode(
      stringFromValue(
        firstValue(data, [
          'workMode',
          'workplaceType',
          'locationType',
          'remoteType',
        ]),
      ),
    );
  }

  static bool? extractIsPaid(Map<String, dynamic> data) {
    return parseNullableBool(
      firstValue(data, [
        'isPaid',
        'paid',
        'paidOpportunity',
        'isPaidOpportunity',
      ]),
    );
  }

  static String? extractDuration(Map<String, dynamic> data) {
    return normalizeDuration(
      stringFromValue(
        firstValue(data, ['duration', 'internshipDuration', 'programDuration']),
      ),
    );
  }

  static DateTime? extractApplicationDeadline(Map<String, dynamic> data) {
    return normalizeDeadline(
      firstValue(data, [
            'applicationDeadline',
            'deadlineAt',
            'closingDate',
            'closingAt',
            'expiresAt',
            'expiryDate',
            'endDate',
          ]) ??
          data['deadline'],
    );
  }

  static String? formatEmploymentType(String? rawValue) {
    return switch (normalizeEmploymentType(rawValue)) {
      'full_time' => 'Full-time',
      'part_time' => 'Part-time',
      'internship' => 'Internship',
      'contract' => 'Contract',
      'temporary' => 'Temporary',
      'freelance' => 'Freelance',
      _ => null,
    };
  }

  static String? formatWorkMode(String? rawValue) {
    return switch (normalizeWorkMode(rawValue)) {
      'onsite' => 'On-site',
      'remote' => 'Remote',
      'hybrid' => 'Hybrid',
      _ => null,
    };
  }

  static String? formatPaidLabel(bool? isPaid) {
    if (isPaid == null) {
      return null;
    }

    return isPaid ? 'Paid' : 'Unpaid';
  }

  static String? formatSalaryRange({
    num? salaryMin,
    num? salaryMax,
    String? salaryCurrency,
    String? salaryPeriod,
  }) {
    num? normalizedMin = salaryMin;
    num? normalizedMax = salaryMax;

    if (normalizedMin == null && normalizedMax == null) {
      return null;
    }

    if (normalizedMin != null &&
        normalizedMax != null &&
        normalizedMax < normalizedMin) {
      final swappedMin = normalizedMax;
      normalizedMax = normalizedMin;
      normalizedMin = swappedMin;
    }

    final amountText = normalizedMin != null && normalizedMax != null
        ? '${_formatCompactAmount(normalizedMin)}-${_formatCompactAmount(normalizedMax)}'
        : _formatCompactAmount(normalizedMin ?? normalizedMax!);
    final currencyText = normalizeCurrency(salaryCurrency);
    final periodText = normalizeSalaryPeriod(salaryPeriod);

    final buffer = StringBuffer(amountText);
    if (currencyText != null) {
      buffer.write(' $currencyText');
    }
    if (periodText != null) {
      buffer.write(' / $periodText');
    }

    return buffer.toString().trim();
  }

  static String? formatFundingAmount({
    num? fundingAmount,
    String? fundingCurrency,
  }) {
    if (fundingAmount == null) {
      return null;
    }

    final buffer = StringBuffer(_formatCompactAmount(fundingAmount));
    final currencyText = normalizeCurrency(fundingCurrency);
    if (currencyText != null) {
      buffer.write(' $currencyText');
    }

    return buffer.toString().trim();
  }

  static String? formatFundingRange({
    num? fundingMin,
    num? fundingMax,
    String? fundingCurrency,
  }) {
    num? normalizedMin = fundingMin;
    num? normalizedMax = fundingMax;

    if (normalizedMin == null && normalizedMax == null) {
      return null;
    }

    if (normalizedMin != null &&
        normalizedMax != null &&
        normalizedMax < normalizedMin) {
      final swappedMin = normalizedMax;
      normalizedMax = normalizedMin;
      normalizedMin = swappedMin;
    }

    final amountText = normalizedMin != null && normalizedMax != null
        ? '${_formatCompactAmount(normalizedMin)}-${_formatCompactAmount(normalizedMax)}'
        : _formatCompactAmount(normalizedMin ?? normalizedMax!);
    final buffer = StringBuffer(amountText);
    final currencyText = normalizeCurrency(fundingCurrency);
    if (currencyText != null) {
      buffer.write(' $currencyText');
    }

    return buffer.toString().trim();
  }

  static String? buildFundingLabel({
    num? fundingAmount,
    String? fundingCurrency,
    String? fundingNote,
    num? legacySalaryMin,
    num? legacySalaryMax,
    String? legacySalaryCurrency,
    String? legacyCompensationText,
    bool preferFundingNote = false,
    bool includePrefix = false,
  }) {
    final customText = sanitizeText(fundingNote);
    final structured = formatFundingAmount(
      fundingAmount: fundingAmount,
      fundingCurrency: fundingCurrency,
    );

    String? label;
    if (preferFundingNote && customText != null) {
      label = customText;
    } else {
      label =
          structured ??
          customText ??
          formatFundingRange(
            fundingMin: legacySalaryMin,
            fundingMax: legacySalaryMax,
            fundingCurrency: legacySalaryCurrency,
          ) ??
          sanitizeText(legacyCompensationText);
    }

    if (label == null) {
      return null;
    }

    return includePrefix ? 'Company funding: $label' : label;
  }

  static String? buildCompensationLabel({
    num? salaryMin,
    num? salaryMax,
    String? salaryCurrency,
    String? salaryPeriod,
    String? compensationText,
    bool? isPaid,
    bool preferCompensationText = false,
  }) {
    final customText = sanitizeText(compensationText);
    final structured = formatSalaryRange(
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      salaryCurrency: salaryCurrency,
      salaryPeriod: salaryPeriod,
    );

    if (preferCompensationText && customText != null) {
      return customText;
    }
    if (structured != null) {
      return structured;
    }
    if (customText != null) {
      return customText;
    }

    return formatPaidLabel(isPaid);
  }

  static List<String> buildMetadataItems({
    required String type,
    num? salaryMin,
    num? salaryMax,
    String? salaryCurrency,
    String? salaryPeriod,
    String? compensationText,
    num? fundingAmount,
    String? fundingCurrency,
    String? fundingNote,
    bool? isPaid,
    String? employmentType,
    String? workMode,
    String? duration,
    int maxItems = 3,
    bool preferCompensationText = false,
  }) {
    final items = <String>[];
    final normalizedType = OpportunityType.parse(type);
    final compensationLabel = normalizedType == OpportunityType.sponsoring
        ? buildFundingLabel(
            fundingAmount: fundingAmount,
            fundingCurrency: fundingCurrency,
            fundingNote: fundingNote,
            legacySalaryMin: salaryMin,
            legacySalaryMax: salaryMax,
            legacySalaryCurrency: salaryCurrency,
            legacyCompensationText: compensationText,
            preferFundingNote: preferCompensationText,
          )
        : buildCompensationLabel(
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            salaryCurrency: salaryCurrency,
            salaryPeriod: salaryPeriod,
            compensationText: compensationText,
            isPaid: isPaid,
            preferCompensationText: preferCompensationText,
          );

    if (compensationLabel != null) {
      items.add(compensationLabel);
    }

    final employmentLabel = formatEmploymentType(employmentType);
    if (employmentLabel != null) {
      items.add(employmentLabel);
    }

    final workModeLabel = formatWorkMode(workMode);
    if (workModeLabel != null) {
      items.add(workModeLabel);
    }

    final paidLabel = formatPaidLabel(isPaid);
    final normalizedCompensation = compensationLabel?.toLowerCase();
    final compensationAlreadyConveysPaidState =
        normalizedCompensation == 'paid' || normalizedCompensation == 'unpaid';
    if (paidLabel != null &&
        !compensationAlreadyConveysPaidState &&
        compensationLabel == null) {
      items.add(paidLabel);
    }

    if (normalizedType == OpportunityType.internship) {
      final normalizedDuration = normalizeDuration(duration);
      if (normalizedDuration != null) {
        items.add(normalizedDuration);
      }
    }

    return uniqueNonEmpty(items).take(maxItems).toList();
  }

  static List<String> uniqueNonEmpty(Iterable<String?> items) {
    final seen = <String>{};
    final result = <String>[];

    for (final item in items) {
      final trimmed = item?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        continue;
      }

      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        result.add(trimmed);
      }
    }

    return result;
  }

  static String _formatCompactAmount(num value) {
    final absoluteValue = value.abs();
    if (absoluteValue >= 1000000) {
      final compactMillions = value / 1000000;
      final decimals = compactMillions % 1 == 0 ? 0 : 1;
      return '${_trimTrailingZeros(compactMillions.toStringAsFixed(decimals))}m';
    }

    if (absoluteValue >= 1000) {
      final compactThousands = value / 1000;
      final decimals = compactThousands % 1 == 0 ? 0 : 1;
      return '${_trimTrailingZeros(compactThousands.toStringAsFixed(decimals))}k';
    }

    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return _trimTrailingZeros(value.toStringAsFixed(1));
  }

  static String _trimTrailingZeros(String value) {
    if (!value.contains('.')) {
      return value;
    }

    return value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String? _normalizeListItem(String? value) {
    final trimmed = value
        ?.replaceAll('\u2022', '')
        .replaceFirst(RegExp(r'^\s*[-*]+\s*'), '')
        .replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
