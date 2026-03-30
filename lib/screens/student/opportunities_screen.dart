import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/opportunity_provider.dart';
import 'opportunity_detail_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      context.read<OpportunityProvider>().fetchOpportunities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.opportunities.isEmpty
              ? const Center(child: Text('No open opportunities found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.opportunities.length,
                  itemBuilder: (context, index) {
                    final opportunity = provider.opportunities[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          opportunity.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${opportunity.companyName} \u2022 ${opportunity.location}',
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            opportunity.type,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OpportunityDetailScreen(
                                opportunity: opportunity,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
