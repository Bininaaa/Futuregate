import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import 'innovation_hub_theme.dart';

enum IdeasHubSegment { discover, mine }

class MyIdeasToggle extends StatelessWidget {
  final IdeasHubSegment selected;
  final ValueChanged<IdeasHubSegment> onChanged;

  const MyIdeasToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: InnovationHubPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InnovationHubPalette.border),
        boxShadow: InnovationHubPalette.softShadow(0.04),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: AppLocalizations.of(context)!.uiDiscover,
              selected: selected == IdeasHubSegment.discover,
              onTap: () => onChanged(IdeasHubSegment.discover),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: AppLocalizations.of(context)!.uiMyIdeas,
              selected: selected == IdeasHubSegment.mine,
              onTap: () => onChanged(IdeasHubSegment.mine),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected ? InnovationHubPalette.primaryGradient : null,
        color: selected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: InnovationHubTypography.label(
                color: selected
                    ? Colors.white
                    : InnovationHubPalette.textSecondary,
                size: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
