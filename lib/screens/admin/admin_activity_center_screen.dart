import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/admin_activity_model.dart';
import '../../providers/admin_provider.dart';
import 'admin_content_center_screen.dart';

class AdminActivityCenterScreen extends StatefulWidget {
  const AdminActivityCenterScreen({super.key});

  @override
  State<AdminActivityCenterScreen> createState() =>
      _AdminActivityCenterScreenState();
}

class _AdminActivityCenterScreenState extends State<AdminActivityCenterScreen> {
  static const Color _primaryColor = Color(0xFF2D1B4E);
  static const Color _accentColor = Color(0xFFFF8C00);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadActivityFeed(reset: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final activities = provider.recentActivity
        .where((activity) => activity.matchesQuery(_searchController.text))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FB),
      appBar: AppBar(
        title: const Text('Recent Activity'),
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by type, title, actor, or status...',
                prefixIcon: const Icon(Icons.search, color: _accentColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: provider.activityLoading && provider.recentActivity.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  )
                : provider.activityError != null &&
                      provider.recentActivity.isEmpty
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
                          'Failed to load recent activity',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              provider.loadActivityFeed(reset: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: _accentColor,
                    onRefresh: () => provider.loadActivityFeed(reset: true),
                    child: activities.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 180),
                              Center(child: Text('No recent activity')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: activities.length + 1,
                            itemBuilder: (context, index) {
                              if (index == activities.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: OutlinedButton(
                                    onPressed: provider.activityLoadingMore
                                        ? null
                                        : provider.loadMoreActivityFeed,
                                    child: Text(
                                      provider.activityLoadingMore
                                          ? 'Loading...'
                                          : 'Load More',
                                    ),
                                  ),
                                );
                              }

                              final activity = activities[index];
                              return _ActivityTile(
                                activity: activity,
                                onOpen: () => _openActivity(activity),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openActivity(AdminActivityModel activity) {
    final target = switch (activity.type) {
      'application' => AdminContentCenterScreen.applicationsTab,
      'opportunity' => AdminContentCenterScreen.opportunitiesTab,
      'scholarship' => AdminContentCenterScreen.scholarshipsTab,
      'training' => AdminContentCenterScreen.trainingsTab,
      _ => AdminContentCenterScreen.projectIdeasTab,
    };

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminContentCenterScreen(
          initialTab: target,
          initialTargetId: activity.relatedId,
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AdminActivityModel activity;
  final VoidCallback onOpen;

  const _ActivityTile({required this.activity, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final accentColor = _colorForType(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForType(activity.type), color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF2D1B4E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _metaChip(activity.type.replaceAll('_', ' '), accentColor),
                    if (activity.actorName.trim().isNotEmpty)
                      _metaChip(activity.actorName, const Color(0xFF3A6EA5)),
                    if (activity.status.trim().isNotEmpty)
                      _metaChip(activity.status, _statusColor(activity.status)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activity.createdAt == null
                      ? 'Unknown time'
                      : DateFormat(
                          'MMM d, yyyy • HH:mm',
                        ).format(activity.createdAt!.toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onOpen, child: const Text('Open')),
        ],
      ),
    );
  }

  static Widget _metaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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

  static IconData _iconForType(String type) {
    switch (type) {
      case 'application':
        return Icons.assignment_outlined;
      case 'opportunity':
        return Icons.work_outline;
      case 'scholarship':
        return Icons.card_giftcard;
      case 'training':
        return Icons.cast_for_education_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'application':
        return Colors.deepPurple;
      case 'opportunity':
        return const Color(0xFFFF8C00);
      case 'scholarship':
        return Colors.pink;
      case 'training':
        return Colors.cyan;
      default:
        return Colors.amber.shade700;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'accepted':
      case 'open':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
