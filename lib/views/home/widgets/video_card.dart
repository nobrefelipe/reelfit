import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/text.dart';
import '../../../models/video_model.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.video});

  final VideoModel video;

  void _navigate(BuildContext context) {
    if (video.type == 'workout') {
      context.push('/workout/${video.videoId}');
    } else if (video.type == 'diet') {
      context.push('/diet/${video.videoId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = video.type == 'workout'
        ? 'Workout'
        : video.type == 'diet'
        ? 'Recipe'
        : 'Video';
    final d = video.createdAt.toLocal();
    final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigate(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  video.thumbnailUrl,
                  width: 72,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 54,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.play_circle_outline, size: 32, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypeBadge(label: typeLabel, type: video.type),
                    const SizedBox(height: 4),
                    UIKText.small(dateStr, color: Colors.grey),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.label, required this.type});

  final String label;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = type == 'workout'
        ? Colors.blue
        : type == 'diet'
        ? Colors.green
        : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: UIKText.small(label, color: color),
    );
  }
}
