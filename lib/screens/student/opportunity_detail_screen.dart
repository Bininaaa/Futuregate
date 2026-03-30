import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../services/application_service.dart';
import 'chat_screen.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailScreen({
    super.key,
    required this.opportunity,
  });

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
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
        const SnackBar(
          content: Text('Please create your CV before applying'),
        ),
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
      messenger.showSnackBar(
        SnackBar(content: Text(error)),
      );
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
      messenger.showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  String _buttonLabelForStatus(ApplicationEligibilityStatus status) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return 'Login to Apply';
      case ApplicationEligibilityStatus.available:
        return 'Apply Now';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunity Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _saveOpportunity,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              widget.opportunity.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.business, 'Company', widget.opportunity.companyName),
            _infoRow(Icons.location_on, 'Location', widget.opportunity.location),
            _infoRow(Icons.category, 'Type', widget.opportunity.type),
            _infoRow(Icons.info_outline, 'Status', widget.opportunity.status),
            _infoRow(Icons.calendar_today, 'Deadline', widget.opportunity.deadline),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.opportunity.description),
            const SizedBox(height: 20),
            const Text(
              'Requirements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.opportunity.requirements),
            const SizedBox(height: 30),
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

                return ElevatedButton(
                  onPressed: canApply ? _apply : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _buttonLabelForStatus(eligibility),
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_outlined),
              label: const Text(
                'Message Company',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: const Color(0xFF004E98),
                side: const BorderSide(color: Color(0xFF004E98)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
