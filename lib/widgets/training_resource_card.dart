import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

import '../models/training_model.dart';

class TrainingResourceCard extends StatelessWidget {
  final TrainingModel training;
  final bool isSaved;
  final bool isSaveBusy;
  final VoidCallback onOpen;
  final VoidCallback? onToggleSaved;

  const TrainingResourceCard({
    super.key,
    required this.training,
    required this.isSaved,
    required this.isSaveBusy,
    required this.onOpen,
    this.onToggleSaved,
  });

  Color _typeColor(String type) {
    switch (type) {
      case 'book':
        return Colors.blue;
      case 'course':
        return Colors.green;
      case 'video':
        return Colors.red;
      case 'file':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  Widget _buildChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final isVideo = training.type == 'video';
    final width = isVideo ? 112.0 : 70.0;
    final height = isVideo ? 72.0 : 100.0;
    final placeholderIcon = isVideo
        ? Icons.play_circle_outline_rounded
        : Icons.menu_book_rounded;

    if (training.thumbnail.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(placeholderIcon, size: isVideo ? 36 : 34),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: training.thumbnail,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitleText = training.authors.isNotEmpty
        ? training.authors.join(', ')
        : training.provider;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: training.type.toUpperCase(),
                        color: _typeColor(training.type),
                      ),
                      if (training.isFeatured)
                        _buildChip(
                          label: AppLocalizations.of(context)!.uiFeatured.toUpperCase(),
                          color: Colors.amber.shade800,
                          icon: Icons.star_rounded,
                        ),
                      if (training.level.trim().isNotEmpty)
                        _buildChip(label: training.level, color: Colors.orange),
                      if (training.domain.trim().isNotEmpty)
                        _buildChip(
                          label: training.domain,
                          color: Colors.deepPurple,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          training.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (onToggleSaved != null)
                        isSaveBusy
                            ? const Padding(
                                padding: EdgeInsets.only(left: 8, top: 2),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: isSaved
                                    ? 'Remove from saved'
                                    : 'Save resource',
                                onPressed: onToggleSaved,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  color: isSaved
                                      ? const Color(0xFFFF8C00)
                                      : Colors.grey.shade600,
                                ),
                              ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleText,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  if (training.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      training.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (training.duration.trim().isNotEmpty)
                        Expanded(
                          child: Text(
                            training.duration,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(AppLocalizations.of(context)!.uiOpen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
