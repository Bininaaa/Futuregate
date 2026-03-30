import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../widgets/opportunity_type_badge.dart';
import 'publish_opportunity_screen.dart';

class MyOpportunitiesScreen extends StatefulWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  State<MyOpportunitiesScreen> createState() => _MyOpportunitiesScreenState();
}

class _MyOpportunitiesScreenState extends State<MyOpportunitiesScreen> {
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color strongBlue = Color(0xFF004E98);
  static const Color mediumBlue = Color(0xFF3A6EA5);
  static const Color softGray = Color(0xFFEBEBEB);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        final provider = context.read<CompanyProvider>();
        provider.loadOpportunities(user.uid);
        provider.loadApplications(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'My Opportunities',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: strongBlue),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: vibrantOrange, size: 28),
            onPressed: () => _navigateToPublish(context),
          ),
        ],
      ),
      body: provider.opportunitiesLoading
          ? const Center(
              child: CircularProgressIndicator(color: vibrantOrange))
          : RefreshIndicator(
              color: vibrantOrange,
              onRefresh: () async {
                final user = context.read<AuthProvider>().userModel;
                if (user != null) {
                  await provider.loadOpportunities(user.uid);
                  await provider.loadApplications(user.uid);
                }
              },
              child: provider.opportunities.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.work_off_outlined,
                                  size: 60, color: mediumBlue),
                              const SizedBox(height: 12),
                              Text(
                                'No opportunities yet',
                                style: GoogleFonts.poppins(
                                    color: mediumBlue, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _navigateToPublish(context),
                                child: Text(
                                  'Post your first opportunity',
                                  style: GoogleFonts.poppins(
                                    color: vibrantOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.opportunities.length,
                      itemBuilder: (context, index) {
                        final opp = provider.opportunities[index];
                        final appCount = provider.applications
                            .where((a) => a.opportunityId == opp.id)
                            .length;

                        final isOpen = opp.status == 'open';

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
                                    Expanded(
                                      child: Text(
                                        opp.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: strongBlue,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isOpen
                                                ? Colors.green
                                                : Colors.grey)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isOpen ? 'Open' : 'Closed',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isOpen
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    OpportunityTypeBadge(
                                      type: opp.type,
                                      fontSize: 10,
                                    ),
                                    _buildTag(opp.location, Colors.grey),
                                    _buildTag('Deadline: ${opp.deadline}',
                                        Colors.orange),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.people_outline,
                                        size: 16, color: mediumBlue),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$appCount application${appCount == 1 ? '' : 's'}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: mediumBlue),
                                    ),
                                    const Spacer(),
                                    _buildActionButton(
                                      Icons.edit_outlined,
                                      mediumBlue,
                                      () => _navigateToEdit(context, opp.id),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildActionButton(
                                      isOpen
                                          ? Icons.pause_circle_outline
                                          : Icons.play_circle_outline,
                                      isOpen ? Colors.orange : Colors.green,
                                      () => _toggleStatus(
                                          context, opp.id, isOpen),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildActionButton(
                                      Icons.delete_outline,
                                      Colors.red,
                                      () => _confirmDelete(context, opp.id,
                                          opp.title),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _navigateToPublish(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final companyProvider = context.read<CompanyProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublishOpportunityScreen()),
    ).then((_) {
      if (!mounted) {
        return;
      }
      final user = authProvider.userModel;
      if (user != null) {
        companyProvider.loadOpportunities(user.uid);
      }
    });
  }

  void _navigateToEdit(BuildContext context, String oppId) {
    final authProvider = context.read<AuthProvider>();
    final companyProvider = context.read<CompanyProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublishOpportunityScreen(opportunityId: oppId),
      ),
    ).then((_) {
      if (!mounted) {
        return;
      }
      final user = authProvider.userModel;
      if (user != null) {
        companyProvider.loadOpportunities(user.uid);
      }
    });
  }

  Future<void> _toggleStatus(
      BuildContext context, String oppId, bool isOpen) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final provider = context.read<CompanyProvider>();
    final newStatus = isOpen ? 'closed' : 'open';
    final error =
        await provider.updateOpportunity(oppId, {'status': newStatus});

    if (!mounted) {
      return;
    }

    if (error != null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(error)));
    } else {
      final user = authProvider.userModel;
      if (user != null) {
        provider.loadOpportunities(user.uid);
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, String oppId, String title) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final provider = context.read<CompanyProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Opportunity',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: strongBlue)),
        content: Text(
            'Delete "$title"? If applications already exist, it will be closed instead so history is preserved.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: mediumBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) {
        return;
      }
      final wasClosed = await provider.deleteOpportunity(oppId);
      final error = provider.mutationError;

      if (!mounted) {
        return;
      }

      if (error != null) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(error)));
      } else {
        final user = authProvider.userModel;
        if (user != null) {
          await provider.loadOpportunities(user.uid);
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              wasClosed == true
                  ? 'Opportunity closed because applications already exist'
                  : 'Opportunity deleted',
            ),
          ),
        );
      }
    }
  }
}
