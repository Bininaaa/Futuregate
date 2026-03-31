import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../providers/training_provider.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_dashboard_widgets.dart';
import 'jobs_screen.dart';
import 'opportunity_detail_screen.dart';
import 'trainings_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  final String? initialFilter;

  const OpportunitiesScreen({super.key, this.initialFilter});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchSectionKey = GlobalKey();
  final GlobalKey _trendingSectionKey = GlobalKey();
  final GlobalKey _latestSectionKey = GlobalKey();

  late _OpportunityDashboardFilter _activeFilter;
  String _searchQuery = '';
  String? _selectedEmploymentFilter;
  String? _selectedWorkModeFilter;
  bool _paidOnly = false;
  bool _closingSoonOnly = false;

  @override
  void initState() {
    super.initState();
    _activeFilter = _filterFromInitialValue(widget.initialFilter);
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
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextValue = _searchController.text.trim();
    if (_searchQuery == nextValue) {
      return;
    }

    setState(() {
      _searchQuery = nextValue;
    });
  }

  Future<void> _loadData({bool force = false}) async {
    final opportunityProvider = context.read<OpportunityProvider>();
    final trainingProvider = context.read<TrainingProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final userId = context.read<AuthProvider>().userModel?.uid;

    final futures = <Future<void>>[opportunityProvider.fetchOpportunities()];

    if (force || trainingProvider.trainings.isEmpty) {
      futures.add(trainingProvider.fetchTrainings());
    }

    if (userId != null && userId.isNotEmpty) {
      futures.add(savedProvider.fetchSavedOpportunities(userId));
    }

    await Future.wait(futures);
  }

  _OpportunityDashboardFilter _filterFromInitialValue(String? value) {
    switch (OpportunityType.parse(value)) {
      case OpportunityType.job:
        return _OpportunityDashboardFilter.job;
      case OpportunityType.internship:
        return _OpportunityDashboardFilter.internship;
      case OpportunityType.sponsoring:
        return _OpportunityDashboardFilter.sponsored;
      default:
        return _OpportunityDashboardFilter.all;
    }
  }

  List<OpportunityModel> _applyFilters(List<OpportunityModel> items) {
    final query = _searchQuery.toLowerCase();

    return items.where((opportunity) {
      if (!_matchesTypeFilter(opportunity)) {
        return false;
      }

      if (!_matchesStructuredFilters(opportunity)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchableFields = [
        opportunity.title,
        opportunity.companyName,
        opportunity.location,
        opportunity.description,
        opportunity.requirements,
        _typeLabel(opportunity.type),
        _deriveTrendingTag(opportunity),
        _employmentTypeLabel(opportunity) ?? '',
        _workModeLabel(opportunity) ?? '',
        _compensationText(opportunity) ?? '',
        OpportunityMetadata.formatPaidLabel(_effectiveIsPaid(opportunity)) ??
            '',
        OpportunityMetadata.normalizeDuration(opportunity.duration) ?? '',
        opportunity.deadlineLabel,
      ];

      return searchableFields.any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();
  }

  bool _matchesTypeFilter(OpportunityModel opportunity) {
    final type = OpportunityType.parse(opportunity.type);

    switch (_activeFilter) {
      case _OpportunityDashboardFilter.all:
        return true;
      case _OpportunityDashboardFilter.job:
        return type == OpportunityType.job;
      case _OpportunityDashboardFilter.internship:
        return type == OpportunityType.internship;
      case _OpportunityDashboardFilter.sponsored:
        return type == OpportunityType.sponsoring;
    }
  }

  bool _matchesStructuredFilters(OpportunityModel opportunity) {
    if (_selectedEmploymentFilter != null &&
        opportunity.employmentType != _selectedEmploymentFilter) {
      return false;
    }

    if (_selectedWorkModeFilter != null &&
        _normalizedWorkMode(opportunity) != _selectedWorkModeFilter) {
      return false;
    }

    if (_paidOnly && _effectiveIsPaid(opportunity) != true) {
      return false;
    }

    if (_closingSoonOnly) {
      final deadline = _deadlineFor(opportunity);
      if (deadline == null) {
        return false;
      }
      final difference = deadline.difference(DateTime.now());
      if (difference.isNegative || difference.inDays > 14) {
        return false;
      }
    }

    return true;
  }

  Future<void> _focusSearchField() async {
    await _scrollToKey(_searchSectionKey);
    if (!mounted) {
      return;
    }
    _searchFocusNode.requestFocus();
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
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

  void _openTrainings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingsScreen()),
    );
  }

  Future<void> _toggleSavedOpportunity(OpportunityModel opportunity) async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final userId = authProvider.userModel?.uid;

    if (userId == null || userId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save opportunities'),
        ),
      );
      return;
    }

    final matchingSaved = savedProvider.savedOpportunities
        .where((item) => item.opportunityId == opportunity.id)
        .toList();
    final existingSaved = matchingSaved.isNotEmpty ? matchingSaved.first : null;

    String? error;
    var message = 'Opportunity saved';

    if (existingSaved != null) {
      error = await savedProvider.unsaveOpportunity(existingSaved.id, userId);
      message = 'Removed from saved opportunities';
    } else {
      error = await savedProvider.saveOpportunity(
        studentId: userId,
        opportunityId: opportunity.id,
        title: opportunity.title,
        companyName: opportunity.companyName,
        type: opportunity.type,
        location: opportunity.location,
        deadline: opportunity.deadlineLabel,
      );
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(error ?? message)));
  }

  Future<void> _showFilterSheet() async {
    var draftFilter = _activeFilter;
    var draftEmploymentType = _selectedEmploymentFilter;
    var draftWorkMode = _selectedWorkModeFilter;
    var draftPaidOnly = _paidOnly;
    var draftClosingSoonOnly = _closingSoonOnly;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OpportunityDashboardPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
              IconData? icon,
            }) {
              return ChoiceChip(
                label: Text(label),
                avatar: icon == null ? null : Icon(icon, size: 18),
                selected: selected,
                onSelected: (_) => onTap(),
                selectedColor: OpportunityDashboardPalette.primary.withValues(
                  alpha: 0.14,
                ),
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? OpportunityDashboardPalette.primary
                      : OpportunityDashboardPalette.textSecondary,
                ),
                side: BorderSide(
                  color: selected
                      ? OpportunityDashboardPalette.primary
                      : OpportunityDashboardPalette.border,
                ),
                backgroundColor: OpportunityDashboardPalette.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse categories',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep the existing data source, but tailor what you see.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: OpportunityDashboardPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _dashboardFilters.map((filter) {
                          return buildChip(
                            label: filter.label,
                            icon: filter.icon,
                            selected: filter.value == draftFilter,
                            onTap: () {
                              setModalState(() {
                                draftFilter = filter.value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Employment type',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildChip(
                            label: 'Any',
                            selected: draftEmploymentType == null,
                            onTap: () {
                              setModalState(() {
                                draftEmploymentType = null;
                              });
                            },
                          ),
                          ...OpportunityMetadata.employmentTypes.map((type) {
                            final label =
                                OpportunityMetadata.formatEmploymentType(
                                  type,
                                ) ??
                                type;
                            return buildChip(
                              label: label,
                              selected: draftEmploymentType == type,
                              onTap: () {
                                setModalState(() {
                                  draftEmploymentType = type;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Work mode',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildChip(
                            label: 'Any',
                            selected: draftWorkMode == null,
                            onTap: () {
                              setModalState(() {
                                draftWorkMode = null;
                              });
                            },
                          ),
                          ...OpportunityMetadata.workModes.map((mode) {
                            final label =
                                OpportunityMetadata.formatWorkMode(mode) ??
                                mode;
                            return buildChip(
                              label: label,
                              selected: draftWorkMode == mode,
                              onTap: () {
                                setModalState(() {
                                  draftWorkMode = mode;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Quick filters',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OpportunityDashboardPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          buildChip(
                            label: 'Paid only',
                            selected: draftPaidOnly,
                            onTap: () {
                              setModalState(() {
                                draftPaidOnly = !draftPaidOnly;
                              });
                            },
                            icon: Icons.payments_outlined,
                          ),
                          buildChip(
                            label: 'Closing soon',
                            selected: draftClosingSoonOnly,
                            onTap: () {
                              setModalState(() {
                                draftClosingSoonOnly = !draftClosingSoonOnly;
                              });
                            },
                            icon: Icons.hourglass_bottom_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _activeFilter =
                                      _OpportunityDashboardFilter.all;
                                  _selectedEmploymentFilter = null;
                                  _selectedWorkModeFilter = null;
                                  _paidOnly = false;
                                  _closingSoonOnly = false;
                                  if (_searchQuery.isNotEmpty) {
                                    _searchController.clear();
                                  }
                                });
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    OpportunityDashboardPalette.textSecondary,
                                side: const BorderSide(
                                  color: OpportunityDashboardPalette.border,
                                ),
                              ),
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _activeFilter = draftFilter;
                                  _selectedEmploymentFilter =
                                      draftEmploymentType;
                                  _selectedWorkModeFilter = draftWorkMode;
                                  _paidOnly = draftPaidOnly;
                                  _closingSoonOnly = draftClosingSoonOnly;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    OpportunityDashboardPalette.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _setFilter(_OpportunityDashboardFilter filter) {
    if (_activeFilter == filter) {
      return;
    }

    setState(() {
      _activeFilter = filter;
    });
  }

  String _typeLabel(String type) {
    switch (OpportunityType.parse(type)) {
      case OpportunityType.internship:
        return 'Internships';
      case OpportunityType.sponsoring:
        return 'Sponsored';
      case OpportunityType.job:
      default:
        return 'Jobs';
    }
  }

  String _summaryText(int visibleCount, int totalCount) {
    final filterLabel = switch (_activeFilter) {
      _OpportunityDashboardFilter.all => 'opportunities',
      _OpportunityDashboardFilter.job => 'jobs',
      _OpportunityDashboardFilter.internship => 'internships',
      _OpportunityDashboardFilter.sponsored => 'sponsored opportunities',
    };

    if (_searchQuery.isEmpty &&
        _activeFilter == _OpportunityDashboardFilter.all) {
      return '$totalCount open opportunities curated for students.';
    }

    return 'Showing $visibleCount $filterLabel from $totalCount open listings.';
  }

  String _formatCount(int count, String singular, String plural) {
    if (count <= 0) {
      return plural;
    }

    return '$count ${count == 1 ? singular : plural}';
  }

  String _supportingCountText({
    required int count,
    required String singular,
    required String plural,
    required String fallback,
  }) {
    if (count <= 0) {
      return fallback;
    }

    return _formatCount(count, singular, plural);
  }

  DateTime? _postedAt(OpportunityModel opportunity) {
    return opportunity.createdAt?.toDate() ??
        opportunity.readDateTime([
          'postedAt',
          'publishedAt',
          'created_at',
          'posted_at',
          'published_at',
        ]);
  }

  DateTime? _deadlineFor(OpportunityModel opportunity) {
    final explicitDeadline =
        opportunity.applicationDeadline ??
        _parseDeadlineValue(opportunity.deadlineLabel);
    if (explicitDeadline != null) {
      return explicitDeadline;
    }

    final fallback = opportunity.readDateTime([
      'deadlineAt',
      'closingDate',
      'closingAt',
      'expiresAt',
      'expiryDate',
      'endDate',
    ]);
    if (fallback == null) {
      return null;
    }

    final isDateOnly =
        fallback.hour == 0 &&
        fallback.minute == 0 &&
        fallback.second == 0 &&
        fallback.millisecond == 0 &&
        fallback.microsecond == 0;

    if (!isDateOnly) {
      return fallback;
    }

    return DateTime(fallback.year, fallback.month, fallback.day, 23, 59, 59);
  }

  DateTime? _parseDeadlineValue(String rawDeadline) {
    final trimmed = rawDeadline.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final hasExplicitTime = trimmed.contains(':') || trimmed.contains('T');
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) {
      return hasExplicitTime
          ? direct
          : DateTime(direct.year, direct.month, direct.day, 23, 59, 59);
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
        final parsed = format.parseStrict(trimmed);
        return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  String _formatDeadlineDisplay(OpportunityModel opportunity) {
    final parsed = _deadlineFor(opportunity);
    if (parsed == null) {
      final fallback = opportunity.deadlineLabel.trim();
      return fallback.isEmpty ? 'No deadline' : fallback;
    }

    return DateFormat('MMM d').format(parsed);
  }

  String _relativePostedTime(OpportunityModel opportunity) {
    final createdAt = _postedAt(opportunity);
    if (createdAt == null) {
      return 'Recently added';
    }

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    if (difference.inDays < 30) {
      final weeks = math.max(1, (difference.inDays / 7).floor());
      return '${weeks}w ago';
    }

    return DateFormat('MMM d').format(createdAt);
  }

  bool _isNewOpportunity(OpportunityModel opportunity) {
    final createdAt = _postedAt(opportunity);
    if (createdAt == null) {
      return false;
    }

    return DateTime.now().difference(createdAt).inDays < 3;
  }

  String _closingSoonText(OpportunityModel opportunity) {
    final deadline = _deadlineFor(opportunity);
    if (deadline == null) {
      return 'Deadline unavailable';
    }

    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Closes today';
    }
    if (difference.inHours < 1) {
      final minutes = math.max(1, difference.inMinutes);
      return 'Closes in $minutes min';
    }
    if (difference.inHours < 24) {
      return 'Closes in ${difference.inHours} hours';
    }
    if (difference.inDays == 1) {
      return 'Closes tomorrow';
    }

    return 'Closes in ${difference.inDays} days';
  }

  Color _closingSoonColor(OpportunityModel opportunity) {
    final deadline = _deadlineFor(opportunity);
    if (deadline == null) {
      return OpportunityDashboardPalette.warning;
    }

    final difference = deadline.difference(DateTime.now());
    return difference.inHours <= 24
        ? OpportunityDashboardPalette.error
        : OpportunityDashboardPalette.warning;
  }

  String? _explicitCategoryTag(OpportunityModel opportunity) {
    final rawTag = opportunity.readString([
      'category',
      'tag',
      'field',
      'domain',
      'industry',
      'department',
      'track',
    ]);
    if (rawTag == null) {
      return null;
    }

    final compact = rawTag.split(RegExp(r'[/,&|-]')).first.trim();
    if (compact.isEmpty) {
      return null;
    }

    final words = compact
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final normalized = words.take(2).join(' ').toUpperCase();
    if (normalized.length <= 12) {
      return normalized;
    }

    return words.isEmpty ? null : words.first.toUpperCase();
  }

  String _deriveTrendingTag(OpportunityModel opportunity) {
    final explicitTag = _explicitCategoryTag(opportunity);
    if (explicitTag != null) {
      return explicitTag;
    }

    final text = [
      opportunity.title,
      opportunity.description,
      opportunity.requirements,
    ].join(' ').toLowerCase();

    if (text.contains('design') ||
        text.contains('ui') ||
        text.contains('ux') ||
        text.contains('graphic')) {
      return 'DESIGN';
    }
    if (text.contains('market') ||
        text.contains('business') ||
        text.contains('sales')) {
      return 'BUSINESS';
    }
    if (text.contains('finance') ||
        text.contains('account') ||
        text.contains('audit')) {
      return 'FINANCE';
    }
    if (text.contains('research') ||
        text.contains('lab') ||
        text.contains('analysis')) {
      return 'RESEARCH';
    }
    if (text.contains('data') ||
        text.contains('software') ||
        text.contains('engineer') ||
        text.contains('developer') ||
        text.contains('tech')) {
      return 'TECH';
    }

    return switch (OpportunityType.parse(opportunity.type)) {
      OpportunityType.internship => 'INTERNSHIP',
      OpportunityType.sponsoring => 'SPONSORED',
      _ => 'JOB',
    };
  }

  List<OpportunityModel> _buildTrendingItems(List<OpportunityModel> visible) {
    final featured = visible.where((item) => item.isFeatured).toList();
    final items = <OpportunityModel>[...featured];

    for (final opportunity in visible) {
      if (items.any((item) => item.id == opportunity.id)) {
        continue;
      }
      items.add(opportunity);
      if (items.length >= 6) {
        break;
      }
    }

    return items.take(6).toList();
  }

  List<OpportunityModel> _buildClosingSoonItems(
    List<OpportunityModel> visible,
  ) {
    final items = visible.where((opportunity) {
      final deadline = _deadlineFor(opportunity);
      if (deadline == null) {
        return false;
      }

      final difference = deadline.difference(DateTime.now());
      return !difference.isNegative && difference.inDays <= 14;
    }).toList();

    items.sort((a, b) {
      final first = _deadlineFor(a);
      final second = _deadlineFor(b);
      if (first == null && second == null) {
        return 0;
      }
      if (first == null) {
        return 1;
      }
      if (second == null) {
        return -1;
      }

      return first.compareTo(second);
    });

    return items.take(5).toList();
  }

  String _companyName(OpportunityModel opportunity) {
    final companyName = opportunity.companyName.trim();
    return companyName.isEmpty ? 'AvenirDZ partner' : companyName;
  }

  String? _companyNameOrNull(OpportunityModel opportunity) {
    final companyName = opportunity.companyName.trim();
    return companyName.isEmpty ? null : companyName;
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
      _ => null,
    };
  }

  String _companyLocationText(OpportunityModel opportunity) {
    final company = _companyName(opportunity);
    final location = _locationLabel(opportunity);

    if (location == null || location.isEmpty) {
      return company;
    }

    return '$company - $location';
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
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.contains('http') ||
        normalized.contains('www.') ||
        normalized.contains('.png') ||
        normalized.contains('.jpg') ||
        normalized.contains('.jpeg') ||
        normalized.contains('.webp')) {
      return null;
    }

    if (normalized.contains('unpaid')) {
      return null;
    }

    final looksLikePaidLabel =
        normalized == 'paid' ||
        normalized == 'paid internship' ||
        normalized == 'paid role' ||
        normalized == 'paid opportunity';
    if (looksLikePaidLabel) {
      return 'Paid';
    }

    final hasCompensationSignal = RegExp(
      r'(\$|usd|eur|dzd|k\b|/month|per month|per hour|monthly|hourly|\d)',
      caseSensitive: false,
    ).hasMatch(value);

    if (!hasCompensationSignal) {
      return null;
    }

    if (value.length > 36) {
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

  List<String> _latestStatusItems(OpportunityModel opportunity) {
    final items = <String>[];
    final deadline = _deadlineFor(opportunity);
    final postedAt = _postedAt(opportunity);
    final metadataItems = _metadataItems(opportunity, maxItems: 3);

    items.addAll(metadataItems);

    if (deadline != null) {
      final difference = deadline.difference(DateTime.now());
      if (!difference.isNegative && difference.inDays <= 14) {
        items.add(_closingSoonText(opportunity));
      } else if (postedAt == null) {
        items.add('Deadline ${_formatDeadlineDisplay(opportunity)}');
      }
    }

    if (postedAt != null && metadataItems.length < 2) {
      items.add('Posted ${_relativePostedTime(opportunity)}');
    }

    if (items.isEmpty) {
      items.add(_typeLabel(opportunity.type));
    }

    return _uniqueValues(items).take(4).toList();
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

  List<String> _uniqueValues(List<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        result.add(trimmed);
      }
    }

    return result;
  }

  Widget _buildHeaderSection(int visibleCount, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find your next move.',
          style: GoogleFonts.poppins(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: OpportunityDashboardPalette.textPrimary,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Browse jobs, internships, sponsored tracks, and training picks designed for students.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            height: 1.35,
            color: OpportunityDashboardPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _searchSectionKey,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search jobs, internships or sponsored roles',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: OpportunityDashboardPalette.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: OpportunityDashboardPalette.textSecondary,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: OpportunityDashboardPalette.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: OpportunityDashboardPalette.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: OpportunityDashboardPalette.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dashboardFilters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _dashboardFilters[index];
              final isActive = filter.value == _activeFilter;

              return GestureDetector(
                onTap: () => _setFilter(filter.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? OpportunityDashboardPalette.primary.withValues(
                            alpha: 0.12,
                          )
                        : OpportunityDashboardPalette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? OpportunityDashboardPalette.primary
                          : OpportunityDashboardPalette.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        size: 14,
                        color: isActive
                            ? OpportunityDashboardPalette.primary
                            : OpportunityDashboardPalette.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? OpportunityDashboardPalette.primary
                              : OpportunityDashboardPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _summaryText(visibleCount, totalCount),
            key: ValueKey(
              'summary-$visibleCount-$totalCount-$_activeFilter-$_searchQuery',
            ),
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: OpportunityDashboardPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final opportunityProvider = context.watch<OpportunityProvider>();
    final trainingProvider = context.watch<TrainingProvider>();
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final trendingCardHeight = textScale > 1.08 ? 244.0 : 232.0;

    final allOpportunities = opportunityProvider.opportunities;
    final visibleOpportunities = _applyFilters(allOpportunities);
    final jobItems = allOpportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) == OpportunityType.job,
        )
        .toList();
    final internshipItems = allOpportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) ==
              OpportunityType.internship,
        )
        .toList();
    final sponsoredItems = allOpportunities
        .where(
          (opportunity) =>
              OpportunityType.parse(opportunity.type) ==
              OpportunityType.sponsoring,
        )
        .toList();
    final trainingItems = trainingProvider.trainings
        .where((training) => training.isApproved)
        .toList();
    final trendingItems = _buildTrendingItems(visibleOpportunities);
    final closingSoonItems = _buildClosingSoonItems(visibleOpportunities);
    final savedIds = savedProvider.savedOpportunities
        .map((item) => item.opportunityId)
        .toSet();

    return Scaffold(
      backgroundColor: OpportunityDashboardPalette.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: OpportunityDashboardPalette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'AvenirDZ',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: OpportunityDashboardPalette.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Focus search',
            onPressed: _focusSearchField,
            icon: const Icon(
              Icons.search_rounded,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
          IconButton(
            tooltip: 'Filter opportunities',
            onPressed: _showFilterSheet,
            icon: const Icon(
              Icons.tune_rounded,
              color: OpportunityDashboardPalette.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: opportunityProvider.isLoading && allOpportunities.isEmpty
          ? const OpportunityDashboardLoadingSkeleton()
          : RefreshIndicator(
              color: OpportunityDashboardPalette.primary,
              backgroundColor: OpportunityDashboardPalette.surface,
              onRefresh: () => _loadData(force: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  if (opportunityProvider.isLoading &&
                      allOpportunities.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHeaderSection(
                        visibleOpportunities.length,
                        allOpportunities.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          OpportunityHeroCard(
                            title: 'Jobs',
                            subtitle:
                                'Discover premium open roles from trusted employers and remote-ready teams.',
                            supportingLabel: _supportingCountText(
                              count: jobItems.length,
                              singular: 'open position',
                              plural: 'open positions',
                              fallback: 'Explore verified openings',
                            ),
                            icon: Icons.work_outline_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JobsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 140,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OpportunityCategoryCard(
                                    title: 'Internships',
                                    subtitle: 'Hands-on student placements',
                                    caption: _supportingCountText(
                                      count: internshipItems.length,
                                      singular: 'open internship',
                                      plural: 'open internships',
                                      fallback: 'Build experience faster',
                                    ),
                                    icon: Icons.school_outlined,
                                    color:
                                        OpportunityDashboardPalette.secondary,
                                    backgroundColor: OpportunityDashboardPalette
                                        .secondary
                                        .withValues(alpha: 0.10),
                                    onTap: () async {
                                      _setFilter(
                                        _OpportunityDashboardFilter.internship,
                                      );
                                      await _scrollToKey(_latestSectionKey);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OpportunityCategoryCard(
                                    title: 'Sponsored',
                                    subtitle: 'Partner-backed support',
                                    caption: _supportingCountText(
                                      count: sponsoredItems.length,
                                      singular: 'active track',
                                      plural: 'active tracks',
                                      fallback: 'Partner-backed tracks',
                                    ),
                                    icon: Icons.campaign_outlined,
                                    color: OpportunityDashboardPalette.accent,
                                    backgroundColor: OpportunityDashboardPalette
                                        .accent
                                        .withValues(alpha: 0.10),
                                    onTap: () async {
                                      _setFilter(
                                        _OpportunityDashboardFilter.sponsored,
                                      );
                                      await _scrollToKey(_latestSectionKey);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TrainingProgramsCard(
                            title: 'Training Programs',
                            subtitle: '',
                            badgeLabel: trainingProvider.isLoading
                                ? 'Loading...'
                                : _supportingCountText(
                                    count: trainingItems.length,
                                    singular: 'resource',
                                    plural: 'resources',
                                    fallback: 'Updated weekly',
                                  ),
                            onTap: _openTrainings,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      key: _trendingSectionKey,
                      child: TrendingOpportunitySectionHeader(
                        title: 'Trending Opportunities',
                        subtitle: 'Based on student activity this week',
                        actionLabel: 'View All',
                        onAction: () async {
                          _setFilter(_OpportunityDashboardFilter.all);
                          await _scrollToKey(_latestSectionKey);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 0, 0),
                    sliver: SliverToBoxAdapter(
                      child: trendingItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: OpportunityDashboardEmptyState(
                                icon: Icons.trending_up_rounded,
                                title: 'No trending items right now',
                                subtitle:
                                    'Fresh recommendations will appear here as new listings arrive.',
                                color: OpportunityDashboardPalette.primary,
                              ),
                            )
                          : SizedBox(
                              height: trendingCardHeight,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(right: 20),
                                itemCount: trendingItems.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final opportunity = trendingItems[index];

                                  return TrendingOpportunityCard(
                                    opportunity: opportunity,
                                    badgeLabel: _deriveTrendingTag(opportunity),
                                    companyName: _companyNameOrNull(
                                      opportunity,
                                    ),
                                    locationText: _locationLabel(opportunity),
                                    metadataText:
                                        OpportunityMetadata.uniqueNonEmpty(
                                          _metadataItems(
                                            opportunity,
                                            maxItems: 3,
                                          ).where(
                                            (item) =>
                                                item !=
                                                _compensationText(opportunity),
                                          ),
                                        ).join(' | '),
                                    compensationText: _compensationText(
                                      opportunity,
                                    ),
                                    isSaved: savedIds.contains(opportunity.id),
                                    isBusy: savedProvider.isLoading,
                                    onTap: () => _openOpportunity(opportunity),
                                    onToggleSaved: () =>
                                        _toggleSavedOpportunity(opportunity),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverToBoxAdapter(
                      key: _latestSectionKey,
                      child: const OpportunitySectionHeader(
                        title: 'Latest Opportunities',
                        subtitle:
                            'Fresh roles, internships, and sponsored tracks for quick exploration',
                        accentColor: OpportunityDashboardPalette.success,
                      ),
                    ),
                  ),
                  if (visibleOpportunities.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: OpportunityDashboardEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No opportunities found',
                          subtitle:
                              'Try adjusting your search or filters to uncover more matches.',
                          color: OpportunityDashboardPalette.success,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverList.separated(
                        itemCount: visibleOpportunities.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final opportunity = visibleOpportunities[index];
                          return OpportunityListTile(
                            opportunity: opportunity,
                            companyLocationText: _companyLocationText(
                              opportunity,
                            ),
                            statusItems: _latestStatusItems(opportunity),
                            badgeText: _isNewOpportunity(opportunity)
                                ? 'NEW'
                                : null,
                            badgeColor: OpportunityDashboardPalette.success,
                            isSaved: savedIds.contains(opportunity.id),
                            isBusy: savedProvider.isLoading,
                            onTap: () => _openOpportunity(opportunity),
                            onToggleSaved: () =>
                                _toggleSavedOpportunity(opportunity),
                          );
                        },
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: const OpportunitySectionHeader(
                        title: 'Closing Soon',
                        subtitle:
                            'Urgent applications that need attention before they expire',
                        accentColor: OpportunityDashboardPalette.error,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: closingSoonItems.isEmpty
                        ? SliverToBoxAdapter(
                            child: OpportunityDashboardEmptyState(
                              icon: Icons.hourglass_bottom_rounded,
                              title: 'No urgent deadlines yet',
                              subtitle:
                                  'Once a listing is nearing its deadline, it will show up here.',
                              color: OpportunityDashboardPalette.error,
                            ),
                          )
                        : SliverList.separated(
                            itemCount: closingSoonItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final opportunity = closingSoonItems[index];
                              final urgencyColor = _closingSoonColor(
                                opportunity,
                              );

                              return OpportunityListTile(
                                opportunity: opportunity,
                                companyLocationText: _companyLocationText(
                                  opportunity,
                                ),
                                statusItems: [
                                  _closingSoonText(opportunity),
                                  ..._metadataItems(opportunity, maxItems: 2),
                                ],
                                badgeText: 'URGENT',
                                badgeColor: urgencyColor,
                                statusColor: urgencyColor,
                                isSaved: savedIds.contains(opportunity.id),
                                isBusy: savedProvider.isLoading,
                                onTap: () => _openOpportunity(opportunity),
                                onToggleSaved: () =>
                                    _toggleSavedOpportunity(opportunity),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

enum _OpportunityDashboardFilter { all, job, internship, sponsored }

class _DashboardFilterDefinition {
  final _OpportunityDashboardFilter value;
  final String label;
  final IconData icon;

  const _DashboardFilterDefinition({
    required this.value,
    required this.label,
    required this.icon,
  });
}

const List<_DashboardFilterDefinition> _dashboardFilters = [
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.all,
    label: 'All',
    icon: Icons.apps_rounded,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.job,
    label: 'Jobs',
    icon: Icons.work_outline_rounded,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.internship,
    label: 'Internships',
    icon: Icons.school_outlined,
  ),
  _DashboardFilterDefinition(
    value: _OpportunityDashboardFilter.sponsored,
    label: 'Sponsored',
    icon: Icons.campaign_outlined,
  ),
];
