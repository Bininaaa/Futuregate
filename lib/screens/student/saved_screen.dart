import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../widgets/opportunity_type_badge.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        context.read<SavedOpportunityProvider>().fetchSavedOpportunities(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavedOpportunityProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Opportunities')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.savedOpportunities.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No saved opportunities yet',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.savedOpportunities.length,
                  itemBuilder: (context, index) {
                    final saved = provider.savedOpportunities[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                                    saved.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                OpportunityTypeBadge(type: saved.type),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${saved.companyName} \u2022 ${saved.location}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'Deadline: ${saved.deadline}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    final authProvider =
                                        context.read<AuthProvider>();
                                    final scaffoldMessenger =
                                        ScaffoldMessenger.of(context);
                                    final uid =
                                        authProvider.userModel?.uid ?? '';
                                    await provider.unsaveOpportunity(
                                        saved.id, uid);
                                    if (!mounted) return;
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                          content: Text('Removed from saved')),
                                    );
                                  },
                                  child: const Icon(Icons.bookmark_remove,
                                      color: Colors.red, size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
