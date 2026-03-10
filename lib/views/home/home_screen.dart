import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/extract_controller.dart';
import '../../controllers/history_controller.dart';
import '../../core/atomic_state/result.dart';
import '../../core/global_atoms.dart';
import '../../core/ui/buttons/ui_kit_button.dart';
import '../../core/ui/notifications/dialog/dialog.dart';
import '../../core/ui/text.dart';
import '../../data/auth_repository.dart';
import '../../models/video_model.dart';
import '../auth/sign_in_sheet.dart';
import 'extract_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    extractController.init();
    authState.addListener(_onAuthChanged);
    extractResult.addListener(_onExtractResult);
    historyController.load();
  }

  @override
  void dispose() {
    authState.removeListener(_onAuthChanged);
    extractResult.removeListener(_onExtractResult);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

  void _onExtractResult() {
    if (!mounted) return;
    final result = extractResult.value;
    if (result is Success<VideoModel>) {
      final video = result.value;
      if (video.type == 'workout') {
        context.push('/workout/${video.videoId}', extra: video);
        extractController.reset();
      } else if (video.type == 'diet') {
        context.push('/diet/${video.videoId}', extra: video);
        extractController.reset();
      }
    } else if (result is Failure<VideoModel> && result.message == 'guest_limit') {
      extractController.reset();
      SignInSheet.show(
        context,
        title: "You've used your 3 free extracts",
        subtitle: 'Sign in with Google to save unlimited workouts and track your progress.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: UIKText.h4('ReelFit'),
        actions: [
          extractController.isGuest ? const _SignInButton() : const _ProfileButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (extractController.isGuest)
            guestCount(
              (count) => count > 0 ? _GuestCounterBanner(used: count) : const SizedBox.shrink(),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: history(
              loading: () => const _SkeletonList(),
              empty: () => const _EmptyState(),
              failure: (msg) => Center(child: UIKText.body(msg)),
              success: _VideoList.new,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ExtractSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar buttons
// ---------------------------------------------------------------------------

class _SignInButton extends StatelessWidget {
  const _SignInButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: UIKButton.ghost.small(
        label: 'Sign in',
        fullWidth: false,
        onTap: () async => SignInSheet.show(
          context,
          title: 'Sign in to ReelFit',
          subtitle: 'Sync your history and unlock unlimited extracts.',
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () => ShowDialog(
        context,
        title: 'Sign out',
        content: 'Are you sure you want to sign out?',
        onConfirm: () => AuthRepository().signOut(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guest counter banner
// ---------------------------------------------------------------------------

class _GuestCounterBanner extends StatelessWidget {
  const _GuestCounterBanner({required this.used});

  final int used;

  @override
  Widget build(BuildContext context) {
    final color = used >= 3
        ? Colors.red
        : used >= 2
        ? Colors.amber.shade700
        : Theme.of(context).colorScheme.primary;
    return Container(
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          UIKText.small('$used/3 free extracts used', color: color),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              'Tap the + button and paste a YouTube Shorts URL to get started.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video list
// ---------------------------------------------------------------------------

class _VideoList extends StatelessWidget {
  const _VideoList(this.videos);

  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _VideoCard(video: videos[i]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

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
                    _TypeBadge(label: typeLabel, type: video.type),
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.type});

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
