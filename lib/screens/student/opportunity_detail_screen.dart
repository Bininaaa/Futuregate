import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../services/application_service.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_type_badge.dart';
import 'chat_screen.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  @override
  State<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  static const Color strongBlue = Color(0xFF004E98);
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color softGray = Color(0xFFEBEBEB);

  late Future<ApplicationEligibilityStatus> _eligibilityFuture;

  @override
  void initState() {
    super.initState();
    _eligibilityFuture = _loadEligibility();
  }

  Future<ApplicationEligibilityStatus> _loadEligibility() {
    final currentUser = context.read<AuthProvider>().userModel;
    return context.read<ApplicationProvider>().getEligibility(
      studentId: currentUser?.uid ?? '',
      opportunityId: widget.opportunity.id,
    );
  }

  void _refreshEligibility() {
    setState(() {
      _eligibilityFuture = _loadEligibility();
    });
  }

  Future<void> _apply() async {
    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

    final eligibility = await applicationProvider.getEligibility(
      studentId: currentUser.uid,
      opportunityId: widget.opportunity.id,
    );

    if (!mounted) {
      return;
    }

    if (eligibility != ApplicationEligibilityStatus.available) {
      messenger.showSnackBar(
        SnackBar(content: Text(_messageForStatus(eligibility))),
      );
      _refreshEligibility();
      return;
    }

    final cvProvider = context.read<CvProvider>();
    await cvProvider.loadCv(currentUser.uid);

    if (!mounted) {
      return;
    }

    final cv = cvProvider.cv;
    if (cv == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please create your CV before applying')),
      );
      return;
    }

    final error = await applicationProvider.applyToOpportunity(
      studentId: currentUser.uid,
      studentName: currentUser.fullName,
      opportunityId: widget.opportunity.id,
      companyId: widget.opportunity.companyId,
      cvId: cv.id,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );
      _refreshEligibility();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      _refreshEligibility();
    }
  }

  Future<void> _openChat() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

    try {
      final conversation = await chatProvider.getOrCreateConversation(
        studentId: currentUser.uid,
        studentName: currentUser.fullName,
        companyId: widget.opportunity.companyId,
        companyName: widget.opportunity.companyName,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            otherName: conversation.companyName,
            recipientId: conversation.companyId,
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

  Future<void> _saveOpportunity() async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      return;
    }

    final error = await savedProvider.saveOpportunity(
      studentId: currentUser.uid,
      opportunityId: widget.opportunity.id,
      title: widget.opportunity.title,
      companyName: widget.opportunity.companyName,
      type: widget.opportunity.type,
      location: widget.opportunity.location,
      deadline: widget.opportunity.deadline,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Opportunity saved')),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String _buttonLabelForStatus(ApplicationEligibilityStatus status) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return 'Login to Apply';
      case ApplicationEligibilityStatus.available:
        return widget.opportunity.type == OpportunityType.sponsoring
            ? 'Apply for Sponsoring'
            : 'Apply Now';
      case ApplicationEligibilityStatus.alreadyApplied:
        return 'Already Applied';
      case ApplicationEligibilityStatus.closed:
        return 'Opportunity Closed';
      case ApplicationEligibilityStatus.unavailable:
        return 'No Longer Available';
    }
  }

  String _messageForStatus(ApplicationEligibilityStatus status) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return 'You must be logged in to apply';
      case ApplicationEligibilityStatus.available:
        return 'You can apply to this opportunity';
      case ApplicationEligibilityStatus.alreadyApplied:
        return 'You have already applied to this opportunity';
      case ApplicationEligibilityStatus.closed:
        return 'This opportunity is closed';
      case ApplicationEligibilityStatus.unavailable:
        return 'This opportunity is no longer available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationProvider = context.watch<ApplicationProvider>();
    final typeColor = OpportunityType.color(widget.opportunity.type);

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'Opportunity Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _saveOpportunity,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor.withValues(alpha: 0.18), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: typeColor.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OpportunityTypeBadge(
                    type: widget.opportunity.type,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.opportunity.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: strongBlue,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.opportunity.companyName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMetaChip(
                        icon: Icons.location_on_outlined,
                        label: widget.opportunity.location,
                      ),
                      _buildMetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: widget.opportunity.deadline.isNotEmpty
                            ? widget.opportunity.deadline
                            : 'No deadline',
                      ),
                      _buildMetaChip(
                        icon: Icons.info_outline,
                        label: widget.opportunity.status.isNotEmpty
                            ? widget.opportunity.status[0].toUpperCase() +
                                  widget.opportunity.status.substring(1)
                            : 'Unknown',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: OpportunityType.descriptionLabel(widget.opportunity.type),
              content: widget.opportunity.description.trim().isNotEmpty
                  ? widget.opportunity.description
                  : 'No description provided.',
            ),
            const SizedBox(height: 14),
            _buildSectionCard(
              title: OpportunityType.requirementsLabel(widget.opportunity.type),
              content: widget.opportunity.requirements.trim().isNotEmpty
                  ? widget.opportunity.requirements
                  : 'No requirements provided.',
            ),
            const SizedBox(height: 24),
            FutureBuilder<ApplicationEligibilityStatus>(
              future: _eligibilityFuture,
              builder: (context, snapshot) {
                final eligibility =
                    snapshot.data ?? ApplicationEligibilityStatus.available;
                final canApply =
                    eligibility == ApplicationEligibilityStatus.available;
                final isCheckingEligibility =
                    snapshot.connectionState == ConnectionState.waiting;

                if (applicationProvider.isLoading || isCheckingEligibility) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canApply ? _apply : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: vibrantOrange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _buttonLabelForStatus(eligibility),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(
                          'Message Company',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          foregroundColor: strongBlue,
                          side: const BorderSide(color: strongBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.55,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: strongBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: strongBlue,
            ),
          ),
        ],
      ),
    );
  }
}
