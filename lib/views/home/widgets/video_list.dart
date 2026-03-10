import 'package:flutter/material.dart';

import '../../../models/video_model.dart';
import 'video_card.dart';

class VideoList extends StatelessWidget {
  const VideoList(this.videos, {super.key});

  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => VideoCard(video: videos[i]),
    );
  }
}
