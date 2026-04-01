import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/profile_avatar.dart';
import '../notifications_screen.dart';
import 'opportunity_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

enum _JobsViewMode { grid, list }

class _JobsScreenState extends State<JobsScreen> {
  static const List<_JobCategoryData> _categories = [
    _JobCategoryData(
      key: 'tech',
      label: 'Tech',
      icon: Icons.code_rounded,
      accentColor: OpportunityDashboardPalette.primary,
      surfaceTint: Color(0xFFEDE9FE),
      keywords: [
        'tech',
        'software',
        'developer',
        'development',
        'engineer',
        'engineering',
        'frontend',
        'front-end',
        'backend',
        'back-end',
        'fullstack',
        'full-stack',
        'mobile',
        'android',
        'ios',
        'cloud',
        'devops',
        'security',
        'cyber',
        'ai',
        'machine learning',
        'ml',
        'data analyst',
        'data scientist',
        'technical support',
        'it support',
      ],
    ),
    _JobCategoryData(
      key: 'design',
      label: 'Design',
      icon: Icons.brush_rounded,
      accentColor: OpportunityDashboardPalette.primaryDark,
      surfaceTint: Color(0xFFDBEAFE),
      keywords: [
        'design',
        'designer',
        'ux',
        'ui',
        'product design',
        'graphic',
        'illustrator',
        'visual',
        'creative',
        'motion',
        'brand design',
      ],
    ),
    _JobCategoryData(
      key: 'business',
      label: 'Business',
      icon: Icons.business_center_rounded,
      accentColor: OpportunityDashboardPalette.secondary,
      surfaceTint: Color(0xFFCCFBF1),
      keywords: [
        'business',
        'operations',
        'finance',
        'project manager',
        'account manager',
        'sales',
        'strategy',
        'consultant',
        'coordinator',
        'analyst',
        'administration',
        'office',
      ],
    ),
    _JobCategoryData(
      key: 'marketing',
      label: 'Marketing',
      icon: Icons.campaign_rounded,
      accentColor: OpportunityDashboardPalette.accent,
      surfaceTint: Color(0xFFFFEDD5),
      keywords: [
        'marketing',
        'growth',
        'content',
        'social media',
        'seo',
        'campaign',
        'communications',
        'brand',
        'community',
        'copywriter',
      ],
    ),
    _JobCategoryData(
      key: 'legal',
      label: 'Legal',
      icon: Icons.gavel_rounded,
      accentColor: OpportunityDashboardPalette.warning,
      surfaceTint: Color(0xFFFEF3C7),
      keywords: [
        'legal',
        'law',
        'compliance',
        'contract',
        'policy',
        'regulatory',
        'paralegal',
        'counsel',
        'attorney',
      ],
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  String? _selectedCategoryKey;
  _JobsViewMode _viewMode = _JobsViewMode.grid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextValue = _searchController.text.trim();
    if (nextValue == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = nextValue;
    });
  }

