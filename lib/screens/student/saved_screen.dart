import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/saved_opportunity_provider.dart';

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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          saved.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${saved.companyName} \u2022 ${saved.location}\nType: ${saved.type} \u2022 Deadline: ${saved.deadline}',
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_remove,
                              color: Colors.red),
                          onPressed: () async {
                            final authProvider = context.read<AuthProvider>();
                            final scaffoldMessenger =
                                ScaffoldMessenger.of(context);
                            final uid = authProvider.userModel?.uid ?? '';
                            await provider.unsaveOpportunity(saved.id, uid);
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                  content: Text('Removed from saved')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
