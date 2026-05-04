import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/admin_palette.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';

class AdminEarlyAccessScreen extends StatefulWidget {
  final bool embedded;

  const AdminEarlyAccessScreen({super.key, this.embedded = false});

  @override
  State<AdminEarlyAccessScreen> createState() => _AdminEarlyAccessScreenState();
}

enum _EarlyAccessQueueFilter { pending, approved, rejected, all }

class _AdminEarlyAccessScreenState extends State<AdminEarlyAccessScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _busyOpportunityIds = <String>{};

  _EarlyAccessQueueFilter _selectedFilter = _EarlyAccessQueueFilter.pending;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (nextQuery == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = nextQuery;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildEarlyAccessStream() {
    return FirebaseFirestore.instance
        .collection('opportunities')
        .where('earlyAccessRequested', isEqualTo: true)
        .snapshots();
  }

  Future<void> _refreshQueue() {
    return FirebaseFirestore.instance
        .collection('opportunities')
        .where('earlyAccessRequested', isEqualTo: true)
        .limit(1)
        .get()
        .then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final screen = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildEarlyAccessStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppLoadingView(density: AppLoadingDensity.compact);
        }

        if (snapshot.hasError) {
          return AdminEmptyState(
            icon: Icons.error_outline_rounded,
            title: l10n.uiOpportunityUnavailable,
            message: snapshot.error.toString(),
            action: FilledButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retryLabel),
            ),
          );
        }

        final records = _recordsFromSnapshot(snapshot.data);
        final summary = _EarlyAccessSummary.from(records);
        final filteredRecords = _filterRecords(records, l10n);

        return RefreshIndicator(
          color: AdminPalette.primary,
          onRefresh: _refreshQueue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    widget.embedded ? 16 : 12,
                    16,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EarlyAccessHero(summary: summary),
                      const SizedBox(height: 14),
                      AdminSearchField(
                        controller: _searchController,
                        hintText: l10n
                            .uiSearchOpportunitiesByTitleCompanyLocationStatusOrCompensation,
                        prefixIcon: Icons.manage_search_rounded,
                        onClear: () {
                          _searchController.clear();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                      const SizedBox(height: 12),
                      _EarlyAccessFilterBar(
                        summary: summary,
                        selected: _selectedFilter,
                        onChanged: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (filteredRecords.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EarlyAccessEmptyState(
                    hasAnyRecords: records.isNotEmpty,
                    filter: _selectedFilter,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: SliverList.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filteredRecords.length - 1 ? 0 : 12,
                        ),
                        child: _EarlyAccessCard(
                          record: record,
                          isBusy: _busyOpportunityIds.contains(
                            record.opportunity.id,
                          ),
                          onOpenDetails: () => _showRecordDetails(record),
                          onApprove: () => _showApproveDialog(record),
                          onReject: () => _showRejectDialog(record),
                          onRemove: () => _makeNormal(record),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return screen;
    }

    return AdminShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AdminPalette.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(l10n.earlyAccessLabel),
        ),
        body: SafeArea(top: false, child: screen),
      ),
    );
  }

  List<_EarlyAccessRecord> _recordsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>>? snapshot,
  ) {
    final records = (snapshot?.docs ?? const [])
        .map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return _EarlyAccessRecord(
            opportunity: OpportunityModel.fromMap(data),
            requestedAt: _dateTimeFromValue(data['requestedEarlyAccessAt']),
            reviewedAt: _dateTimeFromValue(data['earlyAccessReviewedAt']),
          );
        })
        .toList(growable: false);

    return records..sort(_compareRecords);
  }

  int _compareRecords(_EarlyAccessRecord a, _EarlyAccessRecord b) {
    final rankDiff = _statusRank(a).compareTo(_statusRank(b));
    if (rankDiff != 0) {
      return rankDiff;
    }

    final bRequested = b.requestedAt?.millisecondsSinceEpoch ?? 0;
    final aRequested = a.requestedAt?.millisecondsSinceEpoch ?? 0;
    return bRequested.compareTo(aRequested);
  }

  int _statusRank(_EarlyAccessRecord record) {
    switch (record.opportunity.earlyAccessStatus) {
      case 'pending':
        return 0;
      case 'approved':
        return 1;
      case 'rejected':
        return 2;
      default:
        return 3;
    }
  }

  List<_EarlyAccessRecord> _filterRecords(
    List<_EarlyAccessRecord> records,
    AppLocalizations l10n,
  ) {
    final query = _searchQuery.toLowerCase();

    return records
        .where((record) {
          final status = record.opportunity.earlyAccessStatus;
          final matchesFilter = switch (_selectedFilter) {
            _EarlyAccessQueueFilter.pending => status == 'pending',
            _EarlyAccessQueueFilter.approved => status == 'approved',
            _EarlyAccessQueueFilter.rejected => status == 'rejected',
            _EarlyAccessQueueFilter.all => true,
          };

          if (!matchesFilter) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          return _searchableText(record, l10n).contains(query);
        })
        .toList(growable: false);
  }

  String _searchableText(_EarlyAccessRecord record, AppLocalizations l10n) {
    final opportunity = record.opportunity;
    return [
      opportunity.title,
      opportunity.companyName,
      opportunity.location,
      OpportunityType.label(opportunity.type, l10n),
      opportunity.description,
      opportunity.requirements,
      opportunity.earlyAccessStatus,
      _statusLabel(record, l10n),
    ].join(' ').toLowerCase();
  }

  void _showRecordDetails(_EarlyAccessRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _EarlyAccessDetailsSheet(
          record: record,
          isBusy: _busyOpportunityIds.contains(record.opportunity.id),
          onApprove: () =>
              _closeDetailsAnd(sheetContext, () => _showApproveDialog(record)),
          onReject: () =>
              _closeDetailsAnd(sheetContext, () => _showRejectDialog(record)),
          onRemove: () =>
              _closeDetailsAnd(sheetContext, () => _makeNormal(record)),
        );
      },
    );
  }

  void _closeDetailsAnd(BuildContext sheetContext, VoidCallback action) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        action();
      }
    });
  }

  Future<void> _showApproveDialog(_EarlyAccessRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    final defaultDelay = context
        .read<PremiumProvider>()
        .config
        .earlyAccessDefaultDelayHours;
    final currentDelay =
        record.opportunity.earlyAccessDurationHours ?? defaultDelay;
    final delayController = TextEditingController(text: '$currentDelay');
    var selectedDelay = currentDelay;

    final delayHours = await showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AdminSurface(
                  radius: 28,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  border: Border.all(
                    color: AdminPalette.success.withValues(alpha: 0.18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DialogHeading(
                        icon: Icons.flash_on_rounded,
                        iconColor: AdminPalette.success,
                        title: l10n.earlyAccessApproveButton,
                        subtitle: DisplayText.opportunityTitle(
                          record.opportunity.title,
                          fallback: l10n.uiUntitledOpportunity,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: delayController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.earlyAccessDelayLabel,
                          suffixText: 'h',
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value.trim());
                          if (parsed != null && parsed > 0) {
                            selectedDelay = parsed;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [24, 48, 72, 96].map((hours) {
                          return _DelayChoiceChip(
                            label: l10n.earlyAccessTimeHours(hours),
                            selected: selectedDelay == hours,
                            onTap: () {
                              setDialogState(() {
                                selectedDelay = hours;
                                delayController.text = '$hours';
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(l10n.cancelLabel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                final parsed =
                                    int.tryParse(delayController.text.trim()) ??
                                    selectedDelay;
                                final normalized = parsed.clamp(1, 336).toInt();
                                Navigator.of(dialogContext).pop(normalized);
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(l10n.earlyAccessApproveButton),
                              style: FilledButton.styleFrom(
                                backgroundColor: AdminPalette.success,
                                foregroundColor: Colors.white,
                              ),
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

    delayController.dispose();

    if (delayHours == null || !mounted) {
      return;
    }

    await _approve(record, delayHours);
  }

  Future<void> _showRejectDialog(_EarlyAccessRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: AdminSurface(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              border: Border.all(
                color: AdminPalette.danger.withValues(alpha: 0.18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogHeading(
                    icon: Icons.close_rounded,
                    iconColor: AdminPalette.danger,
                    title: l10n.earlyAccessRejectButton,
                    subtitle: DisplayText.opportunityTitle(
                      record.opportunity.title,
                      fallback: l10n.uiUntitledOpportunity,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: l10n.earlyAccessRejectReasonHint,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(l10n.cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(
                            dialogContext,
                          ).pop(reasonController.text.trim()),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: Text(l10n.earlyAccessRejectButton),
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminPalette.danger,
                            foregroundColor: Colors.white,
                          ),
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

    reasonController.dispose();

    if (reason == null || !mounted) {
      return;
    }

    await _reject(record, reason);
  }

  Future<void> _approve(_EarlyAccessRecord record, int delayHours) async {
    final l10n = AppLocalizations.of(context)!;
    await _runAction(
      record.opportunity.id,
      action: () {
        final adminUid = context.read<AuthProvider>().userModel?.uid ?? '';
        return context.read<PremiumProvider>().approveEarlyAccess(
          opportunityId: record.opportunity.id,
          adminUid: adminUid,
          delayHours: delayHours,
        );
      },
      successTitle: l10n.earlyAccessApproveButton,
      successMessage: l10n.earlyAccessApprovedStatus,
      successType: AppFeedbackType.success,
    );
  }

  Future<void> _reject(_EarlyAccessRecord record, String reason) async {
    final l10n = AppLocalizations.of(context)!;
    await _runAction(
      record.opportunity.id,
      action: () {
        final adminUid = context.read<AuthProvider>().userModel?.uid ?? '';
        return context.read<PremiumProvider>().rejectEarlyAccess(
          opportunityId: record.opportunity.id,
          adminUid: adminUid,
          reason: reason,
        );
      },
      successTitle: l10n.earlyAccessRejectButton,
      successMessage: l10n.earlyAccessRejectedStatus,
      successType: AppFeedbackType.removed,
    );
  }

  Future<void> _makeNormal(_EarlyAccessRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    await _runAction(
      record.opportunity.id,
      action: () =>
          context.read<PremiumProvider>().makePostNormal(record.opportunity.id),
      successTitle: l10n.adminEarlyAccessMakeNormalButton,
      successMessage: l10n.earlyAccessNoneStatus,
      successType: AppFeedbackType.info,
    );
  }

  Future<void> _runAction(
    String opportunityId, {
    required Future<void> Function() action,
    required String successTitle,
    required String successMessage,
    required AppFeedbackType successType,
  }) async {
    if (_busyOpportunityIds.contains(opportunityId)) {
      return;
    }

    setState(() {
      _busyOpportunityIds.add(opportunityId);
    });

    try {
      await action();
      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        successMessage,
        title: successTitle,
        type: successType,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        error.toString(),
        title: AppLocalizations.of(context)!.uiUpdateUnavailable,
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyOpportunityIds.remove(opportunityId);
        });
      }
    }
  }
}

class _EarlyAccessHero extends StatelessWidget {
  final _EarlyAccessSummary summary;

  const _EarlyAccessHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            eyebrow: l10n.uiReviewOfferSubmissions,
            title: l10n.earlyAccessLabel,
            subtitle:
                'Approve or reject company requests for Premium early visibility.',
            trailing: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AdminPalette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AdminPalette.accent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminPill(
                label: '${summary.pending} ${l10n.adminEarlyAccessPendingTab}',
                color: AdminPalette.warning,
                icon: Icons.hourglass_top_rounded,
              ),
              AdminPill(
                label:
                    '${summary.approved} ${l10n.adminEarlyAccessApprovedTab}',
                color: AdminPalette.success,
                icon: Icons.check_circle_outline_rounded,
              ),
              AdminPill(
                label: '${summary.rejected} ${l10n.uiRejected}',
                color: AdminPalette.danger,
                icon: Icons.block_rounded,
              ),
              AdminPill(
                label: '${summary.total} ${l10n.adminEarlyAccessAllTab}',
                color: AdminPalette.primary,
                icon: Icons.dashboard_customize_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarlyAccessFilterBar extends StatelessWidget {
  final _EarlyAccessSummary summary;
  final _EarlyAccessQueueFilter selected;
  final ValueChanged<_EarlyAccessQueueFilter> onChanged;

  const _EarlyAccessFilterBar({
    required this.summary,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      _FilterDefinition(
        filter: _EarlyAccessQueueFilter.pending,
        label: l10n.adminEarlyAccessPendingTab,
        icon: Icons.hourglass_top_rounded,
        count: summary.pending,
      ),
      _FilterDefinition(
        filter: _EarlyAccessQueueFilter.approved,
        label: l10n.adminEarlyAccessApprovedTab,
        icon: Icons.verified_outlined,
        count: summary.approved,
      ),
      _FilterDefinition(
        filter: _EarlyAccessQueueFilter.rejected,
        label: l10n.uiRejected,
        icon: Icons.block_rounded,
        count: summary.rejected,
      ),
      _FilterDefinition(
        filter: _EarlyAccessQueueFilter.all,
        label: l10n.adminEarlyAccessAllTab,
        icon: Icons.dashboard_customize_outlined,
        count: summary.total,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((definition) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: AdminFilterChip(
              label: definition.label,
              icon: definition.icon,
              badgeCount: definition.count,
              selected: selected == definition.filter,
              onTap: () => onChanged(definition.filter),
              compact: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EarlyAccessCard extends StatelessWidget {
  final _EarlyAccessRecord record;
  final bool isBusy;
  final VoidCallback onOpenDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRemove;

  const _EarlyAccessCard({
    required this.record,
    required this.isBusy,
    required this.onOpenDetails,
    required this.onApprove,
    required this.onReject,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final opportunity = record.opportunity;
    final title = DisplayText.opportunityTitle(
      opportunity.title,
      fallback: l10n.uiUntitledOpportunity,
    );

    final company = opportunity.companyName.trim().isEmpty
        ? l10n.uiCompanyNameNotAdded
        : opportunity.companyName.trim();

    return Semantics(
      button: true,
      label:
          '$title, ${OpportunityType.label(opportunity.type, l10n)}, '
          '${_statusLabel(record, l10n)}. ${l10n.uiOpenDetails}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onOpenDetails,
          borderRadius: BorderRadius.circular(18),
          child: AdminSurface(
            radius: 18,
            padding: const EdgeInsets.all(14),
            border: Border.all(
              color: AdminPalette.border.withValues(alpha: 0.92),
            ),
            boxShadow: [
              BoxShadow(
                color: AdminPalette.primary.withValues(
                  alpha: AdminPalette.isDark ? 0.08 : 0.04,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OpportunityGlyph(opportunity: opportunity),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AdminPalette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$company | '
                            '${OpportunityType.label(opportunity.type, l10n)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AdminPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _EarlyAccessStatusBadge(record: record),
                    const SizedBox(width: 6),
                    _CardDetailsArrow(),
                  ],
                ),
                const SizedBox(height: 12),
                _SimpleRequestLine(record: record),
                if (opportunity.earlyAccessStatus == 'pending' ||
                    opportunity.earlyAccessStatus == 'approved') ...[
                  const SizedBox(height: 12),
                  _CardActions(
                    status: opportunity.earlyAccessStatus,
                    isBusy: isBusy,
                    onApprove: onApprove,
                    onReject: onReject,
                    onRemove: onRemove,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardDetailsArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AdminPalette.surfaceMuted.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminPalette.border.withValues(alpha: 0.72)),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AdminPalette.textMuted,
      ),
    );
  }
}

class _SimpleRequestLine extends StatelessWidget {
  final _EarlyAccessRecord record;

  const _SimpleRequestLine({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AdminPalette.surfaceMuted.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminPalette.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: AdminPalette.textMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Requested ${_formatDateTime(context, record.requestedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.product(
                fontSize: 11.4,
                fontWeight: FontWeight.w600,
                color: AdminPalette.textSecondary,
                height: 1.2,
              ),
            ),
          ),
          if (record.opportunity.applicationsCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${record.opportunity.applicationsCount} ${l10n.uiApplicationsSuffix}',
              style: AppTypography.product(
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
                color: AdminPalette.activity,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  final String status;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRemove;

  const _CardActions({
    required this.status,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[
      if (status == 'pending') ...[
        OutlinedButton.icon(
          onPressed: isBusy ? null : onReject,
          icon: Icon(
            Icons.close_rounded,
            size: 17,
            color: isBusy ? null : AdminPalette.danger,
          ),
          label: Text(l10n.earlyAccessRejectButton),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminPalette.danger,
            side: BorderSide(
              color: AdminPalette.danger.withValues(alpha: 0.38),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: isBusy ? null : onApprove,
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, size: 17),
          label: Text(l10n.earlyAccessApproveButton),
          style: FilledButton.styleFrom(
            backgroundColor: AdminPalette.success,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      if (status == 'approved')
        OutlinedButton.icon(
          onPressed: isBusy ? null : onRemove,
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.remove_circle_outline_rounded, size: 17),
          label: Text(l10n.adminEarlyAccessMakeNormalButton),
        ),
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _EarlyAccessStatusBadge extends StatelessWidget {
  final _EarlyAccessRecord record;

  const _EarlyAccessStatusBadge({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor(record);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(record), size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            _statusLabel(record, l10n),
            style: AppTypography.product(
              fontSize: 10.6,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityGlyph extends StatelessWidget {
  final OpportunityModel opportunity;

  const _OpportunityGlyph({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final color = OpportunityType.color(opportunity.type);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Icon(
        OpportunityType.icon(opportunity.type),
        color: color,
        size: 22,
      ),
    );
  }
}

class _EarlyAccessDetailsSheet extends StatelessWidget {
  final _EarlyAccessRecord record;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRemove;

  const _EarlyAccessDetailsSheet({
    required this.record,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final opportunity = record.opportunity;
    final typeColor = OpportunityType.color(opportunity.type);
    final typeLabel = OpportunityType.label(opportunity.type, l10n);
    final title = DisplayText.opportunityTitle(
      opportunity.title,
      fallback: l10n.uiUntitledOpportunity,
    );
    final companyName = opportunity.companyName.trim().isEmpty
        ? l10n.uiUnknownCompany
        : opportunity.companyName.trim();
    final description = DisplayText.capitalizeLeadingLabel(
      opportunity.description,
    ).trim();
    final requirements = _detailList(
      opportunity.requirementItems.isNotEmpty
          ? opportunity.requirementItems
          : <String>[opportunity.requirements],
    );
    final benefits = _detailList(opportunity.benefits);
    final tags = _detailList(opportunity.tags);
    final workMode =
        OpportunityMetadata.formatWorkMode(opportunity.workMode) ?? '';
    final employmentType =
        OpportunityMetadata.formatEmploymentType(opportunity.employmentType) ??
        '';
    final paidStatus =
        OpportunityMetadata.formatPaidLabel(opportunity.isPaid) ?? '';
    final compensation = _compensationLabel(opportunity);
    final createdAt = opportunity.createdAt?.toDate();
    final rejectedReason = DisplayText.capitalizeLeadingLabel(
      opportunity.earlyAccessRejectedReason ?? '',
    ).trim();
    final hasActions =
        opportunity.earlyAccessStatus == 'pending' ||
        opportunity.earlyAccessStatus == 'approved';

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.46,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: AdminPalette.background,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                _EarlyAccessDetailHero(
                  title: title,
                  subtitle: companyName,
                  typeLabel: typeLabel,
                  statusLabel: _statusLabel(record, l10n),
                  typeColor: typeColor,
                  statusIcon: _statusIcon(record),
                  icon: OpportunityType.icon(opportunity.type),
                  isFeatured: opportunity.isFeatured,
                  isHidden: opportunity.isHidden,
                ),
                if (hasActions) ...[
                  const SizedBox(height: 12),
                  AdminSurface(
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EarlyAccessSectionTitle(
                          title: 'Review action',
                          icon: Icons.fact_check_outlined,
                          color: AdminPalette.primary,
                        ),
                        const SizedBox(height: 12),
                        _CardActions(
                          status: opportunity.earlyAccessStatus,
                          isBusy: isBusy,
                          onApprove: onApprove,
                          onReject: onReject,
                          onRemove: onRemove,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _EarlyAccessDetailGrid(
                  items: [
                    _EarlyAccessDetailItem(
                      label: l10n.uiLocation,
                      value: _detailValue(
                        opportunity.location,
                        l10n.uiLocationNotSpecified,
                      ),
                      icon: Icons.location_on_outlined,
                      color: AdminPalette.info,
                    ),
                    _EarlyAccessDetailItem(
                      label: l10n.uiDeadline,
                      value: _deadlineLabel(opportunity, l10n),
                      icon: Icons.event_outlined,
                      color: AdminPalette.activity,
                    ),
                    if (compensation.isNotEmpty)
                      _EarlyAccessDetailItem(
                        label: l10n.uiCompensation,
                        value: compensation,
                        icon: Icons.payments_outlined,
                        color: AdminPalette.success,
                      ),
                    if (workMode.isNotEmpty)
                      _EarlyAccessDetailItem(
                        label: l10n.uiWorkMode,
                        value: workMode,
                        icon: Icons.lan_outlined,
                        color: typeColor,
                      ),
                    if (employmentType.isNotEmpty)
                      _EarlyAccessDetailItem(
                        label: l10n.uiEmploymentType,
                        value: employmentType,
                        icon: Icons.badge_outlined,
                        color: AdminPalette.primary,
                      ),
                    if (paidStatus.isNotEmpty)
                      _EarlyAccessDetailItem(
                        label: l10n.uiPaidStatus,
                        value: paidStatus,
                        icon: Icons.account_balance_wallet_outlined,
                        color: AdminPalette.success,
                      ),
                    if ((opportunity.duration ?? '').trim().isNotEmpty)
                      _EarlyAccessDetailItem(
                        label: l10n.uiDuration,
                        value: opportunity.duration!.trim(),
                        icon: Icons.schedule_outlined,
                        color: AdminPalette.textMuted,
                      ),
                    if (createdAt != null)
                      _EarlyAccessDetailItem(
                        label: l10n.uiPosted,
                        value: _formatDateTime(context, createdAt),
                        icon: Icons.update_outlined,
                        color: AdminPalette.secondary,
                      ),
                    _EarlyAccessDetailItem(
                      label: 'Requested',
                      value: _formatDateTime(context, record.requestedAt),
                      icon: Icons.schedule_rounded,
                      color: AdminPalette.warning,
                    ),
                    if (record.reviewedAt != null)
                      _EarlyAccessDetailItem(
                        label: l10n.uiReviewed,
                        value: _formatDateTime(context, record.reviewedAt),
                        icon: Icons.verified_outlined,
                        color: _statusColor(record),
                      ),
                    if (opportunity.publicVisibleAt != null)
                      _EarlyAccessDetailItem(
                        label: 'Public release',
                        value: _formatDateTime(
                          context,
                          opportunity.publicVisibleAt,
                        ),
                        icon: Icons.public_outlined,
                        color: AdminPalette.accent,
                      ),
                    if (opportunity.earlyAccessDurationHours != null)
                      _EarlyAccessDetailItem(
                        label: l10n.earlyAccessDelayLabel,
                        value: l10n.earlyAccessTimeHours(
                          opportunity.earlyAccessDurationHours!,
                        ),
                        icon: Icons.lock_clock_rounded,
                        color: AdminPalette.accent,
                      ),
                    _EarlyAccessDetailItem(
                      label: l10n.uiApplications,
                      value: '${opportunity.applicationsCount}',
                      icon: Icons.assignment_turned_in_outlined,
                      color: AdminPalette.activity,
                    ),
                    _EarlyAccessDetailItem(
                      label: 'Premium apps',
                      value: '${opportunity.premiumApplicationsCount}',
                      icon: Icons.workspace_premium_outlined,
                      color: AdminPalette.accent,
                    ),
                    _EarlyAccessDetailItem(
                      label: 'Free apps',
                      value: '${opportunity.freeApplicationsCount}',
                      icon: Icons.person_outline_rounded,
                      color: AdminPalette.secondary,
                    ),
                    _EarlyAccessDetailItem(
                      label: 'Views',
                      value: '${opportunity.viewsCount}',
                      icon: Icons.visibility_outlined,
                      color: AdminPalette.info,
                    ),
                    _EarlyAccessDetailItem(
                      label: 'Locked clicks',
                      value: '${opportunity.lockedApplyClicks}',
                      icon: Icons.lock_outline_rounded,
                      color: AdminPalette.warning,
                    ),
                    _EarlyAccessDetailItem(
                      label: 'Upgrade views',
                      value: '${opportunity.upgradeModalViews}',
                      icon: Icons.open_in_new_rounded,
                      color: AdminPalette.primary,
                    ),
                    _EarlyAccessDetailItem(
                      label: 'Upgrade clicks',
                      value: '${opportunity.upgradeClicks}',
                      icon: Icons.touch_app_outlined,
                      color: AdminPalette.success,
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EarlyAccessTextSection(
                    title: l10n.uiDescription,
                    text: description,
                    icon: Icons.description_outlined,
                    color: typeColor,
                  ),
                ],
                if (rejectedReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EarlyAccessTextSection(
                    title: l10n.earlyAccessRejectReasonHint,
                    text: rejectedReason,
                    icon: Icons.block_outlined,
                    color: AdminPalette.danger,
                  ),
                ],
                if (requirements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EarlyAccessListSection(
                    title: l10n.requirementsLabel,
                    items: requirements,
                    icon: Icons.checklist_rounded,
                    color: typeColor,
                  ),
                ],
                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EarlyAccessListSection(
                    title: l10n.uiBenefits,
                    items: benefits,
                    icon: Icons.workspace_premium_outlined,
                    color: AdminPalette.success,
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EarlyAccessListSection(
                    title: l10n.uiTags,
                    items: tags,
                    icon: Icons.sell_outlined,
                    color: AdminPalette.secondary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EarlyAccessDetailHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String typeLabel;
  final String statusLabel;
  final Color typeColor;
  final IconData statusIcon;
  final IconData icon;
  final bool isFeatured;
  final bool isHidden;

  const _EarlyAccessDetailHero({
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.statusLabel,
    required this.typeColor,
    required this.statusIcon,
    required this.icon,
    required this.isFeatured,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdminSurface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      gradient: AdminPalette.heroGradient(typeColor),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTypography.product(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.product(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminPill(label: typeLabel, color: Colors.white, icon: icon),
              AdminPill(
                label: statusLabel,
                color: Colors.white,
                icon: statusIcon,
              ),
              if (isFeatured)
                AdminPill(
                  label: l10n.uiFeatured,
                  color: Colors.white,
                  icon: Icons.workspace_premium_outlined,
                ),
              if (isHidden)
                AdminPill(
                  label: l10n.uiHiddenLabel,
                  color: Colors.white,
                  icon: Icons.visibility_off_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarlyAccessDetailItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _EarlyAccessDetailItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _EarlyAccessDetailGrid extends StatelessWidget {
  final List<_EarlyAccessDetailItem> items;

  const _EarlyAccessDetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 520;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: useTwoColumns ? 2 : 1,
            mainAxisExtent: 82,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return AdminSurface(
              radius: 18,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, color: item.color, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.product(
                            fontSize: 11.2,
                            color: AdminPalette.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.product(
                            fontSize: 12.4,
                            color: AdminPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EarlyAccessTextSection extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color color;

  const _EarlyAccessTextSection({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EarlyAccessSectionTitle(title: title, icon: icon, color: color),
          const SizedBox(height: 10),
          Text(
            text,
            style: AppTypography.product(
              fontSize: 12.8,
              color: AdminPalette.textSecondary,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarlyAccessListSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _EarlyAccessListSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EarlyAccessSectionTitle(title: title, icon: icon, color: color),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.product(
                        fontSize: 12.8,
                        color: AdminPalette.textSecondary,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarlyAccessSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _EarlyAccessSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AdminPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: AdminPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _EarlyAccessEmptyState extends StatelessWidget {
  final bool hasAnyRecords;
  final _EarlyAccessQueueFilter filter;

  const _EarlyAccessEmptyState({
    required this.hasAnyRecords,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = hasAnyRecords
        ? l10n.uiNoResultsInThisView
        : 'No early access requests yet';
    final message = hasAnyRecords
        ? 'Try another status or search term to bring requests back into view.'
        : 'Company requests for premium early visibility will appear here as soon as they are submitted.';

    return AdminEmptyState(
      icon: filter == _EarlyAccessQueueFilter.pending
          ? Icons.hourglass_empty_rounded
          : Icons.workspace_premium_outlined,
      title: title,
      message: message,
    );
  }
}

class _DialogHeading extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _DialogHeading({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.product(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.product(
                  fontSize: 12.3,
                  color: AdminPalette.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DelayChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DelayChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AdminPalette.primary : AdminPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AdminPalette.border.withValues(alpha: 0.9),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.product(
            fontSize: 11.3,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AdminPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EarlyAccessRecord {
  final OpportunityModel opportunity;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;

  const _EarlyAccessRecord({
    required this.opportunity,
    required this.requestedAt,
    required this.reviewedAt,
  });
}

class _EarlyAccessSummary {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _EarlyAccessSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory _EarlyAccessSummary.from(List<_EarlyAccessRecord> records) {
    var pending = 0;
    var approved = 0;
    var rejected = 0;

    for (final record in records) {
      switch (record.opportunity.earlyAccessStatus) {
        case 'pending':
          pending++;
        case 'approved':
          approved++;
        case 'rejected':
          rejected++;
      }
    }

    return _EarlyAccessSummary(
      total: records.length,
      pending: pending,
      approved: approved,
      rejected: rejected,
    );
  }
}

class _FilterDefinition {
  final _EarlyAccessQueueFilter filter;
  final String label;
  final IconData icon;
  final int count;

  const _FilterDefinition({
    required this.filter,
    required this.label,
    required this.icon,
    required this.count,
  });
}

String _detailValue(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty
      ? fallback
      : DisplayText.capitalizeLeadingLabel(trimmed);
}

List<String> _detailList(List<String> values) {
  return values
      .map((item) => DisplayText.capitalizeLeadingLabel(item).trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _deadlineLabel(OpportunityModel opportunity, AppLocalizations l10n) {
  final deadline =
      opportunity.applicationDeadline ??
      OpportunityMetadata.parseDateTimeLike(opportunity.deadlineLabel);
  if (deadline != null) {
    return OpportunityMetadata.formatDateLabel(deadline);
  }

  return _detailValue(opportunity.deadlineLabel, l10n.uiNotSpecified);
}

String _compensationLabel(OpportunityModel opportunity) {
  final label = OpportunityType.isSponsoring(opportunity.type)
      ? opportunity.fundingLabel(preferFundingNote: true)
      : OpportunityMetadata.buildCompensationLabel(
          salaryMin: opportunity.salaryMin,
          salaryMax: opportunity.salaryMax,
          salaryCurrency: opportunity.salaryCurrency,
          salaryPeriod: opportunity.salaryPeriod,
          compensationText: opportunity.compensationText,
          isPaid: opportunity.isPaid,
          preferCompensationText: true,
        );

  return (label ?? '').trim();
}

String _statusLabel(_EarlyAccessRecord record, AppLocalizations l10n) {
  switch (record.opportunity.earlyAccessStatus) {
    case 'pending':
      return l10n.uiPending;
    case 'approved':
      return l10n.uiApproved;
    case 'rejected':
      return l10n.uiRejected;
    default:
      return l10n.earlyAccessNoneStatus;
  }
}

Color _statusColor(_EarlyAccessRecord record) {
  switch (record.opportunity.earlyAccessStatus) {
    case 'pending':
      return AdminPalette.warning;
    case 'approved':
      return AdminPalette.success;
    case 'rejected':
      return AdminPalette.danger;
    default:
      return AdminPalette.textMuted;
  }
}

IconData _statusIcon(_EarlyAccessRecord record) {
  switch (record.opportunity.earlyAccessStatus) {
    case 'pending':
      return Icons.hourglass_top_rounded;
    case 'approved':
      return Icons.check_circle_outline_rounded;
    case 'rejected':
      return Icons.block_rounded;
    default:
      return Icons.remove_circle_outline_rounded;
  }
}

String _formatDateTime(BuildContext context, DateTime? value) {
  final l10n = AppLocalizations.of(context)!;
  if (value == null) {
    return l10n.uiUnknownTime;
  }

  return DateFormat.yMMMd(l10n.localeName).add_Hm().format(value);
}

DateTime? _dateTimeFromValue(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return OpportunityMetadata.parseDateTimeLike(value);
}
