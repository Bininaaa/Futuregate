import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'student/chat_screen.dart' as student_chat;
import 'student/opportunity_detail_screen.dart';
import 'student/scholarship_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color strongBlue = Color(0xFF004E98);
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color softGray = Color(0xFFEBEBEB);

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final userId = context.read<AuthProvider>().userModel?.uid ?? '';
    final role = context.read<AuthProvider>().userModel?.role ?? '';
    final primaryColor = role == 'admin' ? const Color(0xFF2D1B4E) : strongBlue;
    final title = role == 'admin'
        ? 'Admin Notification Center'
        : 'Notifications';

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notifProvider.markAllAsRead(userId),
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: vibrantOrange,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, notifProvider),
    );
  }

  Widget _buildBody(BuildContext context, NotificationProvider provider) {
    final role = context.read<AuthProvider>().userModel?.role ?? '';

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              role == 'admin'
                  ? 'No admin notifications yet'
                  : 'No notifications yet',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notif = provider.notifications[index];
        return _NotificationTile(
          notification: notif,
          onTap: () => _handleTap(context, notif, provider),
        );
      },
    );
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

      if (!context.mounted) return;

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

      if (role == 'admin' &&
          const {
            'application',
            'opportunity',
            'scholarship',
            'training',
            'project_idea',
          }.contains(notif.type)) {
        final adminTab = switch (notif.type) {
          'application' => AdminContentCenterScreen.applicationsTab,
          'opportunity' => AdminContentCenterScreen.opportunitiesTab,
          'scholarship' => AdminContentCenterScreen.scholarshipsTab,
          'training' => AdminContentCenterScreen.trainingsTab,
          _ => AdminContentCenterScreen.projectIdeasTab,
        };

        if (!context.mounted) return;
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
          if (!doc.exists || !context.mounted) return;
          final data = doc.data()!;
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
          if (!doc.exists || !context.mounted) return;
          final data = doc.data()!;
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
          if (!doc.exists || !context.mounted) return;
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
          if (oppId.isEmpty || !context.mounted) return;
          final oppDoc = await FirebaseFirestore.instance
              .collection('opportunities')
              .doc(oppId)
              .get();
          if (!oppDoc.exists || !context.mounted) return;
          final oppData = oppDoc.data()!;
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
          if (!doc.exists || !context.mounted) return;
          final data = doc.data()!;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                data['title'] ?? 'Project Idea',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Text(
                data['description'] ?? '',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
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

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = notification.createdAt != null
        ? _formatTime(notification.createdAt!.toDate())
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFF004E98).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.grey.withValues(alpha: 0.1)
                    : const Color(0xFFFF6700).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForType(notification.type),
                color: notification.isRead
                    ? Colors.grey
                    : const Color(0xFFFF6700),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: const Color(0xFF004E98),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body.isNotEmpty
                        ? notification.body
                        : notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (!notification.isRead) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6700),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'opportunity':
        return Icons.work_outline;
      case 'scholarship':
        return Icons.school_outlined;
      case 'training':
        return Icons.model_training;
      case 'application':
        return Icons.assignment_outlined;
      case 'project_idea':
        return Icons.lightbulb_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt);
  }
}