  Future<void> _loadData({bool force = false}) async {
    final opportunityProvider = context.read<OpportunityProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final userId = context.read<AuthProvider>().userModel?.uid;

    final futures = <Future<void>>[opportunityProvider.fetchOpportunities()];

    if (userId != null &&
        userId.isNotEmpty &&
        (force || savedProvider.savedOpportunities.isEmpty)) {
      futures.add(savedProvider.fetchSavedOpportunities(userId));
    }

    await Future.wait(futures);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openOpportunity(OpportunityModel opportunity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpportunityDetailScreen(opportunity: opportunity),
      ),
    );
  }

  List<_JobCardData> _buildJobCards(OpportunityProvider provider) {
    final featuredIds = provider.featuredOpportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) == OpportunityType.job,
        )
        .map((opportunity) => opportunity.id)
        .toSet();

    final liveJobs = provider.opportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) == OpportunityType.job,
        )
        .map(
          (opportunity) => _mapOpportunityToJobCard(
            opportunity,
            isFeaturedPreferred:
                featuredIds.contains(opportunity.id) || opportunity.isFeatured,
          ),
        )
        .toList();

    if (liveJobs.isNotEmpty) {
      return liveJobs;
    }

    return _fallbackJobCards;
  }

  List<_JobCardData> _applyFilters(List<_JobCardData> jobs) {
    final query = _searchQuery.toLowerCase();

    return jobs.where((job) {
      final matchesCategory =
          _selectedCategoryKey == null ||
          job.category.key == _selectedCategoryKey;
      final matchesQuery = query.isEmpty || job.searchText.contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<_JobCardData> _selectFeaturedJobs(List<_JobCardData> jobs) {
    final result = <_JobCardData>[];
    final seen = <String>{};

    void addCandidates(Iterable<_JobCardData> candidates) {
      for (final candidate in candidates) {
        if (result.length >= 5) {
          return;
        }

        if (seen.add(candidate.uniqueKey)) {
          result.add(candidate);
        }
      }
    }

    addCandidates(jobs.where((job) => job.isFeaturedPreferred));
    addCandidates(jobs);

    return result;
  }

  List<_JobCardData> _selectAvailableRoles(List<_JobCardData> jobs) {
    final availableRoles = <_JobCardData>[];
    final seen = <String>{};

    for (final job in jobs) {
      if (seen.add(job.uniqueKey)) {
        availableRoles.add(job);
      }
    }

    return availableRoles;
  }

  _JobCardData _mapOpportunityToJobCard(
    OpportunityModel opportunity, {
    required bool isFeaturedPreferred,
  }) {
    final category = _categoryFor(opportunity);
    final title = opportunity.title.trim().isEmpty
        ? 'Open Role'
        : opportunity.title.trim();
    final company = _companyName(opportunity);
    final subtitle = _subtitleLabel(opportunity, company: company);
    final location = _locationLabel(opportunity);
    final salary = _availableRoleCompensationText(opportunity);
    final metadata = _metadataItems(opportunity, maxItems: 3);
    final metadataLine = metadata
        .where((item) => item != salary)
        .take(2)
        .join(' | ');
    final badge = _jobBadgeLabel(opportunity);
    final typeBadge = _employmentBadgeLabel(opportunity);
    final levelTag = _experienceChipLabel(opportunity);
    final searchable = <String>[
      title,
      company,
      subtitle,
      location ?? '',
      salary ?? '',
      metadata.join(' '),
      badge,
      typeBadge ?? '',
      levelTag ?? '',
      category.label,
      category.key,
      opportunity.description,
      opportunity.requirements,
      opportunity.readString([
            'category',
            'department',
            'team',
            'industry',
            'field',
            'tags',
            'skills',
          ]) ??
          '',
    ].join(' ').toLowerCase();

    return _JobCardData(
      id: opportunity.id,
      title: title,
      company: company,
      subtitle: subtitle,
      location: location,
      salary: salary,
      metadataLine: metadataLine,
      badge: badge,
      typeBadge: typeBadge,
      levelTag: levelTag,
      logoUrl: opportunity.companyLogo.trim(),
      category: category,
      isFeaturedPreferred: isFeaturedPreferred,
      isPlaceholder: false,
      opportunity: opportunity,
      searchText: searchable,
    );
  }

  _JobCategoryData _categoryFor(OpportunityModel opportunity) {
    final searchable = <String>[
      opportunity.title,
      opportunity.description,
      opportunity.requirements,
      opportunity.readString([
            'category',
            'department',
            'team',
            'industry',
            'field',
            'tags',
            'skills',
          ]) ??
          '',
    ].join(' ').toLowerCase();

    for (final category in _categories.skip(1)) {
      final hasMatch = category.keywords.any(searchable.contains);
      if (hasMatch) {
        return category;
      }
    }

    return _categories.first;
  }

  String _companyName(OpportunityModel opportunity) {
    final companyName = opportunity.companyName.trim();
    return companyName.isEmpty ? 'AvenirDZ partner' : companyName;
  }

  String? _locationLabel(OpportunityModel opportunity) {
    final location = opportunity.location.trim();
    if (location.isNotEmpty) {
      return location;
    }

    final fallback = opportunity.readString([
      'city',
      'region',
      'country',
      'officeLocation',
      'address',
      'place',
    ]);
    if (fallback != null) {
      return fallback;
    }

    return switch (_workModeLabel(opportunity)) {
      'Remote' => 'Remote',
      'Hybrid' => 'Hybrid',
      'On-site' => 'On-site',
      _ => null,
    };
  }

  String _jobBadgeLabel(OpportunityModel opportunity) {
    final employmentBadge = _employmentBadgeLabel(opportunity);
    if (employmentBadge != null) {
      return employmentBadge;
    }

    final workMode = _workModeLabel(opportunity);
    if (workMode != null) {
      return workMode.toUpperCase();
    }

    return 'FULL TIME';
  }

  String? _employmentBadgeLabel(OpportunityModel opportunity) {
    return switch (OpportunityMetadata.normalizeEmploymentType(
      opportunity.employmentType,
    )) {
      'full_time' => 'FULL-TIME',
      'part_time' => 'PART-TIME',
      'internship' => 'INTERN',
      'contract' => 'CONTRACT',
      'temporary' => 'TEMP',
      'freelance' => 'FREELANCE',
      _ => null,
    };
  }

  String? _availableRoleCompensationText(OpportunityModel opportunity) {
    final label = _compensationText(opportunity);
    if (label == null) {
      return null;
    }

    final normalized = label.trim().toLowerCase();
    if (normalized == 'unpaid') {
      return null;
    }

    return _compactCompensationLabel(label);
  }

  String _compactCompensationLabel(String label) {
    return label
        .replaceAll(' / hour', ' / hr')
        .replaceAll(' / day', ' / day')
        .replaceAll(' / week', ' / wk')
        .replaceAll(' / month', ' / mo')
        .replaceAll(' / year', ' / yr')
        .replaceAll(' per hour', ' / hr')
        .replaceAll(' per day', ' / day')
        .replaceAll(' per week', ' / wk')
        .replaceAll(' per month', ' / mo')
        .replaceAll(' per year', ' / yr')
        .replaceAll(RegExp(r'\bUSD\b'), '\$');
  }

  String _subtitleLabel(
    OpportunityModel opportunity, {
    required String company,
  }) {
    final descriptor = _compactDescriptor(
      opportunity.readString([
        'department',
        'team',
        'category',
        'field',
        'industry',
        'track',
      ]),
    );
    if (descriptor == null ||
        descriptor.toLowerCase() == company.toLowerCase()) {
      return company;
    }

    return '$company • $descriptor';
  }

  String? _compactDescriptor(String? rawValue) {
    final sanitized = rawValue?.trim();
    if (sanitized == null || sanitized.isEmpty) {
      return null;
    }

    final segment = sanitized.split(RegExp(r'[/|,&]')).first.trim();
    if (segment.isEmpty) {
      return null;
    }

    final words = segment
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    return words.take(3).join(' ');
  }

  String? _experienceChipLabel(OpportunityModel opportunity) {
    final explicitLevel = _formatLevelChip(
      opportunity.readString([
        'experienceLevel',
        'experience_level',
        'experience',
        'seniority',
        'careerStage',
        'level',
        'tag',
      ]),
    );
    if (explicitLevel != null) {
      return explicitLevel;
    }

    final normalizedTitle = opportunity.title.toLowerCase();
    if (normalizedTitle.contains('entry')) {
      return 'ENTRY';
    }
    if (normalizedTitle.contains('junior')) {
      return 'JUNIOR';
    }
    if (normalizedTitle.contains('intern')) {
      return 'STUDENT';
    }

    final normalizedEmploymentType =
        OpportunityMetadata.normalizeEmploymentType(opportunity.employmentType);
    if (normalizedEmploymentType == 'internship' ||
        OpportunityType.parse(opportunity.type) == OpportunityType.internship) {
      return 'STUDENT';
    }

    return null;
  }

  String? _formatLevelChip(String? rawValue) {
    final trimmed = rawValue?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (normalized.contains('entry')) {
      return 'ENTRY';
    }
    if (normalized.contains('junior')) {
      return 'JUNIOR';
    }
    if (normalized.contains('student') || normalized.contains('intern')) {
      return 'STUDENT';
    }
    if (normalized.contains('graduate')) {
      return 'GRAD';
    }
    if (normalized.contains('senior')) {
      return 'SENIOR';
    }
    if (normalized.contains('mid')) {
      return 'MID';
    }

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final candidate = words.take(2).join(' ').toUpperCase();
    if (candidate.isEmpty) {
      return null;
    }

    return candidate.length <= 12 ? candidate : words.first.toUpperCase();
  }

  String? _compensationText(OpportunityModel opportunity) {
    final structuredLabel = OpportunityMetadata.buildCompensationLabel(
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
      compensationText: opportunity.compensationText,
      isPaid: opportunity.isPaid,
    );
    if (structuredLabel != null) {
      return structuredLabel;
    }

    final legacyCompensation = _sanitizeCompensationText(
      OpportunityMetadata.extractCompensationText(opportunity.rawData),
    );
    if (legacyCompensation != null) {
      return legacyCompensation;
    }

    final extracted = _sanitizeCompensationText(
      _extractCompensationFromText(opportunity),
    );
    if (extracted != null) {
      return extracted;
    }

    return OpportunityMetadata.formatPaidLabel(_effectiveIsPaid(opportunity));
  }

  String? _extractCompensationFromText(OpportunityModel opportunity) {
    final text = '${opportunity.description} ${opportunity.requirements}'
        .replaceAll('\n', ' ');
    final patterns = [
      RegExp(
        r'((?:salary|stipend|compensation|payment|pay)\s*[:\-]?\s*[^,;\n]{3,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'((?:USD|EUR|DZD|\$)\s?[0-9][0-9,.\s/-]{1,24})',
        caseSensitive: false,
      ),
      RegExp(
        r'((?:paid|unpaid)\s+(?:internship|role|position|opportunity))',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final result = match?.group(1)?.trim();
      if (result != null && result.isNotEmpty) {
        return result;
      }
    }

    return null;
  }

  String? _sanitizeCompensationText(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    var value = rawValue.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) {
      return null;
    }

    value = value.replaceFirst(
      RegExp(
        r'^(salary|stipend|compensation|payment|pay)\s*[:\-]?\s*',
        caseSensitive: false,
      ),
      '',
    );

    final normalized = value.toLowerCase();
    if (normalized.isEmpty ||
        normalized.contains('http') ||
        normalized.contains('www.') ||
        normalized.contains('.png') ||
        normalized.contains('.jpg') ||
        normalized.contains('.jpeg') ||
        normalized.contains('.webp') ||
        normalized.contains('unpaid')) {
      return null;
    }

    if (normalized == 'paid' ||
        normalized == 'paid internship' ||
        normalized == 'paid role' ||
        normalized == 'paid opportunity') {
      return 'Paid';
    }

    final hasCompensationSignal = RegExp(
      r'(\$|usd|eur|dzd|k\b|/month|per month|per hour|monthly|hourly|\d)',
      caseSensitive: false,
    ).hasMatch(value);

    if (!hasCompensationSignal || value.length > 36) {
      return null;
    }

    return value;
  }

  String? _workModeLabel(OpportunityModel opportunity) {
    final normalizedMode = _normalizedWorkMode(opportunity);
    if (normalizedMode != null) {
      return OpportunityMetadata.formatWorkMode(normalizedMode);
    }

    final searchable = [
      opportunity.location,
      opportunity.description,
      opportunity.requirements,
    ].whereType<String>().join(' ').toLowerCase();

    if (searchable.contains('hybrid')) {
      return 'Hybrid';
    }
    if (searchable.contains('remote')) {
      return 'Remote';
    }
    if (searchable.contains('on-site') ||
        searchable.contains('onsite') ||
        searchable.contains('on site')) {
      return 'On-site';
    }

    return null;
  }

  String? _normalizedWorkMode(OpportunityModel opportunity) {
    return opportunity.workMode ??
        OpportunityMetadata.extractWorkMode(opportunity.rawData);
  }

  bool? _effectiveIsPaid(OpportunityModel opportunity) {
    return opportunity.isPaid ??
        OpportunityMetadata.extractIsPaid(opportunity.rawData);
  }

  List<String> _metadataItems(
    OpportunityModel opportunity, {
    int maxItems = 3,
  }) {
    final items = OpportunityMetadata.buildMetadataItems(
      type: opportunity.type,
      salaryMin: opportunity.salaryMin,
      salaryMax: opportunity.salaryMax,
      salaryCurrency: opportunity.salaryCurrency,
      salaryPeriod: opportunity.salaryPeriod,
      compensationText: opportunity.compensationText,
      isPaid: _effectiveIsPaid(opportunity),
      employmentType: opportunity.employmentType,
      workMode: _normalizedWorkMode(opportunity),
      duration: opportunity.duration,
      maxItems: maxItems,
    );
    if (items.isNotEmpty) {
      return items;
    }

    final legacyItems = <String>[];
    final compensation = _sanitizeCompensationText(
      _extractCompensationFromText(opportunity),
    );
    if (compensation != null) {
      legacyItems.add(compensation);
    }
    final workMode = _workModeLabel(opportunity);
    if (workMode != null) {
      legacyItems.add(workMode);
    }

    return OpportunityMetadata.uniqueNonEmpty(
      legacyItems,
    ).take(maxItems).toList();
  }

  List<_JobCardData> get _fallbackJobCards => [
    _JobCardData.placeholder(
      title: 'Senior Product Designer',
      company: 'Nova Labs',
      subtitle: 'Nova Labs • Product Design',
      location: 'Remote - Algiers',
      salary: 'DZD 120k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'SENIOR',
      category: _categories[1],
      isFeaturedPreferred: true,
    ),
    _JobCardData.placeholder(
      title: 'Cloud Support Engineer',
      company: 'Avenir Cloud',
      subtitle: 'Avenir Cloud • Support',
      location: 'Hybrid - Oran',
      salary: 'DZD 105k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'ENTRY',
      category: _categories[0],
      isFeaturedPreferred: true,
    ),
    _JobCardData.placeholder(
      title: 'Growth Marketing Lead',
      company: 'Bright Studio',
      subtitle: 'Bright Studio • Growth',
      location: 'Remote',
      salary: 'DZD 95k/mo',
      badge: 'REMOTE',
      levelTag: 'SENIOR',
      category: _categories[3],
      isFeaturedPreferred: true,
    ),
    _JobCardData.placeholder(
      title: 'Junior Frontend Developer',
      company: 'Pixel Foundry',
      subtitle: 'Pixel Foundry • Engineering',
      location: 'Algiers',
      salary: 'DZD 75k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'JUNIOR',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'UI Design Intern',
      company: 'Loom Studio',
      subtitle: 'Loom Studio • Design',
      location: 'Remote',
      salary: 'Paid',
      badge: 'INTERNSHIP',
      typeBadge: 'INTERN',
      levelTag: 'STUDENT',
      category: _categories[1],
    ),
    _JobCardData.placeholder(
      title: 'Data Analyst',
      company: 'North Metrics',
      subtitle: 'North Metrics • Analytics',
      location: 'Hybrid',
      salary: 'DZD 88k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'ENTRY',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'Social Media Manager',
      company: 'Wave House',
      subtitle: 'Wave House • Social',
      location: 'Remote',
      salary: 'DZD 82k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'JUNIOR',
      category: _categories[3],
    ),
    _JobCardData.placeholder(
      title: 'Security Analyst',
      company: 'Shield Ops',
      subtitle: 'Shield Ops • Security',
      location: 'Algiers',
      salary: 'DZD 110k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'ENTRY',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'Marketing Analyst',
      company: 'Signal Growth',
      subtitle: 'Signal Growth • Marketing',
      location: 'Hybrid',
      salary: 'DZD 84k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'JUNIOR',
      category: _categories[3],
    ),
    _JobCardData.placeholder(
      title: 'Backend Support',
      company: 'Stack Harbor',
      subtitle: 'Stack Harbor • Platform',
      location: 'Remote',
      salary: 'DZD 90k/mo',
      badge: 'FULL TIME',
      typeBadge: 'FULL-TIME',
      levelTag: 'ENTRY',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'Illustrator Intern',
      company: 'Sketchroom',
      subtitle: 'Sketchroom • Illustration',
      location: 'Oran',
      salary: 'Paid',
      badge: 'INTERNSHIP',
      typeBadge: 'INTERN',
      levelTag: 'STUDENT',
      category: _categories[1],
    ),
    _JobCardData.placeholder(
      title: 'AI Trainer',
      company: 'Orbit AI',
      subtitle: 'Orbit AI • AI Ops',
      location: 'Remote',
      salary: 'DZD 115k/mo',
      badge: 'CONTRACT',
      typeBadge: 'CONTRACT',
      levelTag: 'JUNIOR',
      category: _categories[0],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final opportunityProvider = context.watch<OpportunityProvider>();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final viewPadding = mediaQuery.viewPadding;
    final isCompact = screenSize.width < 390 || screenSize.height < 780;
    final isExtraCompact = screenSize.width < 360 || screenSize.height < 700;
    final horizontalPadding = isExtraCompact
        ? 16.0
        : isCompact
        ? 18.0
        : 20.0;
    final headlineTopPadding = isExtraCompact
        ? 10.0
        : isCompact
        ? 12.0
        : 22.0;
    final headlineFontSize = isExtraCompact
        ? 25.0
        : isCompact
        ? 26.0
        : 34.0;
    final searchTopPadding = isExtraCompact
        ? 10.0
        : isCompact
        ? 12.0
        : 18.0;
    final categoriesTopPadding = isExtraCompact
        ? 12.0
        : isCompact
        ? 14.0
        : 24.0;
    final categoriesHeight = isExtraCompact
        ? 72.0
        : isCompact
        ? 78.0
        : 102.0;
    final categorySpacing = isExtraCompact ? 12.0 : 14.0;
    final sectionTopPadding = isExtraCompact
        ? 14.0
        : isCompact
        ? 16.0
        : 28.0;
    final featuredHeight = isExtraCompact
        ? 204.0
        : isCompact
        ? 212.0
        : 248.0;
    final featuredCardWidthFactor = isExtraCompact ? 0.76 : 0.78;
    final featuredSpacing = isExtraCompact ? 12.0 : 16.0;
    final gridSpacing = isExtraCompact ? 12.0 : 14.0;
    final gridMainExtent = isExtraCompact
        ? 168.0
        : isCompact
        ? 172.0
        : 182.0;
    final bottomSpacing =
        viewPadding.bottom +
        (isExtraCompact
            ? 18.0
            : isCompact
            ? 22.0
            : 28.0);

    final allJobs = _buildJobCards(opportunityProvider);
    final filteredJobs = _applyFilters(allJobs);
    final featuredJobs = _selectFeaturedJobs(filteredJobs);
    final availableRoles = _selectAvailableRoles(filteredJobs);
    final showLoadingBar =
        opportunityProvider.isLoading &&
        opportunityProvider.opportunities.isNotEmpty;

    return Scaffold(
      backgroundColor: OpportunityDashboardPalette.background,
      body: RefreshIndicator(
        color: OpportunityDashboardPalette.primary,
        backgroundColor: OpportunityDashboardPalette.surface,
        onRefresh: () => _loadData(force: true),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: _JobsHeaderBar(
                user: authProvider.userModel,
                unreadCount: notificationProvider.unreadCount,
                onNotificationsPressed: _openNotifications,
                compact: isCompact,
              ),
            ),
            if (showLoadingBar)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                headlineTopPadding,
                horizontalPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Find your next\n',
                        style: GoogleFonts.poppins(
                          fontSize: headlineFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'breakthrough',
                        style: GoogleFonts.poppins(
                          fontSize: headlineFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                          color: OpportunityDashboardPalette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                searchTopPadding,
                horizontalPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _JobsSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onClear: _searchQuery.isEmpty
                      ? null
                      : _searchController.clear,
                  compact: isCompact,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                categoriesTopPadding,
                horizontalPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Categories',
                  actionLabel: 'See All',
                  compact: isCompact,
                  onAction: () {
                    if (_selectedCategoryKey == null) {
                      return;
                    }

                    setState(() {
                      _selectedCategoryKey = null;
                    });
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: categoriesHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isExtraCompact
                        ? 4
                        : isCompact
                        ? 6
                        : 14,
                    horizontalPadding,
                    0,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(width: categorySpacing),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _JobCategoryChip(
                      category: category,
                      isSelected: category.key == _selectedCategoryKey,
                      compact: isCompact,
                      onTap: () {
                        setState(() {
                          _selectedCategoryKey =
                              _selectedCategoryKey == category.key
                              ? null
                              : category.key;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                sectionTopPadding,
                horizontalPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Featured Jobs',
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 16 : 19,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
              ),
            ),
            if (filteredJobs.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isExtraCompact
                      ? 8
                      : isCompact
                      ? 10
                      : 14,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _JobsEmptyStateCard(
                    title: 'No featured jobs found',
                    message:
                        'Try another keyword or clear your category filter to see more roles.',
                    compact: isCompact,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: featuredHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      isExtraCompact
                          ? 8
                          : isCompact
                          ? 10
                          : 14,
                      horizontalPadding,
                      0,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: featuredJobs.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: featuredSpacing),
                    itemBuilder: (context, index) {
                      final job = featuredJobs[index];
                      return SizedBox(
                        width: screenSize.width * featuredCardWidthFactor,
                        child: _FeaturedJobCard(
                          job: job,
                          style: _featuredStyleFor(index),
                          compact: isCompact,
                          onTap: job.opportunity == null
                              ? null
                              : () => _openOpportunity(job.opportunity!),
                          onApply: job.opportunity == null
                              ? null
                              : () => _openOpportunity(job.opportunity!),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                sectionTopPadding,
                horizontalPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Available Roles',
                  countLabel: availableRoles.length == 1
                      ? '1 job'
                      : '${availableRoles.length} jobs',
                  compact: isCompact,
                  trailing: _RolesViewToggle(
                    viewMode: _viewMode,
                    compact: isCompact,
                    onChanged: (viewMode) {
                      setState(() {
                        _viewMode = viewMode;
                      });
                    },
                  ),
                ),
              ),
            ),
            if (filteredJobs.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isExtraCompact ? 12 : 14,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _JobsEmptyStateCard(
                    title: 'No roles match your search',
                    message:
                        'Search by title or company, or tap See All to reset categories.',
                    compact: isCompact,
                  ),
                ),
              )
            else if (_viewMode == _JobsViewMode.grid)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isExtraCompact ? 12 : 14,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final job = availableRoles[index];
                    return _AvailableRoleCard(
                      job: job,
                      compact: isCompact,
                      onTap: job.opportunity == null
                          ? null
                          : () => _openOpportunity(job.opportunity!),
                    );
                  }, childCount: availableRoles.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    mainAxisExtent: gridMainExtent,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isExtraCompact ? 12 : 14,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final job = availableRoles[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == availableRoles.length - 1 ? 0 : 12,
                      ),
                      child: _PurpleAvailableRoleListCard(
                        job: job,
                        compact: isCompact,
                        onTap: job.opportunity == null
                            ? null
                            : () => _openOpportunity(job.opportunity!),
                      ),
                    );
                  }, childCount: availableRoles.length),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
          ],
        ),
      ),
    );
  }
}

class _PurpleAvailableRoleListCard extends StatelessWidget {
  final _JobCardData job;
  final VoidCallback? onTap;
  final bool compact;

  const _PurpleAvailableRoleListCard({
    required this.job,
    this.onTap,
    required this.compact,
  });

  String _supportingLine() {
    final subtitle = job.subtitle.trim();
    if (subtitle.isEmpty) {
      return job.company;
    }

    return subtitle.toLowerCase() == job.company.toLowerCase()
        ? job.company
        : subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _availableRolePaletteFor(job.uniqueKey);
    final cardRadius = BorderRadius.circular(compact ? 17 : 19);
    final supportingLine = _supportingLine();
    final showExplicitFullTime =
        !job.isPlaceholder &&
        job.typeBadge?.trim().toUpperCase() == 'FULL-TIME';
    final topSurface = Color.alphaBlend(
      palette.surfaceTint.withValues(alpha: 0.24),
      const Color(0xFFFEFBFF),
    );
    final bottomSurface = Color.alphaBlend(
      palette.surfaceTint.withValues(alpha: 0.34),
      const Color(0xFFF6F2FF),
    );
    final iconSurface = Color.alphaBlend(
      palette.surfaceTint.withValues(alpha: 0.46),
      Colors.white,
    );
    final metadataItems = <Widget>[
      if (job.salary?.trim().isNotEmpty ?? false)
        _AvailableRoleListMetaItem(
          text: job.salary!.trim(),
          icon: Icons.payments_rounded,
          color: palette.chipTextColor,
          compact: compact,
          emphasize: true,
        ),
      if (job.location?.trim().isNotEmpty ?? false)
        _AvailableRoleListMetaItem(
          text: job.location!.trim(),
          icon: Icons.place_rounded,
          color: OpportunityDashboardPalette.textSecondary,
          compact: compact,
        ),
      if (job.levelTag?.trim().isNotEmpty ?? false)
        _AvailableRoleListMetaItem(
          text: job.levelTag!.trim(),
          color: palette.chipTextColor.withValues(alpha: 0.82),
          compact: compact,
        ),
      if (job.salary?.trim().isEmpty ?? true)
        if (job.badge.trim().isNotEmpty)
          _AvailableRoleListMetaItem(
            text: job.badge.trim(),
            color: palette.chipTextColor.withValues(alpha: 0.82),
            compact: compact,
          ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [topSurface, bottomSurface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: cardRadius,
            border: Border.all(
              color: palette.chipTextColor.withValues(alpha: 0.10),
            ),
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: compact ? -18 : -22,
                  bottom: compact ? -26 : -30,
                  child: Container(
                    width: compact ? 64 : 72,
                    height: compact ? 64 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 11 : 13,
                    compact ? 11 : 12,
                    compact ? 11 : 13,
                    compact ? 11 : 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: compact ? 40 : 44,
                        height: compact ? 40 : 44,
                        decoration: BoxDecoration(
                          color: iconSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.chipTextColor.withValues(
                              alpha: 0.10,
                            ),
                          ),
                        ),
                        child: Icon(
                          job.category.icon,
                          color: palette.chipTextColor,
                          size: compact ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: compact ? 10 : 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    job.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: compact ? 13.6 : 14.6,
                                      fontWeight: FontWeight.w700,
                                      height: 1.08,
                                      color: OpportunityDashboardPalette
                                          .textPrimary,
                                    ),
                                  ),
                                ),
                                if (showExplicitFullTime) ...[
                                  SizedBox(width: compact ? 8 : 10),
                                  Text(
                                    'FULL-TIME',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: compact ? 9.0 : 9.6,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.24,
                                      color: palette.chipTextColor.withValues(
                                        alpha: 0.80,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: compact ? 3 : 4),
                            Text(
                              supportingLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: compact ? 10.6 : 11.2,
                                fontWeight: FontWeight.w600,
                                color:
                                    OpportunityDashboardPalette.textSecondary,
                              ),
                            ),
                            SizedBox(height: compact ? 5 : 6),
                            Wrap(
                              spacing: compact ? 9 : 11,
                              runSpacing: compact ? 3 : 4,
                              children: metadataItems,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: compact ? 28 : 30,
                          height: compact ? 28 : 30,
                          decoration: BoxDecoration(
                            color: palette.chipTextColor.withValues(
                              alpha: 0.10,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: palette.chipTextColor.withValues(
                              alpha: 0.82,
                            ),
                            size: compact ? 15 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableRoleListMetaItem extends StatelessWidget {
  final String text;
  final Color color;
  final bool compact;
  final IconData? icon;
  final bool emphasize;

  const _AvailableRoleListMetaItem({
    required this.text,
    required this.color,
    required this.compact,
    this.icon,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 12.0 : 13.0, color: color),
          SizedBox(width: compact ? 4 : 5),
        ],
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: compact ? 9.8 : 10.4,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            color: color,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

_FeaturedJobVariantStyle _featuredStyleFor(int index) {
  const styles = <_FeaturedJobVariantStyle>[
    _FeaturedJobVariantStyle(
      decorationVariant: _FeaturedDecorationVariant.heroBloom,
      gradientColors: [
        Color(0xFF7466FF),
        OpportunityDashboardPalette.primary,
        OpportunityDashboardPalette.primaryDark,
      ],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      logoSurface: Color(0xFFF8F5FF),
      logoForeground: OpportunityDashboardPalette.primaryDark,
      badgeBackground: Color(0x26FFFFFF),
      badgeBorderColor: Color(0x3DFFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFEAE2FF)],
      buttonTextColor: OpportunityDashboardPalette.primaryDark,
      accentColor: Color(0xFFBFB0FF),
      glowColor: Color(0xFF9D92FF),
    ),
    _FeaturedJobVariantStyle(
      decorationVariant: _FeaturedDecorationVariant.glassRibbon,
      gradientColors: [Color(0xFF5F46FF), Color(0xFF3B22F6), Color(0xFF26146D)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomRight,
      logoSurface: Color(0xFFF7F2FF),
      logoForeground: Color(0xFF3520BE),
      badgeBackground: Color(0x22FFFFFF),
      badgeBorderColor: Color(0x36FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFE3D8FF)],
      buttonTextColor: Color(0xFF3924D7),
      accentColor: Color(0xFFCBBEFF),
      glowColor: Color(0xFF7B66FF),
    ),
    _FeaturedJobVariantStyle(
      decorationVariant: _FeaturedDecorationVariant.diagonalLight,
      gradientColors: [Color(0xFF8773FF), Color(0xFF4C30F2), Color(0xFF2235C1)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomCenter,
      logoSurface: Color(0xFFF9F6FF),
      logoForeground: Color(0xFF2832B6),
      badgeBackground: Color(0x24FFFFFF),
      badgeBorderColor: Color(0x3DFFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFE8E0FF)],
      buttonTextColor: Color(0xFF2B31B7),
      accentColor: Color(0xFFD3C8FF),
      glowColor: Color(0xFF8E80FF),
    ),
    _FeaturedJobVariantStyle(
      decorationVariant: _FeaturedDecorationVariant.geoPattern,
      gradientColors: [Color(0xFF4C32F4), Color(0xFF2F1AAA), Color(0xFF1B2B88)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      logoSurface: Color(0xFFF7F3FF),
      logoForeground: Color(0xFF25259B),
      badgeBackground: Color(0x21FFFFFF),
      badgeBorderColor: Color(0x34FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFE1D7FF)],
      buttonTextColor: Color(0xFF2C249F),
      accentColor: Color(0xFFAB9EFF),
      glowColor: Color(0xFF7368FF),
    ),
    _FeaturedJobVariantStyle(
      decorationVariant: _FeaturedDecorationVariant.buttonGlow,
      gradientColors: [
        Color(0xFF7F6FFF),
        OpportunityDashboardPalette.primary,
        Color(0xFF2841D1),
      ],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      logoSurface: Color(0xFFF9F5FF),
      logoForeground: OpportunityDashboardPalette.primaryDark,
      badgeBackground: Color(0x24FFFFFF),
      badgeBorderColor: Color(0x38FFFFFF),
      buttonGradientColors: [Colors.white, Color(0xFFECE5FF)],
      buttonTextColor: OpportunityDashboardPalette.primaryDark,
      accentColor: Color(0xFFC7BBFF),
      glowColor: Color(0xFFA091FF),
    ),
  ];

  return styles[index % styles.length];
}

class _JobsHeaderBar extends StatelessWidget {
  final UserModel? user;
  final int unreadCount;
  final VoidCallback onNotificationsPressed;
  final bool compact;

  const _JobsHeaderBar({
    required this.user,
    required this.unreadCount,
    required this.onNotificationsPressed,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        compact ? 10 : 16,
        compact ? 16 : 20,
        compact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        border: Border(
          bottom: BorderSide(
            color: OpportunityDashboardPalette.border.withValues(alpha: 0.75),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: OpportunityDashboardPalette.primary.withValues(
                    alpha: 0.16,
                  ),
                ),
              ),
              child: ProfileAvatar(
                user: user,
                radius: compact ? 15 : 18,
                fallbackName: 'J',
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: Text(
                'Jobs',
                style: GoogleFonts.poppins(
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.textPrimary,
                ),
              ),
            ),
            _NotificationBellButton(
              unreadCount: unreadCount,
              onTap: onNotificationsPressed,
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  final bool compact;

  const _NotificationBellButton({
    required this.unreadCount,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 40.0 : 46.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        child: Ink(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(color: OpportunityDashboardPalette.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: OpportunityDashboardPalette.textPrimary,
                size: compact ? 19 : 22,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: compact ? 8 : 10,
                  right: compact ? 8 : 10,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: compact ? 16 : 18,
                      minHeight: compact ? 16 : 18,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 4),
                    decoration: const BoxDecoration(
                      color: OpportunityDashboardPalette.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 8 : 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onClear;
  final bool compact;

  const _JobsSearchBar({
    required this.controller,
    required this.focusNode,
    this.onClear,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      style: GoogleFonts.poppins(
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w500,
        color: OpportunityDashboardPalette.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: compact,
        hintText: 'Search roles, companies...',
        hintStyle: GoogleFonts.poppins(
          fontSize: compact ? 12 : 14,
          color: OpportunityDashboardPalette.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: OpportunityDashboardPalette.textSecondary,
          size: compact ? 18 : 22,
        ),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                color: OpportunityDashboardPalette.textSecondary,
              ),
        filled: true,
        fillColor: const Color(0xFFEEF2FF),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 12 : 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 18 : 24),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 18 : 24),
          borderSide: BorderSide(
            color: OpportunityDashboardPalette.primary.withValues(alpha: 0.22),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? countLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final bool compact;

  const _SectionHeader({
    required this.title,
    this.countLabel,
    this.actionLabel,
    this.onAction,
    this.trailing,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 16 : 19,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
              ),
              if (countLabel != null) ...[
                SizedBox(width: compact ? 8 : 10),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 4 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(compact ? 12 : 14),
                    border: Border.all(
                      color: OpportunityDashboardPalette.border.withValues(
                        alpha: 0.95,
                      ),
                    ),
                  ),
                  child: Text(
                    countLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: OpportunityDashboardPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: OpportunityDashboardPalette.primary,
              padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
              minimumSize: Size(0, compact ? 28 : 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: GoogleFonts.poppins(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _JobCategoryChip extends StatelessWidget {
  final _JobCategoryData category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const _JobCategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: compact ? 60 : 78,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 8,
            vertical: compact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? OpportunityDashboardPalette.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: compact ? 40 : 58,
                height: compact ? 40 : 58,
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.accentColor.withValues(alpha: 0.14)
                      : category.surfaceTint,
                  borderRadius: BorderRadius.circular(compact ? 14 : 20),
                  border: Border.all(
                    color: isSelected
                        ? category.accentColor.withValues(alpha: 0.22)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: category.accentColor,
                  size: compact ? 18 : 26,
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: OpportunityDashboardPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FeaturedDecorationVariant {
  heroBloom,
  glassRibbon,
  diagonalLight,
  geoPattern,
  buttonGlow,
}

class _FeaturedJobVariantStyle {
  final _FeaturedDecorationVariant decorationVariant;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Color logoSurface;
  final Color logoForeground;
  final Color badgeBackground;
  final Color badgeBorderColor;
  final List<Color> buttonGradientColors;
  final Color buttonTextColor;
  final Color accentColor;
  final Color glowColor;

  const _FeaturedJobVariantStyle({
    required this.decorationVariant,
    required this.gradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.logoSurface,
    required this.logoForeground,
    required this.badgeBackground,
    required this.badgeBorderColor,
    required this.buttonGradientColors,
    required this.buttonTextColor,
    required this.accentColor,
    required this.glowColor,
  });
}

class _FeaturedJobCard extends StatelessWidget {
  final _JobCardData job;
  final _FeaturedJobVariantStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final bool compact;

  const _FeaturedJobCard({
    required this.job,
    required this.style,
    this.onTap,
    this.onApply,
    required this.compact,
  });

  String? _displayMetadataLine() {
    final metadata = job.metadataLine?.trim();
    if (metadata == null || metadata.isEmpty) return null;

    final salary = job.salary?.trim();
    if (salary == null || salary.isEmpty) return metadata;

    final normalizedSalary = salary.toLowerCase();
    final salaryTokens = normalizedSalary
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 2)
        .toList();

    final filteredParts = metadata
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) {
          final normalizedPart = part.toLowerCase();
          if (normalizedPart.contains(normalizedSalary)) {
            return false;
          }

          final matchingTokenCount = salaryTokens
              .where(normalizedPart.contains)
              .length;
          return matchingTokenCount < 2;
        })
        .toList();

    if (filteredParts.isEmpty) return null;
    return filteredParts.join(' | ');
  }

  List<Widget> _buildDecorations({
    required bool isTight,
    required double borderRadius,
  }) {
    switch (style.decorationVariant) {
      case _FeaturedDecorationVariant.heroBloom:
        return [
          Positioned(
            top: isTight ? -52 : -60,
            right: isTight ? -18 : -22,
            child: _GlowOrb(
              size: isTight ? 150 : 180,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: isTight ? -48 : -56,
            left: isTight ? -28 : -34,
            child: _GlowOrb(
              size: isTight ? 168 : 194,
              color: style.glowColor.withValues(alpha: 0.34),
            ),
          ),
        ];
      case _FeaturedDecorationVariant.glassRibbon:
        return [
          Positioned(
            top: isTight ? -46 : -54,
            left: isTight ? -24 : -28,
            child: _GlowOrb(
              size: isTight ? 158 : 186,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            top: isTight ? 18 : 22,
            right: isTight ? 20 : 24,
            child: Container(
              width: isTight ? 54 : 64,
              height: isTight ? 54 : 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: isTight ? -32 : -36,
            right: isTight ? -28 : -24,
            child: _GlowOrb(
              size: isTight ? 144 : 172,
              color: style.glowColor.withValues(alpha: 0.26),
            ),
          ),
        ];
      case _FeaturedDecorationVariant.diagonalLight:
        return [
          Positioned(
            top: isTight ? 26 : 30,
            right: isTight ? 12 : 16,
            child: Container(
              width: isTight ? 90 : 108,
              height: isTight ? 112 : 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: isTight ? -34 : -40,
            left: isTight ? -20 : -24,
            child: _GlowOrb(
              size: isTight ? 132 : 154,
              color: style.glowColor.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: isTight ? -22 : -28,
            left: isTight ? 36 : 44,
            child: _GlowOrb(
              size: isTight ? 106 : 122,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ];
      case _FeaturedDecorationVariant.geoPattern:
        return [
          Positioned(
            bottom: isTight ? 20 : 24,
            right: isTight ? 16 : 20,
            child: SizedBox(
              width: isTight ? 40 : 46,
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: List<Widget>.generate(
                  4,
                  (index) => Container(
                    width: isTight ? 8 : 9,
                    height: isTight ? 8 : 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white.withValues(
                        alpha: index.isEven ? 0.18 : 0.10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: isTight ? -36 : -42,
            left: isTight ? -18 : -24,
            child: _GlowOrb(
              size: isTight ? 124 : 146,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: isTight ? -42 : -46,
            right: isTight ? -18 : -22,
            child: _GlowOrb(
              size: isTight ? 148 : 170,
              color: style.glowColor.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: isTight ? 58 : 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ];
      case _FeaturedDecorationVariant.buttonGlow:
        return [
          Positioned(
            top: isTight ? 10 : 14,
            left: isTight ? 10 : 14,
            child: _GlowOrb(
              size: isTight ? 100 : 116,
              color: style.glowColor.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            bottom: isTight ? -28 : -30,
            right: isTight ? -8 : -6,
            child: _GlowOrb(
              size: isTight ? 154 : 182,
              color: style.glowColor.withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            bottom: isTight ? 18 : 22,
            right: isTight ? 24 : 28,
            child: Container(
              width: isTight ? 62 : 72,
              height: isTight ? 62 : 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationText = job.location == null || job.location!.isEmpty
        ? job.company
        : '${job.company} • ${job.location}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight =
            compact ||
            constraints.maxHeight < 228 ||
            constraints.maxWidth < 280;
        final displayMetadataLine = _displayMetadataLine();
        final footerSalary = job.salary?.trim();
        final denseLayout =
            isTight ||
            job.title.length > 15 ||
            locationText.length > 22 ||
            (displayMetadataLine?.length ?? 0) > 18;
        final cardPadding = denseLayout
            ? EdgeInsets.fromLTRB(
                isTight ? 14 : 18,
                isTight ? 14 : 16,
                isTight ? 14 : 18,
                isTight ? 12 : 14,
              )
            : const EdgeInsets.fromLTRB(20, 20, 20, 18);
        final logoSize = denseLayout
            ? (isTight ? 38.0 : 42.0)
            : (isTight ? 40.0 : 46.0);
        final titleFontSize = denseLayout
            ? (isTight ? 18.5 : 21.5)
            : (isTight ? 20.0 : 24.0);
        final locationFontSize = denseLayout
            ? (isTight ? 11.5 : 12.2)
            : (isTight ? 12.0 : 13.0);
        final metadataFontSize = denseLayout
            ? (isTight ? 10.0 : 10.8)
            : (isTight ? 10.5 : 11.5);
        final salaryFontSize = denseLayout
            ? (isTight ? 12.2 : 13.4)
            : (isTight ? 13.0 : 15.0);
        final hasFooterSalary = footerSalary != null && footerSalary.isNotEmpty;
        final useStackedFooter =
            constraints.maxWidth < 254 ||
            ((footerSalary?.length ?? 0) > (isTight ? 16 : 18) &&
                constraints.maxWidth < 304);
        final borderRadiusValue = isTight ? 24.0 : 30.0;
        final cardRadius = BorderRadius.circular(borderRadiusValue);
        final footerButtonCompact = compact || denseLayout;
        final salaryLabel = !hasFooterSalary
            ? null
            : Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: isTight ? 13 : 15,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  SizedBox(width: isTight ? 6 : 8),
                  Flexible(
                    child: Text(
                      footerSalary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: salaryFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.96),
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              );

        final footer = useStackedFooter
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...?salaryLabel == null
                      ? null
                      : <Widget>[salaryLabel, const SizedBox(height: 9)],
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ApplyNowButton(
                      onTap: onApply,
                      backgroundColors: style.buttonGradientColors,
                      textColor: style.buttonTextColor,
                      compact: footerButtonCompact,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: salaryLabel == null
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: salaryLabel,
                          ),
                  ),
                  SizedBox(width: isTight ? 10 : 12),
                  _ApplyNowButton(
                    onTap: onApply,
                    backgroundColors: style.buttonGradientColors,
                    textColor: style.buttonTextColor,
                    compact: footerButtonCompact,
                  ),
                ],
              );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardRadius,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: style.gradientColors,
                  begin: style.gradientBegin,
                  end: style.gradientEnd,
                ),
                borderRadius: cardRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: ClipRRect(
                borderRadius: cardRadius,
                child: Stack(
                  children: [
                    ..._buildDecorations(
                      isTight: isTight,
                      borderRadius: borderRadiusValue,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              style.accentColor.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTight ? 2.5 : 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    isTight ? 18 : 20,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.30),
                                      Colors.white.withValues(alpha: 0.10),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: _CompanyLogoTile(
                                  logoUrl: job.logoUrl,
                                  companyName: job.company,
                                  size: logoSize,
                                  backgroundColor: style.logoSurface,
                                  foregroundColor: style.logoForeground,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: denseLayout
                                      ? (isTight ? 8 : 10)
                                      : (isTight ? 10 : 12),
                                  vertical: denseLayout
                                      ? (isTight ? 5 : 6)
                                      : (isTight ? 6 : 8),
                                ),
                                decoration: BoxDecoration(
                                  color: style.badgeBackground,
                                  borderRadius: BorderRadius.circular(
                                    denseLayout
                                        ? (isTight ? 12 : 14)
                                        : (isTight ? 14 : 16),
                                  ),
                                  border: Border.all(
                                    color: style.badgeBorderColor,
                                  ),
                                ),
                                child: Text(
                                  job.badge,
                                  style: GoogleFonts.poppins(
                                    fontSize: denseLayout
                                        ? (isTight ? 8.4 : 9.2)
                                        : (isTight ? 9 : 10),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              height: denseLayout ? 1.04 : 1.1,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            height: denseLayout
                                ? (isTight ? 6 : 8)
                                : (isTight ? 8 : 10),
                          ),
                          Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: locationFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          if (displayMetadataLine != null &&
                              displayMetadataLine.trim().isNotEmpty) ...[
                            SizedBox(
                              height: denseLayout
                                  ? (isTight ? 3 : 4)
                                  : (isTight ? 4 : 6),
                            ),
                            Text(
                              displayMetadataLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: metadataFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.80),
                              ),
                            ),
                          ],
                          SizedBox(
                            height: denseLayout
                                ? (isTight ? 10 : 14)
                                : (isTight ? 12 : 18),
                          ),
                          footer,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ApplyNowButton extends StatelessWidget {
  final VoidCallback? onTap;
  final List<Color> backgroundColors;
  final Color textColor;
  final bool compact;

  const _ApplyNowButton({
    required this.onTap,
    required this.backgroundColors,
    required this.textColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onTap == null,
      child: Opacity(
        opacity: onTap == null ? 0.82 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 13,
                vertical: compact ? 6 : 7,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: backgroundColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(compact ? 16 : 18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Apply Now',
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 10.0 : 11.0,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

enum _AvailableRoleDecorationStyle {
  cornerBloom,
  topMist,
  sideGlow,
  auroraLift,
}

class _AvailableRolePalette {
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Alignment glowCenter;
  final Color glowColor;
  final Color chipTextColor;
  final Color surfaceTint;
  final _AvailableRoleDecorationStyle decorationStyle;

  const _AvailableRolePalette({
    required this.gradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.glowCenter,
    required this.glowColor,
    required this.chipTextColor,
    required this.surfaceTint,
    required this.decorationStyle,
  });
}

_AvailableRolePalette _availableRolePaletteFor(String uniqueKey) {
  const palettes = <_AvailableRolePalette>[
    _AvailableRolePalette(
      gradientColors: [Color(0xFFF8F4FF), Color(0xFFF1ECFF), Color(0xFFE9E2FF)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
      glowCenter: Alignment(0.90, -0.16),
      glowColor: Color(0xFFD6CBFF),
      chipTextColor: OpportunityDashboardPalette.primary,
      surfaceTint: Color(0xFFE3D8FF),
      decorationStyle: _AvailableRoleDecorationStyle.cornerBloom,
    ),
    _AvailableRolePalette(
      gradientColors: [Color(0xFFF9F7FF), Color(0xFFF2EEFF), Color(0xFFEAE5FF)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomCenter,
      glowCenter: Alignment(-0.76, 0.82),
      glowColor: Color(0xFFD9D0FF),
      chipTextColor: OpportunityDashboardPalette.primaryDark,
      surfaceTint: Color(0xFFDCD5FF),
      decorationStyle: _AvailableRoleDecorationStyle.topMist,
    ),
    _AvailableRolePalette(
      gradientColors: [Color(0xFFFCF8FF), Color(0xFFF4EEFF), Color(0xFFEDE5FF)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomRight,
      glowCenter: Alignment(0.84, 0.74),
      glowColor: Color(0xFFE0D1FF),
      chipTextColor: Color(0xFF5B34E6),
      surfaceTint: Color(0xFFE8DBFF),
      decorationStyle: _AvailableRoleDecorationStyle.sideGlow,
    ),
    _AvailableRolePalette(
      gradientColors: [Color(0xFFF6F1FF), Color(0xFFECE5FF), Color(0xFFE1D7FF)],
      gradientBegin: Alignment.topRight,
      gradientEnd: Alignment.bottomLeft,
      glowCenter: Alignment(0.86, -0.10),
      glowColor: Color(0xFFD4C7FF),
      chipTextColor: Color(0xFF4331CC),
      surfaceTint: Color(0xFFE7DCFF),
      decorationStyle: _AvailableRoleDecorationStyle.auroraLift,
    ),
  ];

  return palettes[uniqueKey.hashCode.abs() % palettes.length];
}

List<Widget> _buildAvailableRoleDecorations({
  required _AvailableRolePalette palette,
  required bool compact,
  required bool listLayout,
}) {
  switch (palette.decorationStyle) {
    case _AvailableRoleDecorationStyle.cornerBloom:
      return [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: palette.glowCenter,
                radius: listLayout ? 1.30 : 1.18,
                colors: [
                  palette.glowColor.withValues(alpha: 0.24),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: compact ? -18 : -22,
          right: compact ? -14 : -18,
          child: _GlowOrb(
            size: compact ? (listLayout ? 92 : 88) : (listLayout ? 106 : 98),
            color: palette.glowColor.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: compact ? -24 : -28,
          left: compact ? -18 : -22,
          child: _GlowOrb(
            size: compact ? (listLayout ? 94 : 98) : (listLayout ? 112 : 116),
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ];
    case _AvailableRoleDecorationStyle.topMist:
      return [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: compact ? (listLayout ? 42 : 46) : (listLayout ? 48 : 54),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          right: compact ? -22 : -26,
          top: compact ? 22 : 28,
          child: _GlowOrb(
            size: compact ? (listLayout ? 84 : 88) : (listLayout ? 96 : 100),
            color: palette.glowColor.withValues(alpha: 0.18),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ];
    case _AvailableRoleDecorationStyle.sideGlow:
      return [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.24),
                  Colors.transparent,
                  palette.glowColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          top: compact ? 52 : 60,
          left: compact ? -18 : -22,
          child: _GlowOrb(
            size: compact ? (listLayout ? 78 : 82) : (listLayout ? 88 : 92),
            color: palette.glowColor.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          bottom: compact ? -18 : -22,
          right: compact ? -12 : -16,
          child: _GlowOrb(
            size: compact ? (listLayout ? 86 : 92) : (listLayout ? 100 : 104),
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ];
    case _AvailableRoleDecorationStyle.auroraLift:
      return [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  palette.surfaceTint.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
        Positioned(
          top: compact ? -20 : -24,
          right: compact ? -10 : -14,
          child: _GlowOrb(
            size: compact ? (listLayout ? 94 : 100) : (listLayout ? 110 : 120),
            color: palette.glowColor.withValues(alpha: 0.20),
          ),
        ),
        Positioned(
          bottom: compact ? -18 : -22,
          left: compact ? -18 : -22,
          child: _GlowOrb(
            size: compact ? (listLayout ? 74 : 82) : (listLayout ? 88 : 98),
            color: palette.surfaceTint.withValues(alpha: 0.34),
          ),
        ),
        Positioned(
          top: compact ? 16 : 20,
          left: compact ? 16 : 20,
          child: Container(
            width: compact ? (listLayout ? 58 : 52) : (listLayout ? 68 : 60),
            height: compact ? (listLayout ? 58 : 52) : (listLayout ? 68 : 60),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ];
  }
}

class _AvailableRoleCard extends StatelessWidget {
  final _JobCardData job;
  final VoidCallback? onTap;
  final bool compact;

  const _AvailableRoleCard({
    required this.job,
    this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _availableRolePaletteFor(job.uniqueKey);
    final cardRadius = BorderRadius.circular(compact ? 20 : 24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette.gradientColors,
              begin: palette.gradientBegin,
              end: palette.gradientEnd,
            ),
            borderRadius: cardRadius,
            border: Border.all(
              color: palette.chipTextColor.withValues(alpha: 0.10),
            ),
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTight =
                    compact ||
                    constraints.maxWidth < 170 ||
                    constraints.maxHeight < 172;
                final cardPadding = EdgeInsets.fromLTRB(
                  isTight ? 11 : 13,
                  isTight ? 10 : 12,
                  isTight ? 11 : 13,
                  isTight ? 9 : 11,
                );
                final iconSize = isTight ? 15.5 : 17.5;
                final iconTileSize = isTight ? 32.0 : 36.0;
                final titleSize = isTight ? 12.6 : 13.6;
                final subtitleSize = isTight ? 9.6 : 10.3;
                final detailSize = isTight ? 9.0 : 9.8;
                final chipSize = isTight ? 8.6 : 9.1;

                return Stack(
                  children: [
                    ..._buildAvailableRoleDecorations(
                      palette: palette,
                      compact: isTight,
                      listLayout: false,
                    ),
                    Padding(
                      padding: cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: iconTileSize,
                                height: iconTileSize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.94),
                                      palette.surfaceTint.withValues(
                                        alpha: 0.88,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    isTight ? 12 : 14,
                                  ),
                                  border: Border.all(
                                    color: palette.chipTextColor.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  job.category.icon,
                                  color: palette.chipTextColor,
                                  size: iconSize,
                                ),
                              ),
                              const Spacer(),
                              if (job.typeBadge != null)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth * 0.44,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTight ? 7 : 8,
                                      vertical: isTight ? 4 : 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.chipTextColor.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        isTight ? 10 : 11,
                                      ),
                                      border: Border.all(
                                        color: palette.chipTextColor.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      job.typeBadge!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: chipSize,
                                        fontWeight: FontWeight.w700,
                                        color: palette.chipTextColor,
                                        letterSpacing: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isTight ? 6 : 8),
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                              color: OpportunityDashboardPalette.textPrimary,
                            ),
                          ),
                          SizedBox(height: isTight ? 2 : 3),
                          Text(
                            job.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w600,
                              color: OpportunityDashboardPalette.textSecondary,
                            ),
                          ),
                          SizedBox(height: isTight ? 5 : 6),
                          if (job.location != null &&
                              job.location!.trim().isNotEmpty) ...[
                            _AvailableRoleMetaLine(
                              icon: Icons.place_rounded,
                              text: job.location!,
                              fontSize: detailSize,
                              iconSize: isTight ? 12.5 : 13.5,
                              iconColor: palette.chipTextColor,
                              textColor:
                                  OpportunityDashboardPalette.textSecondary,
                            ),
                            SizedBox(height: isTight ? 4 : 5),
                          ],
                          if (job.salary != null &&
                              job.salary!.trim().isNotEmpty)
                            _AvailableRoleMetaLine(
                              icon: Icons.payments_rounded,
                              text: job.salary!,
                              fontSize: detailSize,
                              iconSize: isTight ? 12.5 : 13.5,
                              iconColor: palette.chipTextColor,
                              textColor: palette.chipTextColor,
                            ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: job.levelTag == null
                                    ? const SizedBox.shrink()
                                    : Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTight ? 7 : 8,
                                            vertical: isTight ? 4 : 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.chipTextColor
                                                .withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(
                                              isTight ? 11 : 12,
                                            ),
                                            border: Border.all(
                                              color: palette.chipTextColor
                                                  .withValues(alpha: 0.10),
                                            ),
                                          ),
                                          child: Text(
                                            job.levelTag!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: chipSize,
                                              fontWeight: FontWeight.w700,
                                              color: palette.chipTextColor,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              Container(
                                width: isTight ? 28 : 30,
                                height: isTight ? 28 : 30,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      palette.chipTextColor,
                                      palette.chipTextColor.withValues(
                                        alpha: 0.78,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: isTight ? 14 : 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableRoleMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final double fontSize;
  final double iconSize;
  final Color iconColor;
  final Color textColor;

  const _AvailableRoleMetaLine({
    required this.icon,
    required this.text,
    required this.fontSize,
    required this.iconSize,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _AvailableRoleListCard extends StatelessWidget {
  final _JobCardData job;
  final VoidCallback? onTap;
  final bool compact;

  // ignore: unused_element_parameter
  const _AvailableRoleListCard({
    required this.job,
    // ignore: unused_element_parameter
    this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        child: Ink(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
            border: Border.all(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 46 : 52,
                height: compact ? 46 : 52,
                decoration: BoxDecoration(
                  color: job.category.surfaceTint,
                  borderRadius: BorderRadius.circular(compact ? 16 : 18),
                ),
                child: Icon(
                  job.category.icon,
                  color: job.category.accentColor,
                  size: compact ? 21 : 24,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.location == null || job.location!.isEmpty
                          ? job.company
                          : '${job.company} • ${job.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: OpportunityDashboardPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (job.salary != null)
                    SizedBox(
                      width: compact ? 88 : 104,
                      child: Text(
                        job.salary!,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: job.category.accentColor,
                    size: compact ? 18 : 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolesViewToggle extends StatelessWidget {
  final _JobsViewMode viewMode;
  final ValueChanged<_JobsViewMode> onChanged;
  final bool compact;

  const _RolesViewToggle({
    required this.viewMode,
    required this.onChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 3 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(
          color: OpportunityDashboardPalette.border.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIconButton(
            icon: Icons.grid_view_rounded,
            isActive: viewMode == _JobsViewMode.grid,
            compact: compact,
            onTap: () => onChanged(_JobsViewMode.grid),
          ),
          SizedBox(width: compact ? 3 : 4),
          _ToggleIconButton(
            icon: Icons.view_list_rounded,
            isActive: viewMode == _JobsViewMode.list,
            compact: compact,
            onTap: () => onChanged(_JobsViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool compact;

  const _ToggleIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        child: Ink(
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          decoration: BoxDecoration(
            color: isActive
                ? OpportunityDashboardPalette.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(
              color: isActive
                  ? OpportunityDashboardPalette.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: compact ? 16 : 18,
            color: isActive
                ? OpportunityDashboardPalette.primary
                : OpportunityDashboardPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CompanyLogoTile extends StatelessWidget {
  final String logoUrl;
  final String companyName;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const _CompanyLogoTile({
    required this.logoUrl,
    required this.companyName,
    required this.size,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedCompanyName = companyName.trim();
    final initial = trimmedCompanyName.isEmpty
        ? 'A'
        : trimmedCompanyName[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: size * 0.34,
                  height: size * 0.34,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
            ),
    );
  }
}

class _JobsEmptyStateCard extends StatelessWidget {
  final String title;
  final String message;
  final bool compact;

  const _JobsEmptyStateCard({
    required this.title,
    required this.message,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              color: OpportunityDashboardPalette.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
            ),
            child: Icon(
              Icons.work_outline_rounded,
              color: OpportunityDashboardPalette.primary,
              size: compact ? 20 : 24,
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 11 : 12,
                    height: 1.35,
                    color: OpportunityDashboardPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCategoryData {
  final String key;
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color surfaceTint;
  final List<String> keywords;

  const _JobCategoryData({
    required this.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.surfaceTint,
    required this.keywords,
  });
}

class _JobCardData {
  final String id;
  final String title;
  final String company;
  final String subtitle;
  final String? location;
  final String? salary;
  final String? metadataLine;
  final String badge;
  final String? typeBadge;
  final String? levelTag;
  final String logoUrl;
  final _JobCategoryData category;
  final bool isFeaturedPreferred;
  final bool isPlaceholder;
  final OpportunityModel? opportunity;
  final String searchText;

  const _JobCardData({
    required this.id,
    required this.title,
    required this.company,
    required this.subtitle,
    required this.location,
    required this.salary,
    required this.metadataLine,
    required this.badge,
    required this.typeBadge,
    required this.levelTag,
    required this.logoUrl,
    required this.category,
    required this.isFeaturedPreferred,
    required this.isPlaceholder,
    required this.opportunity,
    required this.searchText,
  });

  factory _JobCardData.placeholder({
    required String title,
    required String company,
    String? subtitle,
    required String? location,
    required String? salary,
    required String badge,
    String? typeBadge,
    String? levelTag,
    required _JobCategoryData category,
    bool isFeaturedPreferred = false,
  }) {
    return _JobCardData(
      id: '',
      title: title,
      company: company,
      subtitle: subtitle ?? company,
      location: location,
      salary: salary,
      metadataLine: null,
      badge: badge,
      typeBadge: typeBadge,
      levelTag: levelTag,
      logoUrl: '',
      category: category,
      isFeaturedPreferred: isFeaturedPreferred,
      isPlaceholder: true,
      opportunity: null,
      searchText: [
        title,
        company,
        location ?? '',
        salary ?? '',
        badge,
        typeBadge ?? '',
        levelTag ?? '',
        category.label,
        category.key,
      ].join(' ').toLowerCase(),
    );
  }

  String get uniqueKey {
    if (id.isNotEmpty) {
      return id;
    }

    return '$title|$company|$badge';
  }
}
