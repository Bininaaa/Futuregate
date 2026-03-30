import 'package:flutter/material.dart';
import '../../models/scholarship_model.dart';

class ScholarshipDetailScreen extends StatelessWidget {
  final ScholarshipModel scholarship;

  const ScholarshipDetailScreen({super.key, required this.scholarship});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scholarship Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            scholarship.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.business, 'Provider', scholarship.provider),
          _infoRow(Icons.attach_money, 'Amount', '${scholarship.amount} DA'),
          _infoRow(Icons.calendar_today, 'Deadline', scholarship.deadline),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(scholarship.description),
          const SizedBox(height: 20),
          const Text(
            'Eligibility',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(scholarship.eligibility),
          if (scholarship.link.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Link',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              scholarship.link,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ],
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
