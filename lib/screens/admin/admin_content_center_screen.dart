import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/admin_application_item_model.dart';
import '../../models/cv_model.dart';
import '../../models/project_idea_model.dart';
import '../../models/training_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/company_service.dart';
import '../../services/document_access_service.dart';
import '../../widgets/profile_avatar.dart';

class AdminContentCenterScreen extends StatefulWidget {
  static const int projectIdeasTab = 0;
  static const int applicationsTab = 1;
  static const int opportunitiesTab = 2;
  static const int scholarshipsTab = 3;
  static const int trainingsTab = 4;

  final int initialTab;
  final String initialTargetId;
  final bool embedded;

  const AdminContentCenterScreen({
    super.key,
    this.initialTab = projectIdeasTab,
    this.initialTargetId = '',
    this.embedded = false,
  });

  @override
  State<AdminContentCenterScreen> createState() =>
      _AdminContentCenterScreenState();
}

class _AdminContentCenterScreenState extends State<AdminContentCenterScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF2D1B4E);
  static const Color _accentColor = Color(0xFFFF8C00);

  final CompanyService _companyService = CompanyService();
  final DocumentAccessService _documentAccessService = DocumentAccessService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  bool _showPendingOnly = true;
  bool _openedInitialTarget = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadModerationData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (!provider.moderationLoading &&
        !_openedInitialTarget &&
        widget.initialTargetId.trim().isNotEmpty) {
      _openedInitialTarget = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openInitialTarget(provider, widget.initialTargetId.trim());
      });
    }

    final content = Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: _primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
            tabs: [
              _buildTab(
                icon: Icons.lightbulb,
                label: 'Ideas',
                badgeCount: provider.allProjectIdeas
                    .where((idea) => idea.status == 'pending')
                    .length,
              ),
              _buildTab(icon: Icons.assignment_outlined, label: 'Applications'),
              _buildTab(icon: Icons.work_outline, label: 'Opportunities'),
              _buildTab(icon: Icons.card_giftcard, label: 'Scholarships'),
              _buildTab(
                icon: Icons.cast_for_education_outlined,
                label: 'Trainings',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _searchHintForCurrentTab(),
                prefixIcon: const Icon(Icons.search, color: _accentColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
        ),
        Expanded(
          child: provider.moderationLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _accentColor),
                )
              : provider.moderationError != null &&
                    provider.allProjectIdeas.isEmpty &&
                    provider.allApplications.isEmpty &&
                    provider.allOpportunities.isEmpty &&
                    provider.allScholarships.isEmpty &&
                    provider.allTrainings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load admin content',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: provider.loadModerationData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProjectIdeasTab(provider),
                    _buildApplicationsTab(provider),
                    _buildOpportunitiesTab(provider),
                    _buildScholarshipsTab(provider),
                    _buildTrainingsTab(provider),
                  ],
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FB),
      appBar: AppBar(
        title: const Text('Admin Content Center'),
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
      ),
      body: SafeArea(child: content),
    );
  }

  Tab _buildTab({
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
          if (badgeCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectIdeasTab(AdminProvider provider) {
    final allIdeas = provider.allProjectIdeas
        .where(_matchesIdeaSearch)
        .toList();
    final ideas = _showPendingOnly
        ? allIdeas.where((idea) => idea.status == 'pending').toList()
        : allIdeas;

    if (provider.allProjectIdeas.isEmpty) {
      return _buildEmptyState(Icons.lightbulb_outline, 'No project ideas yet');
    }

    if (ideas.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        _showPendingOnly
            ? 'No pending ideas match your search'
            : 'No ideas match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ideas.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showPendingOnly
                        ? 'Pending Ideas (${ideas.length})'
                        : 'All Ideas (${ideas.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showPendingOnly = !_showPendingOnly;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _showPendingOnly ? 'Show All' : 'Pending Only',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final idea = ideas[index - 1];
          final isIdeaBusy = provider.busyIdeaIds.contains(idea.id);
          final statusColor = _statusColor(idea.status);
          final submitterLabel = idea.submittedByName.trim().isNotEmpty
              ? idea.submittedByName
              : idea.submittedBy;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: idea.id == widget.initialTargetId
                  ? Border.all(color: _accentColor, width: 1.4)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showProjectIdeaDetails(idea),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            idea.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        _statusBadge(idea.status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      idea.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildChip(idea.domain, Colors.blue),
                        _buildChip(idea.level, Colors.purple),
                        if (idea.tools.isNotEmpty)
                          _buildChip(idea.tools, Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Submitted by: $submitterLabel',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (idea.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatTimestamp(idea.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    if (idea.status == 'pending') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isIdeaBusy
                                  ? null
                                  : () async {
                                      final error = await provider
                                          .updateProjectIdeaStatus(
                                            idea.id,
                                            'approved',
                                          );
                                      if (error != null && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(error)),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(
                                isIdeaBusy ? 'Working...' : 'Approve',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isIdeaBusy
                                  ? null
                                  : () async {
                                      final error = await provider
                                          .updateProjectIdeaStatus(
                                            idea.id,
                                            'rejected',
                                          );
                                      if (error != null && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(error)),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(isIdeaBusy ? 'Working...' : 'Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationsTab(AdminProvider provider) {
    final applications = provider.allApplications
        .where(
          (application) => application.matchesQuery(_searchController.text),
        )
        .toList();

    if (provider.allApplications.isEmpty) {
      return _buildEmptyState(Icons.assignment_outlined, 'No applications yet');
    }

    if (applications.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        'No applications match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final item = applications[index];
          final statusColor = _statusColor(item.status);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: item.id == widget.initialTargetId
                  ? Border.all(color: _accentColor, width: 1.4)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: () => _showApplicationDetails(item),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: ProfileAvatar(
                radius: 20,
                userId: item.application.studentId,
                fallbackName: item.studentName,
                role: 'student',
              ),
              title: Text(
                item.studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _primaryColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    item.opportunityTitle.isNotEmpty
                        ? item.opportunityTitle
                        : 'Unknown opportunity',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.companyName.isNotEmpty
                        ? item.companyName
                        : 'Unknown company',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusBadge(item.status, statusColor),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(item.appliedAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunitiesTab(AdminProvider provider) {
    final opportunities = provider.allOpportunities
        .where(_matchesOpportunitySearch)
        .toList();

    if (provider.allOpportunities.isEmpty) {
      return _buildEmptyState(Icons.work_outline, 'No opportunities yet');
    }

    if (opportunities.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        'No opportunities match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: opportunities.length,
        itemBuilder: (context, index) {
          final opportunity = opportunities[index];
          return _buildMapListTile(
            id: opportunity['id'].toString(),
            icon: Icons.work,
            iconColor: _accentColor,
            title: (opportunity['title'] ?? 'No title').toString(),
            subtitle: (opportunity['companyName'] ?? 'Unknown company')
                .toString(),
            badges: [
              _BadgeData(
                (opportunity['type'] ?? '').toString(),
                (opportunity['type'] ?? '') == 'job'
                    ? Colors.blue
                    : Colors.green,
              ),
              _BadgeData(
                (opportunity['status'] ?? '').toString(),
                (opportunity['status'] ?? '') == 'open'
                    ? Colors.green
                    : Colors.grey,
              ),
            ],
            onTap: () => _showOpportunityDetails(opportunity),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteDialog(
                'Delete Opportunity',
                'Are you sure you want to delete "${opportunity['title']}"?',
                () async {
                  final error = await provider.deleteOpportunity(
                    opportunity['id'].toString(),
                  );
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScholarshipsTab(AdminProvider provider) {
    final scholarships = provider.allScholarships
        .where(_matchesScholarshipSearch)
        .toList();

    if (provider.allScholarships.isEmpty) {
      return _buildEmptyState(Icons.card_giftcard, 'No scholarships yet');
    }

    if (scholarships.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        'No scholarships match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: scholarships.length,
        itemBuilder: (context, index) {
          final scholarship = scholarships[index];
          return _buildMapListTile(
            id: scholarship['id'].toString(),
            icon: Icons.card_giftcard,
            iconColor: Colors.pink,
            title: (scholarship['title'] ?? 'No title').toString(),
            subtitle: (scholarship['provider'] ?? 'Unknown provider')
                .toString(),
            badges: [
              if (scholarship['amount'] != null)
                _BadgeData('${scholarship['amount']} DA', Colors.green),
              if ((scholarship['deadline'] ?? '').toString().isNotEmpty)
                _BadgeData('Due: ${scholarship['deadline']}', Colors.orange),
            ],
            onTap: () => _showScholarshipDetails(scholarship),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteDialog(
                'Delete Scholarship',
                'Are you sure you want to delete "${scholarship['title']}"?',
                () async {
                  final error = await provider.deleteScholarship(
                    scholarship['id'].toString(),
                  );
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrainingsTab(AdminProvider provider) {
    final trainings = provider.allTrainings
        .where(_matchesTrainingSearch)
        .toList();

    if (provider.allTrainings.isEmpty) {
      return _buildEmptyState(
        Icons.cast_for_education_outlined,
        'No trainings yet',
      );
    }

    if (trainings.isEmpty) {
      return _buildEmptyState(
        Icons.search_off_outlined,
        'No trainings match your search',
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: provider.loadModerationData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: trainings.length,
        itemBuilder: (context, index) {
          final training = trainings[index];
          return _buildTrainingListTile(training);
        },
      ),
    );
  }

  String _searchHintForCurrentTab() {
    switch (_tabController.index) {
      case AdminContentCenterScreen.projectIdeasTab:
        return 'Search ideas by title, domain, submitter, or status...';
      case AdminContentCenterScreen.applicationsTab:
        return 'Search applications by student, opportunity, company, or status...';
      case AdminContentCenterScreen.opportunitiesTab:
        return 'Search opportunities by title, company, location, or status...';
      case AdminContentCenterScreen.scholarshipsTab:
        return 'Search scholarships by title, provider, or deadline...';
      case AdminContentCenterScreen.trainingsTab:
        return 'Search trainings by title, provider, domain, or level...';
      default:
        return 'Search...';
    }
  }

  bool _matchesIdeaSearch(ProjectIdeaModel idea) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return idea.title.toLowerCase().contains(query) ||
        idea.description.toLowerCase().contains(query) ||
        idea.domain.toLowerCase().contains(query) ||
        idea.level.toLowerCase().contains(query) ||
        idea.tools.toLowerCase().contains(query) ||
        idea.status.toLowerCase().contains(query) ||
        idea.submittedBy.toLowerCase().contains(query) ||
        idea.submittedByName.toLowerCase().contains(query);
  }

  bool _matchesOpportunitySearch(Map<String, dynamic> opportunity) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return (opportunity['title'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (opportunity['companyName'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (opportunity['location'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (opportunity['type'] ?? '').toString().toLowerCase().contains(query) ||
        (opportunity['status'] ?? '').toString().toLowerCase().contains(query);
  }

  bool _matchesScholarshipSearch(Map<String, dynamic> scholarship) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return (scholarship['title'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (scholarship['provider'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (scholarship['eligibility'] ?? '').toString().toLowerCase().contains(
          query,
        ) ||
        (scholarship['deadline'] ?? '').toString().toLowerCase().contains(
          query,
        );
  }

  bool _matchesTrainingSearch(TrainingModel training) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return training.title.toLowerCase().contains(query) ||
        training.provider.toLowerCase().contains(query) ||
        training.domain.toLowerCase().contains(query) ||
        training.level.toLowerCase().contains(query) ||
        training.source.toLowerCase().contains(query) ||
        training.type.toLowerCase().contains(query);
  }

  void _openInitialTarget(AdminProvider provider, String targetId) {
    switch (widget.initialTab) {
      case AdminContentCenterScreen.projectIdeasTab:
        final matches = provider.allProjectIdeas
            .where((item) => item.id == targetId)
            .toList();
        final idea = matches.isEmpty ? null : matches.first;
        if (idea != null) {
          _showProjectIdeaDetails(idea);
        }
        break;
      case AdminContentCenterScreen.applicationsTab:
        final matches = provider.allApplications
            .where((item) => item.id == targetId)
            .toList();
        final application = matches.isEmpty ? null : matches.first;
        if (application != null) {
          _showApplicationDetails(application);
        }
        break;
      case AdminContentCenterScreen.opportunitiesTab:
        final matches = provider.allOpportunities
            .where((item) => item['id'] == targetId)
            .toList();
        final opportunity = matches.isEmpty ? null : matches.first;
        if (opportunity != null) {
          _showOpportunityDetails(opportunity);
        }
        break;
      case AdminContentCenterScreen.scholarshipsTab:
        final matches = provider.allScholarships
            .where((item) => item['id'] == targetId)
            .toList();
        final scholarship = matches.isEmpty ? null : matches.first;
        if (scholarship != null) {
          _showScholarshipDetails(scholarship);
        }
        break;
      case AdminContentCenterScreen.trainingsTab:
        final matches = provider.allTrainings
            .where((item) => item.id == targetId)
            .toList();
        final training = matches.isEmpty ? null : matches.first;
        if (training != null) {
          _showTrainingDetails(training);
        }
        break;
    }
  }

  Widget _buildMapListTile({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<_BadgeData> badges,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: id == widget.initialTargetId
            ? Border.all(color: _accentColor, width: 1.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: _primaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: badges
                  .map((badge) => _statusBadge(badge.label, badge.color))
                  .toList(),
            ),
          ],
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildTrainingListTile(TrainingModel training) {
    return _buildMapListTile(
      id: training.id,
      icon: Icons.cast_for_education_outlined,
      iconColor: Colors.cyan,
      title: training.title,
      subtitle: training.provider.isNotEmpty
          ? training.provider
          : 'Unknown provider',
      badges: [
        if (training.domain.isNotEmpty)
          _BadgeData(training.domain, Colors.cyan),
        if (training.level.isNotEmpty)
          _BadgeData(training.level, Colors.indigo),
        _BadgeData(training.type, Colors.teal),
        if (training.isFeatured) _BadgeData('featured', _accentColor),
      ],
      onTap: () => _showTrainingDetails(training),
    );
  }

  void _showProjectIdeaDetails(ProjectIdeaModel idea) {
    final submitterLabel = idea.submittedByName.trim().isNotEmpty
        ? idea.submittedByName
        : idea.submittedBy;

    _showContentDetailsSheet(
      title: idea.title,
      subtitle: 'Submitted by $submitterLabel',
      description: idea.description,
      detailLines: [
        _SheetDetailLine('Domain', idea.domain),
        _SheetDetailLine('Level', idea.level),
        _SheetDetailLine('Tools', idea.tools),
        _SheetDetailLine('Status', idea.status),
        _SheetDetailLine('Submitted', _formatTimestamp(idea.createdAt)),
      ],
    );
  }

  void _showApplicationDetails(AdminApplicationItemModel item) {
    _showContentDetailsSheet(
      title: item.studentName,
      subtitle: item.companyName.isNotEmpty ? item.companyName : 'Application',
      description: item.opportunityTitle.isNotEmpty
          ? 'Applied to ${item.opportunityTitle}.'
          : 'Application details',
      detailLines: [
        _SheetDetailLine('Opportunity', item.opportunityTitle),
        _SheetDetailLine('Company', item.companyName),
        _SheetDetailLine('Status', item.status),
        _SheetDetailLine('Applied', _formatTimestamp(item.appliedAt)),
      ],
      actionLabel: 'View CV',
      onAction: () {
        Navigator.pop(context);
        _showApplicationCv(item.application.id);
      },
    );
  }

  Future<void> _showApplicationCv(String applicationId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<CvModel?>(
          future: _companyService.getApplicationCv(applicationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _documentErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final cv = snapshot.data;
            if (cv == null) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: Text('No CV available for this application'),
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.92,
              minChildSize: 0.3,
              expand: false,
              builder: (_, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      cv.fullName.isNotEmpty ? cv.fullName : 'Applicant',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${cv.email} • ${cv.phone}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    _buildApplicationDocumentCard(
                      title: 'Primary CV PDF',
                      subtitle: cv.hasUploadedCv
                          ? 'File: ${cv.uploadedCvDisplayName}\nUploaded: ${_formatDocumentDate(cv.uploadedCvUploadedAt)}'
                          : 'No CV uploaded',
                      accentColor: _accentColor,
                      warningText: cv.hasUploadedCv && !cv.isUploadedCvPdf
                          ? 'This uploaded file is not a valid PDF. Ask the user to replace it with a PDF version.'
                          : null,
                      onView: cv.hasUploadedCv && cv.isUploadedCvPdf
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'primary',
                              requirePdf: true,
                            )
                          : null,
                      onDownload: cv.hasUploadedCv
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'primary',
                              download: true,
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildApplicationDocumentCard(
                      title: 'Built CV',
                      subtitle: cv.hasExportedPdf
                          ? 'Built CV PDF is ready for review.'
                          : cv.hasBuilderContent
                          ? 'Built CV information is available, but no PDF has been exported yet.'
                          : 'No built CV information available.',
                      accentColor: _primaryColor,
                      onView: cv.hasExportedPdf
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'built',
                              requirePdf: true,
                            )
                          : null,
                      onDownload: cv.hasExportedPdf
                          ? () => _openApplicationDocument(
                              applicationId,
                              variant: 'built',
                              download: true,
                            )
                          : null,
                    ),
                    if (cv.summary.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildCvSection('Summary', [cv.summary]),
                    ],
                    if (cv.education.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildCvSection(
                        'Education',
                        cv.education
                            .map(
                              (item) =>
                                  '${item['degree'] ?? ''} - ${item['institution'] ?? ''} (${item['year'] ?? ''})',
                            )
                            .toList(),
                      ),
                    ],
                    if (cv.experience.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildCvSection(
                        'Experience',
                        cv.experience
                            .map(
                              (item) =>
                                  '${item['position'] ?? item['title'] ?? ''} at ${item['company'] ?? ''} (${item['duration'] ?? ''})',
                            )
                            .toList(),
                      ),
                    ],
                    if (cv.skills.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildTagSection('Skills', cv.skills, _accentColor),
                    ],
                    if (cv.languages.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildTagSection(
                        'Languages',
                        cv.languages,
                        _primaryColor,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openApplicationDocument(
    String applicationId, {
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService.getApplicationCvDocument(
        applicationId: applicationId,
        variant: variant,
      );

      if (requirePdf && !document.isPdf) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('This document is not a valid PDF file.'),
          ),
        );
        return;
      }

      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );
      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  Widget _buildApplicationDocumentCard({
    required String title,
    required String subtitle,
    required Color accentColor,
    VoidCallback? onView,
    VoidCallback? onDownload,
    String? warningText,
  }) {
    final hasActions = onView != null || onDownload != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 10),
            Text(
              warningText,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onView != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View CV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (onView != null && onDownload != null)
                  const SizedBox(width: 10),
                if (onDownload != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download CV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(
                          color: accentColor.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDocumentDate(Timestamp? value) {
    if (value == null) {
      return 'Not available';
    }

    return DateFormat('MMM d, yyyy').format(value.toDate());
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }

    return 'Could not open the document right now.';
  }

  void _showOpportunityDetails(Map<String, dynamic> opportunity) {
    _showContentDetailsSheet(
      title: (opportunity['title'] ?? 'Opportunity').toString(),
      subtitle: (opportunity['companyName'] ?? 'Unknown company').toString(),
      description: (opportunity['description'] ?? '').toString(),
      detailLines: [
        _SheetDetailLine('Type', (opportunity['type'] ?? '').toString()),
        _SheetDetailLine('Status', (opportunity['status'] ?? '').toString()),
        _SheetDetailLine(
          'Location',
          (opportunity['location'] ?? '').toString(),
        ),
        _SheetDetailLine(
          'Deadline',
          (opportunity['deadline'] ?? '').toString(),
        ),
        _SheetDetailLine(
          'Requirements',
          (opportunity['requirements'] ?? '').toString(),
        ),
      ],
    );
  }

  void _showScholarshipDetails(Map<String, dynamic> scholarship) {
    _showContentDetailsSheet(
      title: (scholarship['title'] ?? 'Scholarship').toString(),
      subtitle: (scholarship['provider'] ?? 'Unknown provider').toString(),
      description: (scholarship['description'] ?? '').toString(),
      detailLines: [
        _SheetDetailLine(
          'Eligibility',
          (scholarship['eligibility'] ?? '').toString(),
        ),
        _SheetDetailLine('Amount', '${scholarship['amount'] ?? 0} DA'),
        _SheetDetailLine(
          'Deadline',
          (scholarship['deadline'] ?? '').toString(),
        ),
      ],
      actionLabel: (scholarship['link'] ?? '').toString().trim().isEmpty
          ? null
          : 'Open Link',
      onAction: () => _openExternalLink((scholarship['link'] ?? '').toString()),
    );
  }

  void _showTrainingDetails(TrainingModel training) {
    _showContentDetailsSheet(
      title: training.title,
      subtitle: training.provider.isNotEmpty ? training.provider : 'Training',
      description: training.description,
      detailLines: [
        _SheetDetailLine('Type', training.type),
        _SheetDetailLine('Source', training.source),
        _SheetDetailLine('Domain', training.domain),
        _SheetDetailLine('Level', training.level),
        _SheetDetailLine('Duration', training.duration),
      ],
      actionLabel: training.displayLink.trim().isEmpty ? null : 'Open Resource',
      onAction: () => _openExternalLink(training.displayLink),
    );
  }

  void _showContentDetailsSheet({
    required String title,
    required String subtitle,
    required String description,
    required List<_SheetDetailLine> detailLines,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
              ),
            ),
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
            const SizedBox(height: 16),
            ...detailLines
                .where((line) => line.value.trim().isNotEmpty)
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildDetailLine(line.label, line.value),
                  ),
                ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildCvSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? 'Not available' : value,
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) {
      return 'Unknown time';
    }

    final dateTime = value is DateTime
        ? value
        : value is Timestamp
        ? value.toDate()
        : null;
    if (dateTime == null) {
      return 'Unknown time';
    }

    return DateFormat('MMM d, yyyy - HH:mm').format(dateTime);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'accepted':
      case 'open':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'featured':
        return _accentColor;
      default:
        return Colors.orange;
    }
  }
}

class _BadgeData {
  final String label;
  final Color color;

  const _BadgeData(this.label, this.color);
}

class _SheetDetailLine {
  final String label;
  final String value;

  const _SheetDetailLine(this.label, this.value);
}
