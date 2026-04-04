import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/notification_model.dart';
import '../models/opportunity_model.dart';
import '../models/scholarship_model.dart';
import '../models/training_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'admin/admin_content_center_screen.dart';
import 'company/applications_screen.dart';
import 'company/chat_screen.dart' as company_chat;
import 'admin/users_screen.dart';
import 'settings/settings_flow_theme.dart';
import 'settings/settings_flow_widgets.dart';
import 'student/chat_screen.dart' as student_chat;
import 'student/opportunity_detail_screen.dart';
import 'student/scholarship_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    final userId = user?.uid ?? '';
    final role = user?.role ?? '';
    final visibleNotifications = provider.notifications
        .where(_matchesFilter)
        .toList();

    return Scaffold(
      backgroundColor: SettingsFlowPalette.background,
      appBar: AppBar(
        title: Text(
          role == 'admin' ? 'Admin Notifications' : 'Notifications',
          style: SettingsFlowTheme.appBarTitle(),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: SettingsFlowPalette.textPrimary,
          ),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => provider.markAllAsRead(userId),
              child: Text(
                'Read all',
                style: SettingsFlowTheme.micro(SettingsFlowPalette.primary),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: SettingsFlowPalette.primary,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SettingsPanel(
                    padding: const EdgeInsets.all(18),
                    child: SettingsAdaptiveHeader(
                      leading: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: SettingsFlowPalette.primaryGradient,
                          borderRadius: SettingsFlowTheme.radius(20),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.unreadCount > 0
                                ? '${provider.unreadCount} unread updates'
                                : 'All caught up',
                            style: SettingsFlowTheme.sectionTitle(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.notifications.isEmpty
                                ? 'Your notification center will fill up as applications, chats, and opportunities change.'
                                : 'Track application decisions, saved item changes, new opportunities, and messages in one place.',
                            style: SettingsFlowTheme.caption(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _NotificationFilter.values
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_filterLabel(filter)),
                              selected: _selectedFilter == filter,
                              showCheckmark: false,
                              labelStyle: SettingsFlowTheme.micro(
                                _selectedFilter == filter
                                    ? Colors.white
                                    : SettingsFlowPalette.textPrimary,
                              ),
                              selectedColor: SettingsFlowPalette.primary,
                              backgroundColor: SettingsFlowPalette.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: SettingsFlowTheme.radius(999),
                                side: const BorderSide(
                                  color: SettingsFlowPalette.border,
                                ),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedFilter = filter);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: visibleNotifications.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SettingsEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'No notifications here',
                            message:
                                'Try another filter or check back after your next application or message update.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: visibleNotifications.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notification = visibleNotifications[index];
                            return _NotificationCard(
                              notification: notification,
                              onTap: () =>
                                  _handleTap(context, notification, provider),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  bool _matchesFilter(NotificationModel notification) {
    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return true;
      case _NotificationFilter.unread:
        return !notification.isRead;
      case _NotificationFilter.applications:
        return notification.type == 'application';
      case _NotificationFilter.messages:
        return notification.type == 'chat';
    }
  }

  String _filterLabel(_NotificationFilter filter) {
    return switch (filter) {
      _NotificationFilter.all => 'All',
      _NotificationFilter.unread => 'Unread',
      _NotificationFilter.applications => 'Applications',
      _NotificationFilter.messages => 'Messages',
    };
  }

  Future<void> _handleTap(
    BuildContext context,
    NotificationModel notif,
    NotificationProvider provider,
  ) async {
    if (!notif.isRead) {
      provider.markAsRead(notif.id);
    }

    if (notif.type == 'chat' && notif.conversationId.isNotEmpty) {
      final otherName = notif.title.replaceFirst('New message from ', '');
      final authProvider = context.read<AuthProvider>();
      final role = authProvider.userModel?.role ?? '';
      final currentUserId = authProvider.userModel?.uid ?? '';

      String recipientId = '';
      try {
        final convDoc = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(notif.conversationId)
            .get();
        if (convDoc.exists) {
          final data = convDoc.data()!;
          final studentId = data['studentId'] as String? ?? '';
          final companyId = data['companyId'] as String? ?? '';
          recipientId = currentUserId == studentId ? companyId : studentId;
        }
      } catch (e) {
        debugPrint('Failed to resolve recipient: $e');
      }

      if (!context.mounted) {
        return;
      }

      Widget chatScreen;
      if (role == 'student') {
        chatScreen = student_chat.ChatScreen(
          conversationId: notif.conversationId,
          otherName: otherName,
          recipientId: recipientId,
        );
      } else {
        chatScreen = company_chat.ChatScreen(
          conversationId: notif.conversationId,
          otherName: otherName,
          recipientId: recipientId,
        );
      }

      Navigator.push(context, MaterialPageRoute(builder: (_) => chatScreen));
      return;
    }

    if (notif.targetId.isNotEmpty) {
      await _navigateToTarget(context, notif);
    }
  }

  Future<void> _navigateToTarget(
    BuildContext context,
    NotificationModel notif,
  ) async {
    try {
      final role = context.read<AuthProvider>().userModel?.role ?? '';

      if (role == 'admin' && notif.type == 'company_review') {
        if (!context.mounted) {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: SettingsFlowPalette.background,
              appBar: AppBar(
                title: const Text('Company Reviews'),
                backgroundColor: Colors.white,
                foregroundColor: SettingsFlowPalette.textPrimary,
              ),
              body: SafeArea(
                child: UsersScreen(
                  initialRoleFilter: 'company',
                  initialCompanyApprovalFilter: 'pending',
                  initialTargetId: notif.targetId,
                ),
              ),
            ),
          ),
        );
        return;
      }

      if (role == 'admin' &&
          const {
            'application',
            'opportunity',
            'scholarship',
            'training',
            'project_idea',
          }.contains(notif.type)) {
        final adminTab = switch (notif.type) {
          'application' => AdminContentCenterScreen.opportunitiesTab,
          'opportunity' => AdminContentCenterScreen.opportunitiesTab,
          'scholarship' => AdminContentCenterScreen.scholarshipsTab,
          'training' => AdminContentCenterScreen.trainingsTab,
          _ => AdminContentCenterScreen.projectIdeasTab,
        };

        if (!context.mounted) {
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminContentCenterScreen(
              initialTab: adminTab,
              initialTargetId: notif.targetId,
            ),
          ),
        );
        return;
      }

      switch (notif.type) {
        case 'opportunity':
          final doc = await FirebaseFirestore.instance
              .collection('opportunities')
              .doc(notif.targetId)
              .get();
          if (!doc.exists || !context.mounted) {
            return;
          }
          final data = doc.data()!;
          if (data['isHidden'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This opportunity is currently hidden'),
              ),
            );
            return;
          }
          data['id'] = doc.id;
          final opportunity = OpportunityModel.fromMap(data);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OpportunityDetailScreen(opportunity: opportunity),
            ),
          );
          return;

        case 'scholarship':
          final doc = await FirebaseFirestore.instance
              .collection('scholarships')
              .doc(notif.targetId)
              .get();
          if (!doc.exists || !context.mounted) {
            return;
          }
          final data = doc.data()!;
          if (data['isHidden'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This scholarship is currently hidden'),
              ),
            );
            return;
          }
          data['id'] = doc.id;
          final scholarship = ScholarshipModel.fromMap(data);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScholarshipDetailScreen(scholarship: scholarship),
            ),
          );
          return;

        case 'training':
          final doc = await FirebaseFirestore.instance
              .collection('trainings')
              .doc(notif.targetId)
              .get();
          if (!doc.exists || !context.mounted) {
            return;
          }
          if ((doc.data()?['isHidden'] ?? false) == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This training is currently hidden'),
              ),
            );
            return;
          }
          final training = TrainingModel.fromMap({
            ...doc.data()!,
            'id': doc.id,
          });
          final url = training.displayLink;
          if (url.isNotEmpty) {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
          return;

        case 'application':
          if (role == 'company') {
            final applicationId = _extractApplicationId(notif);
            if (applicationId.isNotEmpty) {
              final appDoc = await FirebaseFirestore.instance
                  .collection('applications')
                  .doc(applicationId)
                  .get();
              if (appDoc.exists && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicationsScreen(
                      initialApplicationId: applicationId,
                      showBackButton: true,
                    ),
                  ),
                );
                return;
              }
            }
          }

          var oppId = notif.targetId;
          final directOpp = await FirebaseFirestore.instance
              .collection('opportunities')
              .doc(oppId)
              .get();
          if (!directOpp.exists) {
            final appDoc = await FirebaseFirestore.instance
                .collection('applications')
                .doc(oppId)
                .get();
            if (appDoc.exists) {
              oppId = (appDoc.data()?['opportunityId'] ?? '').toString();
            }
          }
          if (oppId.isEmpty || !context.mounted) {
            return;
          }
          final oppDoc = await FirebaseFirestore.instance
              .collection('opportunities')
              .doc(oppId)
              .get();
          if (!oppDoc.exists || !context.mounted) {
            return;
          }
          final oppData = oppDoc.data()!;
          if (oppData['isHidden'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This opportunity is currently hidden'),
              ),
            );
            return;
          }
          oppData['id'] = oppDoc.id;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OpportunityDetailScreen(
                opportunity: OpportunityModel.fromMap(oppData),
              ),
            ),
          );
          return;

        case 'project_idea':
          final doc = await FirebaseFirestore.instance
              .collection('projectIdeas')
              .doc(notif.targetId)
              .get();
          if (!doc.exists || !context.mounted) {
            return;
          }
          final data = doc.data()!;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: SettingsFlowTheme.radius(24),
              ),
              title: Text(
                data['title'] ?? 'Project Idea',
                style: SettingsFlowTheme.sectionTitle(),
              ),
              content: Text(
                data['description'] ?? '',
                style: SettingsFlowTheme.caption(
                  SettingsFlowPalette.textPrimary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: SettingsFlowTheme.micro(SettingsFlowPalette.primary),
                  ),
                ),
              ],
            ),
          );
          return;

        default:
          return;
      }
    } catch (e) {
      debugPrint('Failed to navigate to target: $e');
    }
  }

  String _extractApplicationId(NotificationModel notif) {
    final eventKey = notif.eventKey.trim();

    if (eventKey.startsWith('application-submitted:')) {
      return eventKey.substring('application-submitted:'.length).trim();
    }

    if (eventKey.startsWith('application-status:')) {
      final remainder = eventKey.substring('application-status:'.length).trim();
      final separatorIndex = remainder.indexOf(':');
      if (separatorIndex == -1) {
        return remainder;
      }
      return remainder.substring(0, separatorIndex).trim();
    }

    return notif.targetId.trim();
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = notification.body.isNotEmpty
        ? notification.body
        : notification.message;
    final createdAt = notification.createdAt?.toDate();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: SettingsFlowTheme.radius(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? SettingsFlowPalette.surface
                : SettingsFlowPalette.primary.withValues(alpha: 0.05),
            borderRadius: SettingsFlowTheme.radius(22),
            border: Border.all(
              color: notification.isRead
                  ? SettingsFlowPalette.border
                  : SettingsFlowPalette.primary.withValues(alpha: 0.14),
            ),
            boxShadow: SettingsFlowTheme.softShadow(0.05),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(
                icon: _iconForType(notification.type),
                color: notification.isRead
                    ? SettingsFlowPalette.textSecondary
                    : _accentForType(notification.type),
                backgroundColor: notification.isRead
                    ? SettingsFlowPalette.border.withValues(alpha: 0.45)
                    : _accentForType(notification.type).withValues(alpha: 0.12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: SettingsFlowTheme.cardTitle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: SettingsFlowPalette.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: SettingsFlowTheme.caption(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 210;

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SettingsStatusPill(
                                label: _labelForType(notification.type),
                                color: _accentForType(notification.type),
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(createdAt),
                                  style: SettingsFlowTheme.micro(),
                                ),
                              ],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            SettingsStatusPill(
                              label: _labelForType(notification.type),
                              color: _accentForType(notification.type),
                            ),
                            const Spacer(),
                            Text(
                              createdAt == null ? '' : _formatTime(createdAt),
                              style: SettingsFlowTheme.micro(),
                            ),
                          ],
                        );
                      },
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'opportunity':
        return Icons.work_outline_rounded;
      case 'scholarship':
        return Icons.school_outlined;
      case 'training':
        return Icons.model_training_outlined;
      case 'application':
        return Icons.assignment_outlined;
      case 'project_idea':
        return Icons.lightbulb_outline_rounded;
      case 'company_review':
        return Icons.verified_user_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'chat':
        return SettingsFlowPalette.secondary;
      case 'application':
        return SettingsFlowPalette.primary;
      case 'opportunity':
        return SettingsFlowPalette.accent;
      case 'scholarship':
        return SettingsFlowPalette.success;
      case 'training':
        return SettingsFlowPalette.warning;
      case 'project_idea':
        return SettingsFlowPalette.primaryDark;
      case 'company_review':
        return SettingsFlowPalette.warning;
      default:
        return SettingsFlowPalette.textSecondary;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'chat':
        return 'Message';
      case 'application':
        return 'Application';
      case 'opportunity':
        return 'Opportunity';
      case 'scholarship':
        return 'Scholarship';
      case 'training':
        return 'Training';
      case 'project_idea':
        return 'Idea';
      case 'company_review':
        return 'Company review';
      default:
        return 'Update';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat.MMMd().format(dt);
  }
}

enum _NotificationFilter { all, unread, applications, messages }
