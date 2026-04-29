import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/notification_model.dart';
import '../models/opportunity_model.dart';
import '../models/project_idea_model.dart';
import '../models/scholarship_model.dart';
import '../models/training_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/localized_display.dart';
import '../utils/opportunity_type.dart';
import 'admin/admin_content_center_screen.dart';
import 'admin/admin_home_navigation.dart';
import 'company/chat_screen.dart' as company_chat;
import 'company/company_home_navigation.dart';
import 'settings/settings_flow_theme.dart';
import 'settings/settings_flow_widgets.dart';
import 'student/chat_screen.dart' as student_chat;
import 'student/idea_details_screen.dart';
import 'student/opportunity_detail_screen.dart';
import 'student/scholarship_detail_screen.dart';
import '../widgets/shared/app_feedback.dart';
import '../widgets/shared/app_loading.dart';

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialNotificationData;

  const NotificationsScreen({super.key, this.initialNotificationData});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;
  _NotificationContentFilter _selectedContentFilter =
      _NotificationContentFilter.all;
  _OpportunityNotificationFilter _selectedOpportunityFilter =
      _OpportunityNotificationFilter.all;
  final Map<String, String> _opportunityTypeByTargetId = <String, String>{};
  final Set<String> _queuedOpportunityTypeIds = <String>{};
  final Set<String> _loadingOpportunityTypeIds = <String>{};
  bool _handledInitialNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleInitialNotificationData();
    });
  }

  Future<void> _handleInitialNotificationData() async {
    if (_handledInitialNotification) {
      return;
    }
    _handledInitialNotification = true;
    final data = widget.initialNotificationData;
    if (data == null || data.isEmpty) {
      return;
    }

    final notification = NotificationModel.fromMap({
      'id': (data['id'] ?? '').toString(),
      'userId': (data['userId'] ?? '').toString(),
      'title': (data['title'] ?? '').toString(),
      'message': (data['message'] ?? data['body'] ?? '').toString(),
      'type': (data['type'] ?? '').toString(),
      'conversationId': (data['conversationId'] ?? '').toString(),
      'targetId': (data['targetId'] ?? '').toString(),
      'route': (data['route'] ?? '').toString(),
      'eventKey': (data['eventKey'] ?? '').toString(),
      'isRead': true,
    });
    await _navigateToTarget(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotificationProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    final userId = user?.uid ?? '';
    final role = user?.role ?? '';
    final isStudent = role == 'student';

    if (isStudent) {
      _scheduleOpportunityTypeLoading(provider.notifications);
    }

    final visibleNotifications = provider.notifications
        .where(_matchesFilter)
        .toList();
    final summaryTitle = _summaryTitle(
      l10n,
      provider,
      visibleNotifications.length,
    );
    final summaryMessage = _summaryMessage(
      l10n,
      role,
      provider,
      visibleNotifications.length,
    );
    final emptyTitle = _emptyStateTitle(l10n);
    final emptyMessage = _emptyStateMessage(l10n, role);

    return Scaffold(
      backgroundColor: SettingsFlowPalette.background,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          role == 'admin'
              ? l10n.notifAdminTitle
              : role == 'company'
              ? l10n.notifCompanyTitle
              : l10n.notificationsTitle,
          style: SettingsFlowTheme.appBarTitle(),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(
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
                l10n.notifReadAll,
                style: SettingsFlowTheme.micro(SettingsFlowPalette.primary),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const AppLoadingView(density: AppLoadingDensity.compact)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
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
                              summaryTitle,
                              style: SettingsFlowTheme.sectionTitle(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summaryMessage,
                              style: SettingsFlowTheme.caption(),
                            ),
                          ],
                        ),
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
                    children: _availableFilters(role)
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _NotificationFilterChip(
                              label: _filterLabel(l10n, filter),
                              count: _unreadCountForFilter(provider, filter),
                              selected: _selectedFilter == filter,
                              selectedColor: SettingsFlowPalette.primary,
                              onTap: () {
                                setState(() {
                                  _selectedFilter = filter;
                                  if (filter !=
                                      _NotificationFilter.newContent) {
                                    _selectedContentFilter =
                                        _NotificationContentFilter.all;
                                    _selectedOpportunityFilter =
                                        _OpportunityNotificationFilter.all;
                                  }
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      isStudent &&
                          _selectedFilter == _NotificationFilter.newContent
                      ? Padding(
                          key: const ValueKey('content_filters'),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _NotificationContentFilter.values
                                  .map(
                                    (filter) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _NotificationFilterChip(
                                        label: _contentFilterLabel(
                                          l10n,
                                          filter,
                                        ),
                                        count: _unreadCountForContentFilter(
                                          provider,
                                          filter,
                                        ),
                                        selected:
                                            _selectedContentFilter == filter,
                                        selectedColor:
                                            SettingsFlowPalette.primaryDark,
                                        onTap: () {
                                          setState(() {
                                            _selectedContentFilter = filter;
                                            if (filter !=
                                                _NotificationContentFilter
                                                    .opportunities) {
                                              _selectedOpportunityFilter =
                                                  _OpportunityNotificationFilter
                                                      .all;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('no_content_filters'),
                        ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      isStudent &&
                          _selectedFilter == _NotificationFilter.newContent &&
                          _selectedContentFilter ==
                              _NotificationContentFilter.opportunities
                      ? Padding(
                          key: const ValueKey('opportunity_filters'),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _OpportunityNotificationFilter.values
                                  .map(
                                    (filter) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _NotificationFilterChip(
                                        label: _opportunityFilterLabel(
                                          l10n,
                                          filter,
                                        ),
                                        count: _unreadCountForOpportunityFilter(
                                          provider,
                                          filter,
                                        ),
                                        selected:
                                            _selectedOpportunityFilter ==
                                            filter,
                                        selectedColor: OpportunityType.color(
                                          _accentOpportunityTypeForFilter(
                                            filter,
                                          ),
                                        ),
                                        onTap: () {
                                          setState(
                                            () => _selectedOpportunityFilter =
                                                filter,
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('no_opportunity_filters'),
                        ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: visibleNotifications.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SettingsEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: emptyTitle,
                            message: emptyMessage,
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
                              opportunityType: isStudent
                                  ? _resolvedOpportunityType(notification)
                                  : '',
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
      case _NotificationFilter.newContent:
        return _isContentNotification(notification) &&
            _matchesContentFilter(notification);
      case _NotificationFilter.unread:
        return !notification.isRead;
      case _NotificationFilter.applications:
        return _isApplicationNotificationType(notification.type);
      case _NotificationFilter.messages:
        return notification.type == 'chat';
    }
  }

  int _unreadCountForFilter(
    NotificationProvider provider,
    _NotificationFilter filter,
  ) {
    return provider.notifications
        .where(
          (notification) =>
              !notification.isRead &&
              _matchesNotificationFilter(notification, filter),
        )
        .length;
  }

  int _unreadCountForContentFilter(
    NotificationProvider provider,
    _NotificationContentFilter filter,
  ) {
    return provider.notifications
        .where(
          (notification) =>
              !notification.isRead &&
              _isContentNotification(notification) &&
              _matchesContentFilterValue(notification, filter),
        )
        .length;
  }

  int _unreadCountForOpportunityFilter(
    NotificationProvider provider,
    _OpportunityNotificationFilter filter,
  ) {
    return provider.notifications
        .where(
          (notification) =>
              !notification.isRead &&
              notification.type == 'opportunity' &&
              _matchesOpportunityFilterValue(notification, filter),
        )
        .length;
  }

  bool _matchesNotificationFilter(
    NotificationModel notification,
    _NotificationFilter filter,
  ) {
    switch (filter) {
      case _NotificationFilter.all:
        return true;
      case _NotificationFilter.newContent:
        return _isContentNotification(notification);
      case _NotificationFilter.unread:
        return !notification.isRead;
      case _NotificationFilter.applications:
        return _isApplicationNotificationType(notification.type);
      case _NotificationFilter.messages:
        return notification.type == 'chat';
    }
  }

  bool _isApplicationNotificationType(String type) {
    return type == 'application' || type == 'rejected';
  }

  List<_NotificationFilter> _availableFilters(String role) {
    if (role == 'student') {
      return const <_NotificationFilter>[
        _NotificationFilter.all,
        _NotificationFilter.newContent,
        _NotificationFilter.unread,
        _NotificationFilter.applications,
        _NotificationFilter.messages,
      ];
    }

    return const <_NotificationFilter>[
      _NotificationFilter.all,
      _NotificationFilter.unread,
      _NotificationFilter.applications,
      _NotificationFilter.messages,
    ];
  }

  String _filterLabel(AppLocalizations l10n, _NotificationFilter filter) {
    return switch (filter) {
      _NotificationFilter.all => l10n.notifFilterAll,
      _NotificationFilter.newContent => l10n.notifFilterNewContent,
      _NotificationFilter.unread => l10n.notifFilterUnread,
      _NotificationFilter.applications => l10n.notifFilterApplications,
      _NotificationFilter.messages => l10n.notifFilterMessages,
    };
  }

  bool _isContentNotification(NotificationModel notification) {
    return const {
      'opportunity',
      'scholarship',
      'training',
      'project_idea',
    }.contains(notification.type);
  }

  bool _matchesContentFilter(NotificationModel notification) {
    return _matchesContentFilterValue(notification, _selectedContentFilter);
  }

  bool _matchesContentFilterValue(
    NotificationModel notification,
    _NotificationContentFilter filter,
  ) {
    switch (filter) {
      case _NotificationContentFilter.all:
        return true;
      case _NotificationContentFilter.opportunities:
        return notification.type == 'opportunity' &&
            _matchesOpportunityFilter(notification);
      case _NotificationContentFilter.trainings:
        return notification.type == 'training';
      case _NotificationContentFilter.scholarships:
        return notification.type == 'scholarship';
      case _NotificationContentFilter.ideas:
        return notification.type == 'project_idea';
    }
  }

  String _contentFilterLabel(
    AppLocalizations l10n,
    _NotificationContentFilter filter,
  ) {
    return switch (filter) {
      _NotificationContentFilter.all => l10n.notifContentAll,
      _NotificationContentFilter.opportunities =>
        l10n.notifContentOpportunities,
      _NotificationContentFilter.trainings => l10n.notifContentTrainings,
      _NotificationContentFilter.scholarships => l10n.notifContentScholarships,
      _NotificationContentFilter.ideas => l10n.notifContentIdeas,
    };
  }

  bool _matchesOpportunityFilter(NotificationModel notification) {
    return _matchesOpportunityFilterValue(
      notification,
      _selectedOpportunityFilter,
    );
  }

  bool _matchesOpportunityFilterValue(
    NotificationModel notification,
    _OpportunityNotificationFilter filter,
  ) {
    switch (filter) {
      case _OpportunityNotificationFilter.all:
        return true;
      case _OpportunityNotificationFilter.jobs:
        return _resolvedOpportunityType(notification) == OpportunityType.job;
      case _OpportunityNotificationFilter.internships:
        return _resolvedOpportunityType(notification) ==
            OpportunityType.internship;
      case _OpportunityNotificationFilter.sponsored:
        return _resolvedOpportunityType(notification) ==
            OpportunityType.sponsoring;
    }
  }

  String _opportunityFilterLabel(
    AppLocalizations l10n,
    _OpportunityNotificationFilter filter,
  ) {
    return switch (filter) {
      _OpportunityNotificationFilter.all => l10n.notifOppAll,
      _OpportunityNotificationFilter.jobs => l10n.notifOppJobs,
      _OpportunityNotificationFilter.internships => l10n.notifOppInternships,
      _OpportunityNotificationFilter.sponsored => l10n.notifOppSponsored,
    };
  }

  String _accentOpportunityTypeForFilter(
    _OpportunityNotificationFilter filter,
  ) {
    return switch (filter) {
      _OpportunityNotificationFilter.internships => OpportunityType.internship,
      _OpportunityNotificationFilter.sponsored => OpportunityType.sponsoring,
      _OpportunityNotificationFilter.jobs ||
      _OpportunityNotificationFilter.all => OpportunityType.job,
    };
  }

  String _resolvedOpportunityType(NotificationModel notification) {
    if (notification.type != 'opportunity') {
      return '';
    }

    final targetId = notification.targetId.trim();
    final cachedType = _opportunityTypeByTargetId[targetId]?.trim() ?? '';
    if (cachedType.isNotEmpty) {
      return OpportunityType.parse(cachedType);
    }

    final eventKey = notification.eventKey.trim().toLowerCase();
    if (eventKey.startsWith('opportunity-')) {
      final rawType = eventKey.substring('opportunity-'.length);
      final separatorIndex = rawType.indexOf(':');
      final candidate = separatorIndex == -1
          ? rawType
          : rawType.substring(0, separatorIndex);
      if (const <String>{
        OpportunityType.job,
        OpportunityType.internship,
        OpportunityType.sponsoring,
        'sponsored',
        'sponsorship',
      }.contains(candidate)) {
        return OpportunityType.parse(candidate);
      }
    }

    final title = notification.title.toLowerCase();
    if (title.contains('internship')) {
      return OpportunityType.internship;
    }
    if (title.contains('sponsor')) {
      return OpportunityType.sponsoring;
    }
    if (title.contains('job')) {
      return OpportunityType.job;
    }

    return '';
  }

  void _scheduleOpportunityTypeLoading(List<NotificationModel> notifications) {
    final ids = notifications
        .where((notification) => notification.type == 'opportunity')
        .map((notification) => notification.targetId.trim())
        .where(
          (id) =>
              id.isNotEmpty &&
              !_opportunityTypeByTargetId.containsKey(id) &&
              !_queuedOpportunityTypeIds.contains(id) &&
              !_loadingOpportunityTypeIds.contains(id),
        )
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) {
      return;
    }

    _queuedOpportunityTypeIds.addAll(ids);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _queuedOpportunityTypeIds.removeAll(ids);
        return;
      }
      _loadOpportunityTypes(ids);
    });
  }

  Future<void> _loadOpportunityTypes(List<String> opportunityIds) async {
    _queuedOpportunityTypeIds.removeAll(opportunityIds);
    _loadingOpportunityTypeIds.addAll(opportunityIds);

    try {
      final snapshots = await Future.wait(
        opportunityIds.map(
          (id) => FirebaseFirestore.instance
              .collection('opportunities')
              .doc(id)
              .get(),
        ),
      );

      if (!mounted) {
        _loadingOpportunityTypeIds.removeAll(opportunityIds);
        return;
      }

      final resolvedTypes = <String, String>{};
      for (var index = 0; index < opportunityIds.length; index++) {
        final id = opportunityIds[index];
        final snapshot = snapshots[index];
        if (snapshot.exists) {
          resolvedTypes[id] = OpportunityType.parse(
            snapshot.data()?['type']?.toString(),
          );
        } else {
          resolvedTypes[id] = '';
        }
      }

      setState(() {
        _opportunityTypeByTargetId.addAll(resolvedTypes);
        _loadingOpportunityTypeIds.removeAll(opportunityIds);
      });
    } catch (_) {
      _loadingOpportunityTypeIds.removeAll(opportunityIds);
    }
  }

  String _summaryTitle(
    AppLocalizations l10n,
    NotificationProvider provider,
    int visibleCount,
  ) {
    if (provider.notifications.isEmpty) {
      return l10n.notifAllCaughtUp;
    }

    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return provider.unreadCount > 0
            ? _updatesNeedingAttention(provider.unreadCount)
            : l10n.notifAllCaughtUp;
      case _NotificationFilter.unread:
        return visibleCount > 0
            ? _updatesNeedingAttention(visibleCount)
            : _noUpdatesNeedAttention();
      case _NotificationFilter.applications:
        return _countedNotificationTitle(
          visibleCount,
          enOne: 'application update',
          enMany: 'application updates',
          arOne: 'تحديث طلب واحد',
          arTwo: 'تحديثا طلب',
          arMany: 'تحديثات طلبات',
          frOne: 'mise à jour de candidature',
          frMany: 'mises à jour de candidature',
        );
      case _NotificationFilter.messages:
        return _countedNotificationTitle(
          visibleCount,
          enOne: 'message update',
          enMany: 'message updates',
          arOne: 'تحديث رسالة واحد',
          arTwo: 'تحديثا رسائل',
          arMany: 'تحديثات رسائل',
          frOne: 'mise à jour de message',
          frMany: 'mises à jour de messages',
        );
      case _NotificationFilter.newContent:
        return switch (_selectedContentFilter) {
          _NotificationContentFilter.all => _countedNotificationTitle(
            visibleCount,
            enOne: 'new content alert',
            enMany: 'new content alerts',
            arOne: 'تنبيه محتوى جديد واحد',
            arTwo: 'تنبيها محتوى جديد',
            arMany: 'تنبيهات محتوى جديدة',
            frOne: 'alerte de nouveau contenu',
            frMany: 'alertes de nouveau contenu',
          ),
          _NotificationContentFilter.opportunities => _opportunitySummaryTitle(
            visibleCount,
          ),
          _NotificationContentFilter.trainings => _countedNotificationTitle(
            visibleCount,
            enOne: 'new training alert',
            enMany: 'new training alerts',
            arOne: 'تنبيه تدريب جديد واحد',
            arTwo: 'تنبيها تدريب جديد',
            arMany: 'تنبيهات تدريب جديدة',
            frOne: 'alerte de formation',
            frMany: 'alertes de formation',
          ),
          _NotificationContentFilter.scholarships => _countedNotificationTitle(
            visibleCount,
            enOne: 'new scholarship alert',
            enMany: 'new scholarship alerts',
            arOne: 'تنبيه منحة جديد واحد',
            arTwo: 'تنبيها منح جديدان',
            arMany: 'تنبيهات منح جديدة',
            frOne: 'alerte de bourse',
            frMany: 'alertes de bourses',
          ),
          _NotificationContentFilter.ideas => _countedNotificationTitle(
            visibleCount,
            enOne: 'idea alert',
            enMany: 'idea alerts',
            arOne: 'تنبيه فكرة واحد',
            arTwo: 'تنبيها أفكار',
            arMany: 'تنبيهات أفكار',
            frOne: 'alerte d’idée',
            frMany: 'alertes d’idées',
          ),
        };
    }
  }

  String _summaryMessage(
    AppLocalizations l10n,
    String role,
    NotificationProvider provider,
    int visibleCount,
  ) {
    if (provider.notifications.isEmpty) {
      if (role == 'company') {
        return _copy(
          en: 'Your company notification center will fill up as applicants and chats change.',
          ar: 'سيمتلئ مركز إشعارات شركتك عند تغيّر الطلبات والمحادثات.',
          fr: 'Votre centre de notifications se remplira avec les candidatures et les conversations.',
        );
      }
      if (role == 'admin') {
        return _copy(
          en: 'Your admin notification center will fill up as reviews, content, and platform updates arrive.',
          ar: 'سيمتلئ مركز إشعارات الإدارة مع المراجعات والمحتوى وتحديثات المنصة.',
          fr: 'Votre centre admin se remplira avec les révisions, le contenu et les mises à jour.',
        );
      }
      return _copy(
        en: 'Your notification center will fill up as applications, chats, opportunities, trainings, scholarships, and ideas change.',
        ar: 'سيمتلئ مركز الإشعارات مع تغيّر الطلبات والمحادثات والفرص والتدريبات والمنح والأفكار.',
        fr: 'Votre centre de notifications se remplira avec les candidatures, chats, opportunités, formations, bourses et idées.',
      );
    }

    switch (_selectedFilter) {
      case _NotificationFilter.all:
        if (role == 'company') {
          return _copy(
            en: 'Track applicant activity and conversations in one place.',
            ar: 'تابع نشاط المتقدمين والمحادثات في مكان واحد.',
            fr: 'Suivez l’activité des candidats et les conversations au même endroit.',
          );
        }
        if (role == 'admin') {
          return _copy(
            en: 'Track reviews, content activity, and platform alerts in one place.',
            ar: 'تابع المراجعات ونشاط المحتوى وتنبيهات المنصة في مكان واحد.',
            fr: 'Suivez les révisions, le contenu et les alertes de la plateforme au même endroit.',
          );
        }
        return _copy(
          en: 'Track application decisions, new content, and messages in one place.',
          ar: 'تابع قرارات الطلبات والمحتوى الجديد والرسائل في مكان واحد.',
          fr: 'Suivez les décisions de candidature, le nouveau contenu et les messages au même endroit.',
        );
      case _NotificationFilter.unread:
        return visibleCount > 0
            ? _copy(
                en: 'Focus on the updates you have not opened yet.',
                ar: 'ركّز على التحديثات التي لم تفتحها بعد.',
                fr: 'Concentrez-vous sur les mises à jour non ouvertes.',
              )
            : _copy(
                en: 'Everything has already been reviewed.',
                ar: 'تمت مراجعة كل شيء بالفعل.',
                fr: 'Tout a déjà été consulté.',
              );
      case _NotificationFilter.applications:
        return _copy(
          en: 'Follow new applications, approvals, and rejections without leaving this inbox.',
          ar: 'تابع الطلبات الجديدة والموافقات والرفض من صندوق واحد.',
          fr: 'Suivez les nouvelles candidatures, approbations et refus depuis cette boîte.',
        );
      case _NotificationFilter.messages:
        return _copy(
          en: 'Keep up with active conversations and jump straight back into chat.',
          ar: 'تابع المحادثات النشطة وعد مباشرة إلى الدردشة.',
          fr: 'Suivez les conversations actives et revenez directement au chat.',
        );
      case _NotificationFilter.newContent:
        return switch (_selectedContentFilter) {
          _NotificationContentFilter.all =>
            'Browse fresh opportunities, trainings, scholarships, and idea-related updates together.',
          _NotificationContentFilter.opportunities =>
            _opportunitySummaryMessage(),
          _NotificationContentFilter.trainings =>
            'Catch newly added learning resources and training programs.',
          _NotificationContentFilter.scholarships =>
            'Review fresh scholarship announcements as soon as they arrive.',
          _NotificationContentFilter.ideas =>
            'Keep idea submissions and idea status updates easy to scan.',
        };
    }
  }

  String _updatesNeedingAttention(int count) {
    if (LocalizedDisplay.isArabic(context)) {
      if (count == 1) {
        return 'تحديث واحد يحتاج انتباهك';
      }
      if (count == 2) {
        return 'تحديثان يحتاجان انتباهك';
      }
      return '$count تحديثات تحتاج انتباهك';
    }
    if (LocalizedDisplay.isFrench(context)) {
      return count == 1
          ? '1 mise à jour demande votre attention'
          : '$count mises à jour demandent votre attention';
    }
    return count == 1
        ? '1 update needing attention'
        : '$count updates needing attention';
  }

  String _noUpdatesNeedAttention() {
    if (LocalizedDisplay.isArabic(context)) {
      return 'لا توجد تحديثات تحتاج انتباهك';
    }
    if (LocalizedDisplay.isFrench(context)) {
      return 'Aucune mise à jour ne demande votre attention';
    }
    return 'No updates need attention';
  }

  String _countedNotificationTitle(
    int count, {
    required String enOne,
    required String enMany,
    required String arOne,
    required String arTwo,
    required String arMany,
    required String frOne,
    required String frMany,
  }) {
    if (LocalizedDisplay.isArabic(context)) {
      if (count == 1) {
        return arOne;
      }
      if (count == 2) {
        return arTwo;
      }
      return '$count $arMany';
    }
    if (LocalizedDisplay.isFrench(context)) {
      return count == 1 ? '1 $frOne' : '$count $frMany';
    }
    return count == 1 ? '1 $enOne' : '$count $enMany';
  }

  String _copy({required String en, required String ar, required String fr}) {
    if (LocalizedDisplay.isArabic(context)) {
      return ar;
    }
    if (LocalizedDisplay.isFrench(context)) {
      return fr;
    }
    return en;
  }

  String _emptyStateTitle(AppLocalizations l10n) {
    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return _copy(
          en: 'No notifications right now',
          ar: 'لا توجد إشعارات الآن',
          fr: 'Aucune notification pour le moment',
        );
      case _NotificationFilter.unread:
        return _noUpdatesNeedAttention();
      case _NotificationFilter.applications:
        return _copy(
          en: 'No application updates',
          ar: 'لا توجد تحديثات طلبات',
          fr: 'Aucune mise à jour de candidature',
        );
      case _NotificationFilter.messages:
        return _copy(
          en: 'No message updates',
          ar: 'لا توجد تحديثات رسائل',
          fr: 'Aucune mise à jour de messages',
        );
      case _NotificationFilter.newContent:
        return switch (_selectedContentFilter) {
          _NotificationContentFilter.all => _copy(
            en: 'No new content alerts',
            ar: 'لا توجد تنبيهات محتوى جديد',
            fr: 'Aucune alerte de nouveau contenu',
          ),
          _NotificationContentFilter.opportunities =>
            _opportunityEmptyStateTitle(),
          _NotificationContentFilter.trainings => _copy(
            en: 'No training alerts',
            ar: 'لا توجد تنبيهات تدريب',
            fr: 'Aucune alerte de formation',
          ),
          _NotificationContentFilter.scholarships => _copy(
            en: 'No scholarship alerts',
            ar: 'لا توجد تنبيهات منح',
            fr: 'Aucune alerte de bourses',
          ),
          _NotificationContentFilter.ideas => _copy(
            en: 'No idea alerts',
            ar: 'لا توجد تنبيهات أفكار',
            fr: 'Aucune alerte d’idées',
          ),
        };
    }
  }

  String _emptyStateMessage(AppLocalizations l10n, String role) {
    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return _copy(
          en: 'Check back after your next application, message, or content update.',
          ar: 'عد بعد طلبك أو رسالتك أو تحديث المحتوى التالي.',
          fr: 'Revenez après votre prochaine candidature, message ou mise à jour.',
        );
      case _NotificationFilter.unread:
        return _copy(
          en: 'You have already opened everything in your inbox.',
          ar: 'لقد فتحت كل ما في صندوقك بالفعل.',
          fr: 'Vous avez déjà ouvert tout ce qui se trouve dans votre boîte.',
        );
      case _NotificationFilter.applications:
        return _copy(
          en: 'Application decisions and submissions will appear here.',
          ar: 'ستظهر قرارات الطلبات والإرسالات هنا.',
          fr: 'Les décisions et envois de candidatures apparaîtront ici.',
        );
      case _NotificationFilter.messages:
        return _copy(
          en: 'New conversations and replies will show up here.',
          ar: 'ستظهر المحادثات والردود الجديدة هنا.',
          fr: 'Les nouvelles conversations et réponses apparaîtront ici.',
        );
      case _NotificationFilter.newContent:
        return switch (_selectedContentFilter) {
          _NotificationContentFilter.all =>
            'Try another content filter or check back after the next published item.',
          _NotificationContentFilter.opportunities =>
            _opportunityEmptyStateMessage(),
          _NotificationContentFilter.trainings =>
            'New training notifications will show up here.',
          _NotificationContentFilter.scholarships =>
            'New scholarship notifications will show up here.',
          _NotificationContentFilter.ideas =>
            'Idea notifications will show up here.',
        };
    }
  }

  String _opportunitySummaryTitle(int visibleCount) {
    return switch (_selectedOpportunityFilter) {
      _OpportunityNotificationFilter.jobs => _countedNotificationTitle(
        visibleCount,
        enOne: 'new job alert',
        enMany: 'new job alerts',
        arOne: 'تنبيه وظيفة جديد واحد',
        arTwo: 'تنبيها وظائف جديدان',
        arMany: 'تنبيهات وظائف جديدة',
        frOne: 'alerte d’emploi',
        frMany: 'alertes d’emploi',
      ),
      _OpportunityNotificationFilter.internships => _countedNotificationTitle(
        visibleCount,
        enOne: 'new internship alert',
        enMany: 'new internship alerts',
        arOne: 'تنبيه تدريب جديد واحد',
        arTwo: 'تنبيها تدريب جديدان',
        arMany: 'تنبيهات تدريب جديدة',
        frOne: 'alerte de stage',
        frMany: 'alertes de stage',
      ),
      _OpportunityNotificationFilter.sponsored => _countedNotificationTitle(
        visibleCount,
        enOne: 'new sponsored opportunity alert',
        enMany: 'new sponsored opportunity alerts',
        arOne: 'تنبيه فرصة ممولة واحد',
        arTwo: 'تنبيها فرص ممولة',
        arMany: 'تنبيهات فرص ممولة',
        frOne: 'alerte d’opportunité sponsorisée',
        frMany: 'alertes d’opportunités sponsorisées',
      ),
      _OpportunityNotificationFilter.all => _countedNotificationTitle(
        visibleCount,
        enOne: 'new opportunity alert',
        enMany: 'new opportunity alerts',
        arOne: 'تنبيه فرصة جديد واحد',
        arTwo: 'تنبيها فرص جديدان',
        arMany: 'تنبيهات فرص جديدة',
        frOne: 'alerte d’opportunité',
        frMany: 'alertes d’opportunités',
      ),
    };
  }

  String _opportunitySummaryMessage() {
    return switch (_selectedOpportunityFilter) {
      _OpportunityNotificationFilter.jobs =>
        'Stay on top of new job openings shared with students.',
      _OpportunityNotificationFilter.internships =>
        'Keep internship opportunities easy to scan and revisit.',
      _OpportunityNotificationFilter.sponsored =>
        'Review new sponsored programs and premium student offers in one place.',
      _OpportunityNotificationFilter.all =>
        'Stay on top of new jobs, internships, and sponsored opportunities.',
    };
  }

  String _opportunityEmptyStateTitle() {
    return switch (_selectedOpportunityFilter) {
      _OpportunityNotificationFilter.jobs => _copy(
        en: 'No job alerts',
        ar: 'لا توجد تنبيهات وظائف',
        fr: 'Aucune alerte d’emploi',
      ),
      _OpportunityNotificationFilter.internships => _copy(
        en: 'No internship alerts',
        ar: 'لا توجد تنبيهات تدريب',
        fr: 'Aucune alerte de stage',
      ),
      _OpportunityNotificationFilter.sponsored => _copy(
        en: 'No sponsored opportunity alerts',
        ar: 'لا توجد تنبيهات فرص ممولة',
        fr: 'Aucune alerte d’opportunités sponsorisées',
      ),
      _OpportunityNotificationFilter.all => _copy(
        en: 'No opportunity alerts',
        ar: 'لا توجد تنبيهات فرص',
        fr: 'Aucune alerte d’opportunités',
      ),
    };
  }

  String _opportunityEmptyStateMessage() {
    return switch (_selectedOpportunityFilter) {
      _OpportunityNotificationFilter.jobs => _copy(
        en: 'New job notifications will show up here.',
        ar: 'ستظهر إشعارات الوظائف الجديدة هنا.',
        fr: 'Les nouvelles notifications d’emploi apparaîtront ici.',
      ),
      _OpportunityNotificationFilter.internships => _copy(
        en: 'New internship notifications will show up here.',
        ar: 'ستظهر إشعارات التدريب الجديدة هنا.',
        fr: 'Les nouvelles notifications de stage apparaîtront ici.',
      ),
      _OpportunityNotificationFilter.sponsored => _copy(
        en: 'New sponsored opportunity notifications will show up here.',
        ar: 'ستظهر إشعارات الفرص الممولة الجديدة هنا.',
        fr: 'Les nouvelles notifications sponsorisées apparaîtront ici.',
      ),
      _OpportunityNotificationFilter.all => _copy(
        en: 'New opportunity notifications will show up here.',
        ar: 'ستظهر إشعارات الفرص الجديدة هنا.',
        fr: 'Les nouvelles notifications d’opportunités apparaîtront ici.',
      ),
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
        AdminHomeNavigation.switchToUsers(
          context,
          targetId: notif.targetId,
          roleFilter: 'company',
          companyApprovalFilter: 'pending',
        );
        return;
      }

      if (role == 'admin' &&
          const {
            'application',
            'rejected',
            'opportunity',
            'scholarship',
            'training',
            'project_idea',
          }.contains(notif.type)) {
        final adminTab = switch (notif.type) {
          'application' => AdminContentCenterScreen.opportunitiesTab,
          'rejected' => AdminContentCenterScreen.opportunitiesTab,
          'opportunity' => AdminContentCenterScreen.opportunitiesTab,
          'scholarship' => AdminContentCenterScreen.scholarshipsTab,
          'training' => AdminContentCenterScreen.libraryTab,
          _ => AdminContentCenterScreen.projectIdeasTab,
        };
        final adminTargetId =
            (notif.type == 'application' || notif.type == 'rejected')
            ? (_extractApplicationId(notif).isNotEmpty
                  ? _extractApplicationId(notif)
                  : notif.targetId)
            : notif.targetId;

        if (!context.mounted) {
          return;
        }
        AdminHomeNavigation.switchToContent(
          context,
          contentTab: adminTab,
          targetId: adminTargetId,
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
            context.showAppSnackBar(
              'This opportunity is currently hidden.',
              title: 'Opportunity unavailable',
              type: AppFeedbackType.warning,
            );
            return;
          }
          data['id'] = doc.id;
          final opportunity = OpportunityModel.fromMap(data);
          OpportunityDetailScreen.show(context, opportunity);
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
            context.showAppSnackBar(
              'This scholarship is currently hidden.',
              title: 'Scholarship unavailable',
              type: AppFeedbackType.warning,
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
            context.showAppSnackBar(
              'This training resource is currently hidden.',
              title: 'Training unavailable',
              type: AppFeedbackType.warning,
            );
            return;
          }
          final training = TrainingModel.fromMap({
            ...doc.data()!,
            'id': doc.id,
          });
          await _openTrainingLink(context, training);
          return;

        case 'application':
        case 'rejected':
          if (role == 'company') {
            final applicationId = _extractApplicationId(notif);
            if (applicationId.isNotEmpty) {
              final appDoc = await FirebaseFirestore.instance
                  .collection('applications')
                  .doc(applicationId)
                  .get();
              if (appDoc.exists && context.mounted) {
                CompanyHomeNavigation.switchToApplications(
                  context,
                  applicationId: applicationId,
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
            context.showAppSnackBar(
              'This opportunity is currently hidden.',
              title: 'Opportunity unavailable',
              type: AppFeedbackType.warning,
            );
            return;
          }
          oppData['id'] = oppDoc.id;
          OpportunityDetailScreen.show(
            context,
            OpportunityModel.fromMap(oppData),
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
          final idea = ProjectIdeaModel.fromMap({...doc.data()!, 'id': doc.id});
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IdeaDetailsScreen(
                ideaId: idea.id,
                initialIdea: idea,
                showModerationStatus: true,
              ),
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

  Future<void> _openTrainingLink(
    BuildContext context,
    TrainingModel training,
  ) async {
    final url = training.displayLink.trim();
    if (url.isEmpty) {
      context.showAppSnackBar(
        'This training does not have a link yet.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      context.showAppSnackBar(
        'This training link is not valid.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showAppSnackBar(
        'We couldn\'t open this training link right now.',
        title: 'Open unavailable',
        type: AppFeedbackType.error,
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String opportunityType;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    this.opportunityType = '',
  });

  @override
  Widget build(BuildContext context) {
    final rawBody = notification.body.isNotEmpty
        ? notification.body
        : notification.message;
    final title = _localizedNotificationTitle(context);
    final body = _localizedNotificationBody(context, rawBody);
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
                icon: _iconForType(notification.type, opportunityType),
                color: notification.isRead
                    ? SettingsFlowPalette.textSecondary
                    : _accentForType(notification.type, opportunityType),
                backgroundColor: notification.isRead
                    ? SettingsFlowPalette.border.withValues(alpha: 0.45)
                    : _accentForType(
                        notification.type,
                        opportunityType,
                      ).withValues(alpha: 0.12),
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
                            title,
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
                            decoration: BoxDecoration(
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
                                label: _labelForType(
                                  context,
                                  notification.type,
                                  opportunityType,
                                ),
                                color: _accentForType(
                                  notification.type,
                                  opportunityType,
                                ),
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(context, createdAt),
                                  style: SettingsFlowTheme.micro(),
                                ),
                              ],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            SettingsStatusPill(
                              label: _labelForType(
                                context,
                                notification.type,
                                opportunityType,
                              ),
                              color: _accentForType(
                                notification.type,
                                opportunityType,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              createdAt == null
                                  ? ''
                                  : _formatTime(context, createdAt),
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

  IconData _iconForType(String type, [String opportunityType = '']) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'opportunity':
        return opportunityType.trim().isNotEmpty
            ? OpportunityType.icon(opportunityType)
            : Icons.work_outline_rounded;
      case 'scholarship':
        return Icons.school_outlined;
      case 'training':
        return Icons.model_training_outlined;
      case 'application':
      case 'rejected':
        return Icons.assignment_outlined;
      case 'project_idea':
        return Icons.lightbulb_outline_rounded;
      case 'company_review':
        return Icons.verified_user_outlined;
      case 'company_status':
        return Icons.business_center_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _accentForType(String type, [String opportunityType = '']) {
    switch (type) {
      case 'chat':
        return SettingsFlowPalette.secondary;
      case 'application':
        return SettingsFlowPalette.primary;
      case 'rejected':
        return SettingsFlowPalette.error;
      case 'opportunity':
        return opportunityType.trim().isNotEmpty
            ? OpportunityType.color(opportunityType)
            : SettingsFlowPalette.accent;
      case 'scholarship':
        return SettingsFlowPalette.success;
      case 'training':
        return SettingsFlowPalette.warning;
      case 'project_idea':
        return SettingsFlowPalette.primaryDark;
      case 'company_review':
        return SettingsFlowPalette.warning;
      case 'company_status':
        return SettingsFlowPalette.primary;
      default:
        return SettingsFlowPalette.textSecondary;
    }
  }

  String _labelForType(
    BuildContext context,
    String type, [
    String opportunityType = '',
  ]) {
    final l10n = AppLocalizations.of(context)!;

    switch (type) {
      case 'chat':
        return l10n.notifTypeMessage;
      case 'application':
        return l10n.notifTypeApplication;
      case 'rejected':
        return l10n.uiRejected;
      case 'opportunity':
        return opportunityType.trim().isNotEmpty
            ? OpportunityType.label(opportunityType, l10n)
            : l10n.notifTypeOpportunity;
      case 'scholarship':
        return l10n.notifTypeScholarship;
      case 'training':
        return l10n.notifTypeTraining;
      case 'project_idea':
        return l10n.notifTypeIdea;
      case 'company_review':
        return l10n.notifTypeCompanyReview;
      default:
        return l10n.notifTypeUpdate;
    }
  }

  String _localizedNotificationTitle(BuildContext context) {
    final title = notification.title.trim();
    final lower = title.toLowerCase();
    if (lower.contains('application approved')) {
      return _copy(
        context,
        en: 'Application Approved',
        ar: 'تمت الموافقة على الطلب',
        fr: 'Candidature approuvée',
      );
    }
    if (lower.contains('application rejected')) {
      return _copy(
        context,
        en: 'Application Rejected',
        ar: 'تم رفض الطلب',
        fr: 'Candidature refusée',
      );
    }
    if (lower.startsWith('new message from ')) {
      final sender = title.substring('New message from '.length).trim();
      return _copy(
        context,
        en: title,
        ar: 'رسالة جديدة من $sender',
        fr: 'Nouveau message de $sender',
      );
    }
    return title;
  }

  String _localizedNotificationBody(BuildContext context, String rawBody) {
    final body = rawBody.trim();
    final approved = RegExp(
      r'^Your application to (.+?) was approved by (.+)\.?$',
      caseSensitive: false,
    ).firstMatch(body);
    if (approved != null) {
      final opportunity = approved.group(1)?.trim() ?? '';
      final company = approved.group(2)?.trim().replaceAll('.', '') ?? '';
      return _copy(
        context,
        en: body,
        ar: 'تمت الموافقة على طلبك إلى $opportunity من طرف $company.',
        fr: 'Votre candidature à $opportunity a été approuvée par $company.',
      );
    }

    final rejected = RegExp(
      r'^Your application to (.+?) was rejected by (.+)\.?$',
      caseSensitive: false,
    ).firstMatch(body);
    if (rejected != null) {
      final opportunity = rejected.group(1)?.trim() ?? '';
      final company = rejected.group(2)?.trim().replaceAll('.', '') ?? '';
      return _copy(
        context,
        en: body,
        ar: 'تم رفض طلبك إلى $opportunity من طرف $company.',
        fr: 'Votre candidature à $opportunity a été refusée par $company.',
      );
    }

    return body;
  }

  String _copy(
    BuildContext context, {
    required String en,
    required String ar,
    required String fr,
  }) {
    if (LocalizedDisplay.isArabic(context)) {
      return ar;
    }
    if (LocalizedDisplay.isFrench(context)) {
      return fr;
    }
    return en;
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) {
      return l10n.notifJustNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.studentMinutesAgoCompact(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.studentHoursAgoCompact(diff.inHours);
    }
    if (diff.inDays < 7) {
      return l10n.studentDaysAgoCompact(diff.inDays);
    }
    return LocalizedDisplay.shortDate(context, dt);
  }
}

class _NotificationFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _NotificationFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : SettingsFlowPalette.textPrimary;
    final badgeColor = selected
        ? Colors.white.withValues(alpha: 0.20)
        : selectedColor.withValues(alpha: 0.12);
    final badgeTextColor = selected ? Colors.white : selectedColor;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: SettingsFlowTheme.radius(999),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: SettingsFlowTheme.micro(
                  badgeTextColor,
                ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      selected: selected,
      showCheckmark: false,
      labelStyle: SettingsFlowTheme.micro(foreground),
      selectedColor: selectedColor,
      backgroundColor: SettingsFlowPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: SettingsFlowTheme.radius(999),
        side: BorderSide(
          color: selected
              ? selectedColor.withValues(alpha: 0.42)
              : SettingsFlowPalette.border,
        ),
      ),
      onSelected: (_) => onTap(),
    );
  }
}

enum _NotificationFilter { all, unread, applications, messages, newContent }

enum _NotificationContentFilter {
  all,
  opportunities,
  trainings,
  scholarships,
  ideas,
}

enum _OpportunityNotificationFilter { all, jobs, internships, sponsored }
