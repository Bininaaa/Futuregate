import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

import '../models/user_model.dart';
import 'profile_avatar.dart';

class RecentUsersList extends StatelessWidget {
  final List<UserModel> users;

  const RecentUsersList({super.key, required this.users});

  String _buildSubtitle(UserModel user, AppLocalizations l10n) {
    if (user.role == 'student' && user.academicLevel == 'doctorat') {
      return '${user.email} - Doctorat${user.researchTopic?.isNotEmpty == true ? ' - ${user.researchTopic}' : ''}';
    }

    if (user.role == 'student') {
      return '${user.email} - ${user.academicLevel ?? l10n.uiNotProvided}';
    }

    if (user.role == 'company') {
      return '${user.email} - ${user.companyName?.isNotEmpty == true ? user.companyName : l10n.uiCompanyNameNotAdded}';
    }

    if (user.role == 'admin') {
      return '${user.email} - ${user.adminLevel?.isNotEmpty == true ? user.adminLevel : l10n.adminRoleLabel}';
    }

    return user.email;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.uiRecentUsers,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (users.isEmpty) Text(l10n.noRecentUsersYet),
            ...users.map(
              (user) => ListTile(
                leading: ProfileAvatar(user: user, radius: 20),
                title: Text(user.fullName),
                subtitle: Text(_buildSubtitle(user, l10n)),
                trailing: Text(
                  user.isActive ? l10n.uiActive : l10n.uiBlocked,
                  style: TextStyle(
                    color: user.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
