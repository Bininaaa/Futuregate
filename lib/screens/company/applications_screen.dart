import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/company_provider.dart';
import '../../models/application_model.dart';
import '../../models/cv_model.dart';
import '../../services/document_access_service.dart';
import '../../widgets/profile_avatar.dart';
import 'chat_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  final String? initialApplicationId;
  final bool showBackButton;

  const ApplicationsScreen({
    super.key,
    this.initialApplicationId,
    this.showBackButton = false,
  });

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color strongBlue = Color(0xFF004E98);
  static const Color mediumBlue = Color(0xFF3A6EA5);
  static const Color softGray = Color(0xFFEBEBEB);
  final DocumentAccessService _documentAccessService = DocumentAccessService();

  String _statusFilter = 'all';
  String _opportunityFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        final provider = context.read<CompanyProvider>();
        provider.loadApplications(user.uid);
        provider.loadOpportunities(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();
    final isFocusedView =
        widget.initialApplicationId != null &&
        widget.initialApplicationId!.trim().isNotEmpty;

    var filteredApps = _statusFilter == 'all'
        ? provider.applications
        : provider.applications
              .where((a) => a.status == _statusFilter)
              .toList();

    if (_opportunityFilter != 'all') {
      filteredApps = filteredApps
          .where((a) => a.opportunityId == _opportunityFilter)
          .toList();
    }

    if (isFocusedView) {
      filteredApps = provider.applications
          .where((a) => a.id == widget.initialApplicationId)
          .toList();
    }

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'Applications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: Column(
        children: [
          if (!isFocusedView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Accepted', 'accepted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ),
          if (!isFocusedView && provider.opportunities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildOppFilterChip('All Opportunities', 'all'),
                    const SizedBox(width: 8),
                    ...provider.opportunities.map((opp) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildOppFilterChip(opp.title, opp.id),
                      );
                    }),
                  ],
                ),
              ),
            ),
          Expanded(
            child: provider.applicationsLoading
                ? const Center(
                    child: CircularProgressIndicator(color: vibrantOrange),
                  )
                : RefreshIndicator(
                    color: vibrantOrange,
                    onRefresh: () {
                      final user = context.read<AuthProvider>().userModel;
                      return provider.loadApplications(user?.uid ?? '');
                    },
                    child: filteredApps.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return ListView(
                                children: [
                                  SizedBox(
                                    height: constraints.maxHeight,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inbox_outlined,
                                            size: 60,
                                            color: mediumBlue,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            isFocusedView
                                                ? 'Application not found'
                                                : 'No applications found',
                                            style: GoogleFonts.poppins(
                                              color: mediumBlue,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isFocusedView
                                                ? 'This application may have been removed or is no longer available.'
                                                : 'Pull down to refresh',
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            itemCount: filteredApps.length,
                            itemBuilder: (context, index) {
                              final app = filteredApps[index];
                              return _buildApplicationCard(app, provider);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOppFilterChip(String label, String value) {
    final isSelected = _opportunityFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _opportunityFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? mediumBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mediumBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : mediumBlue,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    final chipColor = value == 'all' ? strongBlue : _statusColor(value);

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : mediumBlue,
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildApplicationCard(ApplicationModel app, CompanyProvider provider) {
    final opp = provider.opportunities
        .where((o) => o.id == app.opportunityId)
        .firstOrNull;
    final oppTitle = opp?.title ?? 'Unknown Opportunity';

    final statusColor = _statusColor(app.status);

    final appliedAt = app.appliedAt;
    String dateStr = '';
    if (appliedAt != null) {
      final dt = appliedAt.toDate();
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  radius: 22,
                  userId: app.studentId,
                  fallbackName: app.studentName,
                  role: 'student',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: strongBlue,
                        ),
                      ),
                      Text(
                        oppTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: mediumBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    app.status.isNotEmpty
                        ? app.status[0].toUpperCase() + app.status.substring(1)
                        : 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Applied: $dateStr',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: buttonWidth < 120
                          ? constraints.maxWidth
                          : buttonWidth,
                      child: GestureDetector(
                        onTap: () => _openChatWithStudent(app),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: vibrantOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_outlined,
                                size: 14,
                                color: vibrantOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Message',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: vibrantOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth < 120
                          ? constraints.maxWidth
                          : buttonWidth,
                      child: GestureDetector(
                        onTap: () => _showCvSheet(context, app, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: strongBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: strongBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View CV',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: strongBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (app.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: provider.isAppBusy(app.id)
                            ? null
                            : () => _updateStatus(
                                context,
                                app,
                                'accepted',
                                provider,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          provider.isAppBusy(app.id) ? 'Working...' : 'Accept',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: provider.isAppBusy(app.id)
                            ? null
                            : () => _updateStatus(
                                context,
                                app,
                                'rejected',
                                provider,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          provider.isAppBusy(app.id) ? 'Working...' : 'Reject',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openChatWithStudent(ApplicationModel app) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    try {
      final conversation = await chatProvider.getOrCreateConversation(
        studentId: app.studentId,
        studentName: app.studentName,
        companyId: currentUser.uid,
        companyName: currentUser.companyName ?? currentUser.fullName,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            otherName: conversation.studentName,
            recipientId: conversation.studentId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open chat: $e')),
      );
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    ApplicationModel app,
    String status,
    CompanyProvider provider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final error = await provider.updateApplicationStatus(
      appId: app.id,
      status: status,
    );

    if (!mounted) {
      return;
    }

    if (error != null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(error)));
    } else if (currentUserId != null) {
      provider.loadApplications(currentUserId);
    }
  }

  Future<void> _showCvSheet(
    BuildContext context,
    ApplicationModel app,
    CompanyProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<CvModel?>(
          future: provider.getApplicationCv(app.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: vibrantOrange),
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
                      style: GoogleFonts.poppins(color: mediumBlue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final cv = snapshot.data;

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.92,
              minChildSize: 0.3,
              expand: false,
              builder: (_, scrollController) {
                if (cv == null) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Icon(
                          Icons.description_outlined,
                          size: 50,
                          color: mediumBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No CV available for ${app.studentName}',
                          style: GoogleFonts.poppins(color: mediumBlue),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 16),
                    Text(
                      cv.fullName.isNotEmpty ? cv.fullName : app.studentName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: strongBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cv.email} • ${cv.phone}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: mediumBlue,
                      ),
                    ),
                    if (cv.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cv.address,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: mediumBlue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildDocumentReviewCard(
                      title: 'Primary CV PDF',
                      subtitle: cv.hasUploadedCv
                          ? 'File: ${cv.uploadedCvDisplayName}\nUploaded: ${_formatDate(cv.uploadedCvUploadedAt)}'
                          : 'No CV uploaded',
                      accentColor: vibrantOrange,
                      warningText: cv.hasUploadedCv && !cv.isUploadedCvPdf
                          ? 'This uploaded file is not a valid PDF. Ask the applicant to replace it with a PDF version.'
                          : null,
                      onView: cv.hasUploadedCv && cv.isUploadedCvPdf
                          ? () => _openApplicationDocument(
                              app,
                              variant: 'primary',
                              requirePdf: true,
                            )
                          : null,
                      onDownload: cv.hasUploadedCv
                          ? () => _openApplicationDocument(
                              app,
                              variant: 'primary',
                              download: true,
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildDocumentReviewCard(
                      title: 'Built CV',
                      subtitle: cv.hasExportedPdf
                          ? 'Built CV PDF is ready for review.'
                          : cv.hasBuilderContent
                          ? 'Built CV information is available, but no PDF has been exported yet.'
                          : 'No built CV information available.',
                      accentColor: strongBlue,
                      onView: cv.hasExportedPdf
                          ? () => _openApplicationDocument(
                              app,
                              variant: 'built',
                              requirePdf: true,
                            )
                          : null,
                      onDownload: cv.hasExportedPdf
                          ? () => _openApplicationDocument(
                              app,
                              variant: 'built',
                              download: true,
                            )
                          : null,
                    ),
                    if (cv.summary.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildCvSection('Summary', [cv.summary]),
                    ],
                    if (cv.education.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildCvSection(
                        'Education',
                        cv.education
                            .map(
                              (e) =>
                                  '${e['degree'] ?? ''} - ${e['institution'] ?? ''} (${e['year'] ?? ''})',
                            )
                            .toList(),
                      ),
                    ],
                    if (cv.experience.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildCvSection(
                        'Experience',
                        cv.experience
                            .map(
                              (e) =>
                                  '${e['position'] ?? e['title'] ?? ''} at ${e['company'] ?? ''} (${e['duration'] ?? ''})',
                            )
                            .toList(),
                      ),
                    ],
                    if (cv.skills.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Skills',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: strongBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: cv.skills
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: vibrantOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: vibrantOrange,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (cv.languages.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Languages',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: strongBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: cv.languages
                            .map(
                              (l) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: mediumBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  l,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: mediumBlue,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
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
    ApplicationModel app, {
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService.getApplicationCvDocument(
        applicationId: app.id,
        variant: variant,
      );

      if (requirePdf && !document.isPdf) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('The requested file is not a valid PDF.'),
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

  Widget _buildDocumentReviewCard({
    required String title,
    required String subtitle,
    required Color accentColor,
    VoidCallback? onView,
    VoidCallback? onDownload,
    String? warningText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              color: mediumBlue,
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 10),
            Text(
              warningText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.4,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (onView != null || onDownload != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onView != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View CV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: strongBlue,
                        side: BorderSide(
                          color: strongBlue.withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  ),
                if (onView != null && onDownload != null)
                  const SizedBox(width: 10),
                if (onDownload != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download CV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
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

  String _formatDate(Timestamp? value) {
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
      return 'The requested file is no longer available.';
    }

    return 'Could not open the document right now.';
  }

  Widget _buildCvSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }
}
