import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_type_badge.dart';
import 'opportunity_detail_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  /// Optional: pre-select a filter when navigating from dashboard categories.
  final String? initialFilter;

  const OpportunitiesScreen({super.key, this.initialFilter});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color bgColor = Color(0xFFF6F5FB);
  static const Color textDark = Color(0xFF1E1E2D);
  static const Color textMedium = Color(0xFF6E6E82);
  static const Color textLight = Color(0xFF9E9EB8);

  /// null means "All"
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    Future.microtask(() {
      if (!mounted) return;
      context.read<OpportunityProvider>().fetchOpportunities();
    });
  }

  List<OpportunityModel> _filtered(List<OpportunityModel> all) {
    if (_activeFilter == null) return all;
    return all.where((o) => o.type == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Opportunities',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(label: 'All', value: null),
                  const SizedBox(width: 8),
                  ...OpportunityType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: OpportunityType.label(type),
                          value: type,
                          icon: OpportunityType.icon(type),
                          activeColor: OpportunityType.color(type),
                        ),
                      )),
                ],
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryPurple))
                : _buildList(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    IconData? icon,
    Color activeColor = primaryPurple,
  }) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: isActive ? activeColor : Colors.grey.shade500),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(OpportunityProvider provider) {
    final items = _filtered(provider.opportunities);

    if (items.isEmpty) {
      final filterLabel = _activeFilter != null
          ? OpportunityType.label(_activeFilter!)
          : null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeFilter != null
                  ? OpportunityType.icon(_activeFilter!)
                  : Icons.work_off_outlined,
              size: 56,
              color: textLight,
            ),
            const SizedBox(height: 14),
            Text(
              filterLabel != null
                  ? 'No $filterLabel opportunities found'
                  : 'No open opportunities found',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for new postings',
              style: GoogleFonts.poppins(fontSize: 12, color: textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final opp = items[index];
        return _buildOpportunityCard(opp);
      },
    );
  }

  Widget _buildOpportunityCard(OpportunityModel opp) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpportunityDetailScreen(opportunity: opp),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    opp.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                OpportunityTypeBadge(type: opp.type),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              opp.companyName,
              style: GoogleFonts.poppins(fontSize: 13, color: textMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: textLight),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    opp.location,
                    style: GoogleFonts.poppins(fontSize: 12, color: textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (opp.deadline.isNotEmpty) ...[
                  Icon(Icons.schedule, size: 14, color: textLight),
                  const SizedBox(width: 3),
                  Text(
                    opp.deadline,
                    style: GoogleFonts.poppins(fontSize: 12, color: textLight),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
