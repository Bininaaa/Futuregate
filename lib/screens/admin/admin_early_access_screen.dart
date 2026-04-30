import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/opportunity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/early_access_label.dart';
import '../../widgets/premium_badge.dart';

class AdminEarlyAccessScreen extends StatefulWidget {
  const AdminEarlyAccessScreen({super.key});

  @override
  State<AdminEarlyAccessScreen> createState() => _AdminEarlyAccessScreenState();
}

class _AdminEarlyAccessScreenState extends State<AdminEarlyAccessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Row(
          children: [
            Text(
              l10n.adminEarlyAccessTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const PremiumBadge(size: PremiumBadgeSize.small),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: colors.primary,
          tabs: [
            Tab(text: l10n.adminEarlyAccessPendingTab),
            Tab(text: l10n.adminEarlyAccessApprovedTab),
            Tab(text: l10n.adminEarlyAccessAllTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _EarlyAccessList(filterStatus: 'pending'),
          _EarlyAccessList(filterStatus: 'approved'),
          _EarlyAccessList(filterStatus: 'all'),
        ],
      ),
    );
  }
}

class _EarlyAccessList extends StatelessWidget {
  final String filterStatus;
  const _EarlyAccessList({required this.filterStatus});

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('opportunities')
        .where('earlyAccessRequested', isEqualTo: true);

    if (filterStatus != 'all') {
      query = query.where('earlyAccessStatus', isEqualTo: filterStatus);
    }

    return query.snapshots();
  }

  int _requestedEarlyAccessMillis(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final value = doc.data()['requestedEarlyAccessAt'];
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildQuery(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(
              snap.data?.docs ?? const [],
            )..sort(
              (a, b) => _requestedEarlyAccessMillis(
                b,
              ).compareTo(_requestedEarlyAccessMillis(a)),
            );
        if (docs.isEmpty) {
          return _EmptyState(filterStatus: filterStatus);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = Map<String, dynamic>.from(docs[index].data());
            data['id'] = docs[index].id;
            final opp = OpportunityModel.fromMap(data);
            return _EarlyAccessCard(opportunity: opp);
          },
        );
      },
    );
  }
}

class _EarlyAccessCard extends StatelessWidget {
  final OpportunityModel opportunity;
  const _EarlyAccessCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: colors.softShadow(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              EarlyAccessLabel(status: opportunity.earlyAccessStatus),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.business_rounded, size: 12, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                opportunity.companyName,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.work_outline_rounded,
                size: 12,
                color: colors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                opportunity.type,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
          if (opportunity.earlyAccessStatus == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, opportunity),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colors.danger,
                    ),
                    label: Text(
                      l10n.earlyAccessRejectButton,
                      style: TextStyle(
                        color: colors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colors.danger.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showApproveDialog(context, opportunity),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: Text(
                      l10n.earlyAccessApproveButton,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.success,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (opportunity.earlyAccessStatus == 'approved') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _makeNormal(context, opportunity.id),
                icon: Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 14,
                  color: colors.textMuted,
                ),
                label: Text(
                  l10n.adminEarlyAccessMakeNormalButton,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, OpportunityModel opp) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final delayCtrl = TextEditingController(text: '48');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          l10n.earlyAccessApproveButton,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(opp.title, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: delayCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.earlyAccessDelayLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              final hours = int.tryParse(delayCtrl.text) ?? 48;
              Navigator.of(ctx).pop();
              _approve(context, opp.id, hours);
            },
            style: FilledButton.styleFrom(backgroundColor: colors.success),
            child: Text(l10n.earlyAccessApproveButton),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, OpportunityModel opp) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          l10n.earlyAccessRejectButton,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(opp.title, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.earlyAccessRejectReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _reject(context, opp.id, reasonCtrl.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            child: Text(l10n.earlyAccessRejectButton),
          ),
        ],
      ),
    );
  }

  void _approve(BuildContext context, String opportunityId, int delayHours) {
    final adminUid = context.read<AuthProvider>().userModel?.uid ?? '';
    context
        .read<PremiumProvider>()
        .approveEarlyAccess(
          opportunityId: opportunityId,
          adminUid: adminUid,
          delayHours: delayHours,
        )
        .then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Early access approved.')),
            );
          }
        });
  }

  void _reject(BuildContext context, String opportunityId, String reason) {
    final adminUid = context.read<AuthProvider>().userModel?.uid ?? '';
    context
        .read<PremiumProvider>()
        .rejectEarlyAccess(
          opportunityId: opportunityId,
          adminUid: adminUid,
          reason: reason,
        )
        .then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Early access rejected.')),
            );
          }
        });
  }

  void _makeNormal(BuildContext context, String opportunityId) {
    context.read<PremiumProvider>().makePostNormal(opportunityId).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post set to normal.')));
      }
    });
  }
}

class _EmptyState extends StatelessWidget {
  final String filterStatus;
  const _EmptyState({required this.filterStatus});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No $filterStatus early access requests.',
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
