import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/admin_provider.dart';
import '../../models/cv_model.dart';
import '../../models/user_model.dart';
import '../../services/cv_service.dart';
import '../../services/document_access_service.dart';
import '../../widgets/profile_avatar.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CvService _cvService = CvService();
  final DocumentAccessService _documentAccessService = DocumentAccessService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadAllUsers();
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onChanged: (val) => provider.setUserSearch(val),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF8C00)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          provider.setUserSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleChip('All', 'all', provider),
                const SizedBox(width: 8),
                _buildRoleChip('Students', 'student', provider),
                const SizedBox(width: 8),
                _buildRoleChip('Companies', 'company', provider),
                const SizedBox(width: 8),
                _buildRoleChip('Admins', 'admin', provider),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        if (provider.userRoleFilter == 'student' ||
            provider.userRoleFilter == 'all')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Level: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildLevelChip('All', 'all', provider),
                  const SizedBox(width: 6),
                  _buildLevelChip('Bac', 'bac', provider),
                  const SizedBox(width: 6),
                  _buildLevelChip('Licence', 'licence', provider),
                  const SizedBox(width: 6),
                  _buildLevelChip('Master', 'master', provider),
                  const SizedBox(width: 6),
                  _buildLevelChip('Doctorat', 'doctorat', provider),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: provider.usersLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
                )
              : provider.allUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No users found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF8C00),
                  onRefresh: provider.loadAllUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.allUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(provider.allUsers[index], provider);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.userRoleFilter == value;
    return GestureDetector(
      onTap: () => provider.setUserRoleFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF8C00)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF8C00)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2D1B4E),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.userLevelFilter == value;
    return GestureDetector(
      onTap: () => provider.setUserLevelFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D1B4E)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D1B4E)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, AdminProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: ProfileAvatar(user: user, radius: 20),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleBadge(user.role),
                if (user.role == 'student' &&
                    user.academicLevel != null &&
                    user.academicLevel!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildLevelBadge(user.academicLevel!),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.isActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'toggle') {
                  _showToggleDialog(user, provider);
                } else if (value == 'details') {
                  _showUserDetails(user);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: user.isActive ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(user.isActive ? 'Block User' : 'Unblock User'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _roleColor(role),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.purple,
        ),
      ),
    );
  }

  void _showToggleDialog(UserModel user, AdminProvider provider) {
    final action = user.isActive ? 'Block' : 'Unblock';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('$action User'),
        content: Text(
          'Are you sure you want to ${action.toLowerCase()} ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await provider.toggleUserActive(
                user.uid,
                !user.isActive,
              );
              if (!mounted) return;
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: Text(
              action,
              style: TextStyle(
                color: user.isActive ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ProfileAvatar(user: user, radius: 40),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1B4E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRoleBadge(user.role),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (user.isActive ? Colors.green : Colors.red)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.isActive ? 'Active' : 'Blocked',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: user.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.email, 'Email', user.email),
                  _buildDetailRow(
                    Icons.phone,
                    'Phone',
                    user.phone.isNotEmpty ? user.phone : 'Not provided',
                  ),
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    user.location.isNotEmpty ? user.location : 'Not provided',
                  ),
                  if (user.role == 'student') ...[
                    _buildDetailRow(
                      Icons.school,
                      'Academic Level',
                      user.academicLevel?.isNotEmpty == true
                          ? user.academicLevel!
                          : 'Not set',
                    ),
                    _buildDetailRow(
                      Icons.account_balance,
                      'University',
                      user.university?.isNotEmpty == true
                          ? user.university!
                          : 'Not set',
                    ),
                    _buildDetailRow(
                      Icons.subject,
                      'Field of Study',
                      user.fieldOfStudy?.isNotEmpty == true
                          ? user.fieldOfStudy!
                          : 'Not set',
                    ),
                  ],
                  if (user.role == 'student' &&
                      user.academicLevel == 'doctorat') ...[
                    _buildDetailRow(
                      Icons.science,
                      'Research Topic',
                      user.researchTopic?.isNotEmpty == true
                          ? user.researchTopic!
                          : 'Not set',
                    ),
                    _buildDetailRow(
                      Icons.biotech,
                      'Laboratory',
                      user.laboratory?.isNotEmpty == true
                          ? user.laboratory!
                          : 'Not set',
                    ),
                    _buildDetailRow(
                      Icons.person_outline,
                      'Supervisor',
                      user.supervisor?.isNotEmpty == true
                          ? user.supervisor!
                          : 'Not set',
                    ),
                    _buildDetailRow(
                      Icons.category,
                      'Research Domain',
                      user.researchDomain?.isNotEmpty == true
                          ? user.researchDomain!
                          : 'Not set',
                    ),
                  ],
                  if (user.role == 'company') ...[
                    _buildDetailRow(
                      Icons.business,
                      'Company',
                      user.companyName?.isNotEmpty == true
                          ? user.companyName!
                          : 'Not set',
                    ),
                    _buildDetailRow(
                      Icons.category,
                      'Sector',
                      user.sector?.isNotEmpty == true
                          ? user.sector!
                          : 'Not set',
                    ),
                    _buildDetailRow(
                      Icons.language,
                      'Website',
                      user.website?.isNotEmpty == true
                          ? user.website!
                          : 'Not set',
                    ),
                  ],
                  if (user.role == 'student') ...[
                    const SizedBox(height: 8),
                    FutureBuilder<CvModel?>(
                      future: _cvService.getCvByStudentId(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(),
                          );
                        }

                        return _buildStudentCvSection(user, snapshot.data);
                      },
                    ),
                  ],
                  if (user.role == 'company') ...[
                    const SizedBox(height: 8),
                    _buildCompanyCommercialRegisterSection(user),
                  ],
                  if (user.bio?.isNotEmpty == true)
                    _buildDetailRow(Icons.person, 'Bio', user.bio!),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentCvSection(UserModel user, CvModel? cv) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF8C00).withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applicant CV',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B4E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cv == null
                ? 'No CV has been created for this user yet.'
                : cv.hasUploadedCv
                ? 'Primary CV: ${cv.uploadedCvDisplayName}'
                : 'No primary CV uploaded',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            cv == null
                ? 'Built CV unavailable'
                : cv.hasExportedPdf
                ? 'Built CV PDF available'
                : cv.hasBuilderContent
                ? 'Built CV information available'
                : 'Built CV unavailable',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          if (cv != null && cv.hasUploadedCv) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: cv.isUploadedCvPdf
                        ? () => _openUserCvDocument(
                            user.uid,
                            variant: 'primary',
                            requirePdf: true,
                          )
                        : null,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View CV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openUserCvDocument(
                      user.uid,
                      variant: 'primary',
                      download: true,
                    ),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download CV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8C00),
                      side: BorderSide(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!cv.isUploadedCvPdf) ...[
              const SizedBox(height: 10),
              Text(
                'The uploaded file is not a valid PDF.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          if (cv != null && cv.hasExportedPdf) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openUserCvDocument(
                      user.uid,
                      variant: 'built',
                      requirePdf: true,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('View Built CV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D1B4E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openUserCvDocument(
                      user.uid,
                      variant: 'built',
                      download: true,
                    ),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download Built CV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D1B4E),
                      side: BorderSide(
                        color: const Color(0xFF2D1B4E).withValues(alpha: 0.24),
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

  Widget _buildCompanyCommercialRegisterSection(UserModel user) {
    final uploadedAt = user.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? 'Not available'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF8C00).withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سجل تجاري',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B4E),
            ),
          ),
          const SizedBox(height: 8),
          if (user.hasCommercialRegister) ...[
            Text(
              user.commercialRegisterFileName.isNotEmpty
                  ? user.commercialRegisterFileName
                  : 'Commercial Register uploaded',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Uploaded: $uploadedAtLabel',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCommercialRegister(user.uid),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View سجل تجاري'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openCommercialRegister(user.uid, download: true),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download سجل تجاري'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8C00),
                      side: BorderSide(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Missing commercial register document.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUserCvDocument(
    String userId, {
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService.getUserCvDocument(
        userId: userId,
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

  Future<void> _openCommercialRegister(
    String companyId, {
    bool download = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService
          .getCompanyCommercialRegister(companyId: companyId);
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF8C00)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D1B4E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'student':
        return Colors.blue;
      case 'company':
        return Colors.teal;
      case 'admin':
        return const Color(0xFFFF8C00);
      default:
        return Colors.grey;
    }
  }
}
