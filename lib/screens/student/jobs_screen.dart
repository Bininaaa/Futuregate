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

  List<_JobCardData> _selectAvailableRoles(
    List<_JobCardData> jobs,
    List<_JobCardData> featuredJobs,
  ) {
    final featuredKeys = featuredJobs
        .take(2)
        .map((job) => job.uniqueKey)
        .toSet();
    final remaining = jobs
        .where((job) => !featuredKeys.contains(job.uniqueKey))
        .toList();

    final source = remaining.isNotEmpty ? remaining : jobs;
    return source.take(10).toList();
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
    final location = _locationLabel(opportunity);
    final salary = _compensationText(opportunity);
    final metadata = _metadataItems(opportunity, maxItems: 3);
    final metadataLine = metadata
        .where((item) => item != salary)
        .take(2)
        .join(' | ');
    final badge = _jobBadgeLabel(opportunity);
    final searchable = <String>[
      title,
      company,
      location ?? '',
      salary ?? '',
      metadata.join(' '),
      badge,
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
      location: location,
      salary: salary,
      metadataLine: metadataLine,
      badge: badge,
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
    final employmentLabel = _employmentTypeLabel(opportunity);
    if (employmentLabel != null) {
      return employmentLabel.toUpperCase();
    }

    final workMode = _workModeLabel(opportunity);
    if (workMode != null) {
      return workMode.toUpperCase();
    }

    return 'FULL TIME';
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

  String? _employmentTypeLabel(OpportunityModel opportunity) {
    return OpportunityMetadata.formatEmploymentType(opportunity.employmentType);
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
      location: 'Remote - Algiers',
      salary: 'DZD 120k/mo',
      badge: 'FULL TIME',
      category: _categories[1],
      isFeaturedPreferred: true,
    ),
    _JobCardData.placeholder(
      title: 'Cloud Support Engineer',
      company: 'Avenir Cloud',
      location: 'Hybrid - Oran',
      salary: 'DZD 105k/mo',
      badge: 'FULL TIME',
      category: _categories[0],
      isFeaturedPreferred: true,
    ),
    _JobCardData.placeholder(
      title: 'Growth Marketing Lead',
      company: 'Bright Studio',
      location: 'Remote',
      salary: 'DZD 95k/mo',
      badge: 'REMOTE',
      category: _categories[3],
      isFeaturedPreferred: true,
    ),
    _JobCardData.placeholder(
      title: 'Junior Frontend Developer',
      company: 'Pixel Foundry',
      location: 'Algiers',
      salary: 'DZD 75k/mo',
      badge: 'FULL TIME',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'UI Design Intern',
      company: 'Loom Studio',
      location: 'Remote',
      salary: 'Paid',
      badge: 'INTERNSHIP',
      category: _categories[1],
    ),
    _JobCardData.placeholder(
      title: 'Data Analyst',
      company: 'North Metrics',
      location: 'Hybrid',
      salary: 'DZD 88k/mo',
      badge: 'FULL TIME',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'Social Media Manager',
      company: 'Wave House',
      location: 'Remote',
      salary: 'DZD 82k/mo',
      badge: 'FULL TIME',
      category: _categories[3],
    ),
    _JobCardData.placeholder(
      title: 'Security Analyst',
      company: 'Shield Ops',
      location: 'Algiers',
      salary: 'DZD 110k/mo',
      badge: 'FULL TIME',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'Marketing Analyst',
      company: 'Signal Growth',
      location: 'Hybrid',
      salary: 'DZD 84k/mo',
      badge: 'FULL TIME',
      category: _categories[3],
    ),
    _JobCardData.placeholder(
      title: 'Backend Support',
      company: 'Stack Harbor',
      location: 'Remote',
      salary: 'DZD 90k/mo',
      badge: 'FULL TIME',
      category: _categories[0],
    ),
    _JobCardData.placeholder(
      title: 'Illustrator Intern',
      company: 'Sketchroom',
      location: 'Oran',
      salary: 'Paid',
      badge: 'INTERNSHIP',
      category: _categories[1],
    ),
    _JobCardData.placeholder(
      title: 'AI Trainer',
      company: 'Orbit AI',
      location: 'Remote',
      salary: 'DZD 115k/mo',
      badge: 'CONTRACT',
      category: _categories[0],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final opportunityProvider = context.watch<OpportunityProvider>();

    final allJobs = _buildJobCards(opportunityProvider);
    final filteredJobs = _applyFilters(allJobs);
    final featuredJobs = _selectFeaturedJobs(filteredJobs);
    final availableRoles = _selectAvailableRoles(filteredJobs, featuredJobs);
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
              ),
            ),
            if (showLoadingBar)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Find your next\n',
                        style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'breakthrough',
                        style: GoogleFonts.poppins(
                          fontSize: 34,
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _JobsSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onClear: _searchQuery.isEmpty
                      ? null
                      : _searchController.clear,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Categories',
                  actionLabel: 'See All',
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
                height: 102,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _JobCategoryChip(
                      category: category,
                      isSelected: category.key == _selectedCategoryKey,
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
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Featured Jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
              ),
            ),
            if (filteredJobs.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: const _JobsEmptyStateCard(
                    title: 'No featured jobs found',
                    message:
                        'Try another keyword or clear your category filter to see more roles.',
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 244,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: featuredJobs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final job = featuredJobs[index];
                      return SizedBox(
                        width: MediaQuery.of(context).size.width * 0.78,
                        child: _FeaturedJobCard(
                          job: job,
                          gradientColors: _featuredGradientFor(index),
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
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Available Roles',
                  trailing: _RolesViewToggle(
                    viewMode: _viewMode,
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: const _JobsEmptyStateCard(
                    title: 'No roles match your search',
                    message:
                        'Search by title or company, or tap See All to reset categories.',
                  ),
                ),
              )
            else if (_viewMode == _JobsViewMode.grid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final job = availableRoles[index];
                    return _AvailableRoleCard(
                      job: job,
                      onTap: job.opportunity == null
                          ? null
                          : () => _openOpportunity(job.opportunity!),
                    );
                  }, childCount: availableRoles.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 176,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final job = availableRoles[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == availableRoles.length - 1 ? 0 : 12,
                      ),
                      child: _AvailableRoleListCard(
                        job: job,
                        onTap: job.opportunity == null
                            ? null
                            : () => _openOpportunity(job.opportunity!),
                      ),
                    );
                  }, childCount: availableRoles.length),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  List<Color> _featuredGradientFor(int index) {
    switch (index % 4) {
      case 1:
        return const [OpportunityDashboardPalette.secondary, Color(0xFF0F766E)];
      case 2:
        return const [OpportunityDashboardPalette.accent, Color(0xFFEA580C)];
      case 3:
        return const [
          OpportunityDashboardPalette.primaryDark,
          OpportunityDashboardPalette.primary,
        ];
      case 0:
      default:
        return const [
          OpportunityDashboardPalette.primary,
          OpportunityDashboardPalette.primaryDark,
        ];
    }
  }
}

