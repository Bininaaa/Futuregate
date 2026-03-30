import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/scholarship_provider.dart';
import 'scholarship_detail_screen.dart';

class ScholarshipsScreen extends StatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      context.read<ScholarshipProvider>().fetchScholarships();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScholarshipProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Scholarships')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.scholarships.isEmpty
              ? const Center(child: Text('No scholarships found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.scholarships.length,
                  itemBuilder: (context, index) {
                    final scholarship = provider.scholarships[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.workspace_premium,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        title: Text(
                          scholarship.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${scholarship.provider} \u2022 Deadline: ${scholarship.deadline}',
                          ),
                        ),
                        trailing: Text(
                          '${scholarship.amount} DA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScholarshipDetailScreen(
                                scholarship: scholarship,
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
