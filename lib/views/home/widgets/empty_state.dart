import 'package:flutter/material.dart';

import '../../../core/ui/text.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            UIKText.h5('Nothing here yet'),
            const SizedBox(height: 8),
            UIKText.body(
              'Paste a YouTube Shorts URL to get started.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