class _JobsHeaderBar extends StatelessWidget {
  final UserModel? user;
  final int unreadCount;
  final VoidCallback onNotificationsPressed;

  const _JobsHeaderBar({
    required this.user,
    required this.unreadCount,
    required this.onNotificationsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        border: Border(
          bottom: BorderSide(
            color: OpportunityDashboardPalette.border.withValues(alpha: 0.75),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              child: ProfileAvatar(user: user, radius: 18, fallbackName: 'J'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Jobs',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: OpportunityDashboardPalette.textPrimary,
                ),
              ),
            ),
            _NotificationBellButton(
              unreadCount: unreadCount,
              onTap: onNotificationsPressed,
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

  const _NotificationBellButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OpportunityDashboardPalette.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: OpportunityDashboardPalette.textPrimary,
                size: 22,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: OpportunityDashboardPalette.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
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

  const _JobsSearchBar({
    required this.controller,
    required this.focusNode,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: OpportunityDashboardPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search roles, companies...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: OpportunityDashboardPalette.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: OpportunityDashboardPalette.textSecondary,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
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
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: OpportunityDashboardPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              actionLabel!,
              style: GoogleFonts.poppins(
                fontSize: 13,
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

  const _JobCategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 78,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? OpportunityDashboardPalette.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: category.accentColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.accentColor.withValues(alpha: 0.14)
                      : category.surfaceTint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? category.accentColor.withValues(alpha: 0.22)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: category.accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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

class _FeaturedJobCard extends StatelessWidget {
  final _JobCardData job;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final VoidCallback? onApply;

  const _FeaturedJobCard({
    required this.job,
    required this.gradientColors,
    this.onTap,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final locationText = job.location == null || job.location!.isEmpty
        ? job.company
        : '${job.company} • ${job.location}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.24),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -22,
                right: -16,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -36,
                left: -22,
                child: Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CompanyLogoTile(
                          logoUrl: job.logoUrl,
                          companyName: job.company,
                          size: 46,
                          backgroundColor: Colors.white,
                          foregroundColor: gradientColors.first,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            job.badge,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
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
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    if (job.metadataLine != null &&
                        job.metadataLine!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        job.metadataLine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: job.salary == null
                              ? const SizedBox.shrink()
                              : Text(
                                  job.salary!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        _ApplyNowButton(
                          onTap: onApply,
                          textColor: gradientColors.first,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyNowButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color textColor;

  const _ApplyNowButton({required this.onTap, required this.textColor});

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
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Apply Now',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableRoleCard extends StatelessWidget {
  final _JobCardData job;
  final VoidCallback? onTap;

  const _AvailableRoleCard({required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: job.category.accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  job.category.icon,
                  color: job.category.accentColor,
                  size: 23,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.24,
                  color: OpportunityDashboardPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                job.company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: OpportunityDashboardPalette.textSecondary,
                ),
              ),
              if (job.metadataLine != null &&
                  job.metadataLine!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  job.metadataLine!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: OpportunityDashboardPalette.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: job.salary == null
                        ? const SizedBox.shrink()
                        : Text(
                            job.salary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: OpportunityDashboardPalette.primary,
                            ),
                          ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: job.category.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: job.category.accentColor,
                    ),
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

class _AvailableRoleListCard extends StatelessWidget {
  final _JobCardData job;
  final VoidCallback? onTap;

  const _AvailableRoleListCard({required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: OpportunityDashboardPalette.border.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: job.category.surfaceTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  job.category.icon,
                  color: job.category.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: OpportunityDashboardPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (job.salary != null)
                    Text(
                      job.salary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.primary,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: job.category.accentColor,
                    size: 20,
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

  const _RolesViewToggle({required this.viewMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIconButton(
            icon: Icons.grid_view_rounded,
            isActive: viewMode == _JobsViewMode.grid,
            onTap: () => onChanged(_JobsViewMode.grid),
          ),
          const SizedBox(width: 4),
          _ToggleIconButton(
            icon: Icons.view_list_rounded,
            isActive: viewMode == _JobsViewMode.list,
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

  const _ToggleIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive
                ? OpportunityDashboardPalette.primary
                : OpportunityDashboardPalette.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? Colors.white
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

  const _JobsEmptyStateCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OpportunityDashboardPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OpportunityDashboardPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: OpportunityDashboardPalette.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: OpportunityDashboardPalette.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OpportunityDashboardPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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
  final String? location;
  final String? salary;
  final String? metadataLine;
  final String badge;
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
    required this.location,
    required this.salary,
    required this.metadataLine,
    required this.badge,
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
    required String? location,
    required String? salary,
    required String badge,
    required _JobCategoryData category,
    bool isFeaturedPreferred = false,
  }) {
    return _JobCardData(
      id: '',
      title: title,
      company: company,
      location: location,
      salary: salary,
      metadataLine: null,
      badge: badge,
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
