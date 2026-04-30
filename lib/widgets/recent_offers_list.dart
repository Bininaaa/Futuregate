import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

class RecentOffersList extends StatelessWidget {
  final List<Map<String, dynamic>> offers;

  const RecentOffersList({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.uiRecentOffers,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...offers.map((offer) {
              return ListTile(
                leading: const Icon(Icons.work),
                title: Text(offer['title'] ?? l10n.uiUntitledOffer),
                subtitle: Text(offer['companyName'] ?? l10n.uiUnknownCompany),
              );
            }),
          ],
        ),
      ),
    );
  }
}
