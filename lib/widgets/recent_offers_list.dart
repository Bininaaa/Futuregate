import 'package:flutter/material.dart';

class RecentOffersList extends StatelessWidget {
  final List<Map<String, dynamic>> offers;

  const RecentOffersList({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Offers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...offers.map((offer) {
              return ListTile(
                leading: const Icon(Icons.work),
                title: Text(offer['title'] ?? 'Untitled offer'),
                subtitle: Text(offer['companyName'] ?? 'Unknown company'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
