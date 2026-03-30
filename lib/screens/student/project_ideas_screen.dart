import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_idea_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_idea_provider.dart';
import 'edit_project_idea_screen.dart';
import 'submit_project_idea_screen.dart';

class ProjectIdeasScreen extends StatefulWidget {
  const ProjectIdeasScreen({super.key});

  @override
  State<ProjectIdeasScreen> createState() => _ProjectIdeasScreenState();
}

class _ProjectIdeasScreenState extends State<ProjectIdeasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  static const Color _primaryColor = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        setState(() => _currentTab = _tabController.index);
      }
    });

    final currentUid = context.read<AuthProvider>().userModel?.uid ?? '';
    final provider = context.read<ProjectIdeaProvider>();
    provider.fetchIdeas(currentUid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIdeaProvider>();
    final currentUid = context.read<AuthProvider>().userModel?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Ideas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Ideas'),
            Tab(text: 'My Ideas'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final projectIdeaProvider = context.read<ProjectIdeaProvider>();

          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitProjectIdeaScreen()),
          );
          if (!mounted) return;
          projectIdeaProvider.fetchIdeas(currentUid);
        },
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(provider),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIdeaList(
                        provider.approvedIdeas,
                        currentUid,
                        showStatus: false,
                      ),
                      _buildIdeaList(
                        provider.myIdeas,
                        currentUid,
                        showStatus: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar(ProjectIdeaProvider provider) {
    final domains = provider.availableDomains;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (provider.filterDomain != null || provider.filterStatus != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  avatar: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  onPressed: provider.clearFilters,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ...domains.map(
              (domain) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(domain, style: const TextStyle(fontSize: 12)),
                  selected: provider.filterDomain == domain,
                  selectedColor: _primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: _primaryColor,
                  onSelected: (selected) {
                    provider.setFilterDomain(selected ? domain : null);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            if (_currentTab == 1) ...[
              const SizedBox(width: 8),
              ...['pending', 'approved', 'rejected'].map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(status, style: const TextStyle(fontSize: 12)),
                    selected: provider.filterStatus == status,
                    selectedColor: _statusColor(status).withValues(alpha: 0.2),
                    checkmarkColor: _statusColor(status),
                    onSelected: (selected) {
                      provider.setFilterStatus(selected ? status : null);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaList(
    List<ProjectIdeaModel> ideas,
    String currentUid, {
    required bool showStatus,
  }) {
    if (ideas.isEmpty) {
      return const Center(child: Text('No project ideas found'));
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<ProjectIdeaProvider>().fetchIdeas(currentUid),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ideas.length,
        itemBuilder: (context, index) {
          final idea = ideas[index];
          final isOwner = idea.submittedBy == currentUid;
          final canEdit = isOwner && idea.status == 'pending';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          ),
                        ),
                      ),
                      if (showStatus || idea.status == 'approved')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              idea.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            idea.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(idea.status),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    idea.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (idea.domain.isNotEmpty)
                        _chip(Icons.category, idea.domain),
                      _chip(Icons.school, idea.level),
                      if (idea.tools.isNotEmpty)
                        _chip(Icons.build_outlined, idea.tools),
                    ],
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit button — only visible while idea is pending
                        if (canEdit)
                          TextButton.icon(
                            onPressed: () async {
                              final provider =
                                  context.read<ProjectIdeaProvider>();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditProjectIdeaScreen(idea: idea),
                                ),
                              );
                              if (!mounted) return;
                              provider.fetchIdeas(currentUid);
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.blue,
                            ),
                            label: const Text(
                              'Edit',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        // Delete button — always visible for owner
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Idea'),
                                content: const Text(
                                  'Are you sure you want to delete this idea?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              context
                                  .read<ProjectIdeaProvider>()
                                  .deleteProjectIdea(idea.id);
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
