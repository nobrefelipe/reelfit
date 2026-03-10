import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/extract_controller.dart';
import '../../controllers/history_controller.dart';
import '../../core/atomic_state/result.dart';
import '../../core/ui/buttons/ui_kit_button.dart';
import '../../core/ui/notifications/snackbar/snackbar.dart';
import '../../core/ui/text.dart';
import '../../models/video_model.dart';
import '../auth/sign_in_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    extractController.init();
    historyController.load();
    extractResult.addListener(_onExtractResult);
  }

  @override
  void dispose() {
    extractResult.removeListener(_onExtractResult);
    _tabs.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onExtractResult() {
    if (!mounted) return;
    final result = extractResult.value;

    if (result is Success<VideoModel>) {
      final video = result.value;
      extractController.reset();
      if (video.type == 'workout') {
        context.push('/workout/${video.videoId}');
      } else if (video.type == 'diet') {
        context.push('/diet/${video.videoId}');
      } else {
        UIKShowSnackBar(context, message: 'Unsupported video type.', type: UIKSnackBarType.error);
      }
    } else if (result is Failure<VideoModel>) {
      final msg = result.message;
      if (msg == 'guest_limit') {
        extractController.reset();
        SignInSheet.show(
          context,
          title: "You've used your 3 free extracts",
          subtitle: 'Sign in with Google to save unlimited workouts and track your progress.',
        );
      } else {
        extractController.reset();
        UIKShowSnackBar(context, message: msg, type: UIKSnackBarType.error);
      }
    }
  }

  void _onExtract() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    extractController.extract(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: UIKText.h4('ReelFit'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Extract'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ExtractTab(urlController: _urlController, onExtract: _onExtract),
          const _HistoryTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extract tab
// ---------------------------------------------------------------------------

class _ExtractTab extends StatelessWidget {
  const _ExtractTab({required this.urlController, required this.onExtract});

  final TextEditingController urlController;
  final VoidCallback onExtract;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Guest counter — visible only when guest
          guestCount((count) {
            if (!extractController.isGuest) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GuestCounterChip(used: count),
            );
          }),
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: 'Paste YouTube Shorts URL',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => onExtract(),
          ),
          const SizedBox(height: 12),
          // Extract button — loading state mirrors atom
          extractResult(
            success: (_) => UIKButton.primary(label: 'Extract', onTap: () async => onExtract()),
            loading: () => UIKButton.primary(label: 'Extracting…', onTap: null, isLoading: true),
            failure: (_) => UIKButton.primary(label: 'Extract', onTap: () async => onExtract()),
            idle: () => UIKButton.primary(label: 'Extract', onTap: () async => onExtract()),
            empty: () => UIKButton.primary(label: 'Extract', onTap: () async => onExtract()),
          ),
        ],
      ),
    );
  }
}

class _GuestCounterChip extends StatelessWidget {
  const _GuestCounterChip({required this.used});

  final int used;

  @override
  Widget build(BuildContext context) {
    final color = used >= 3
        ? Colors.red
        : used == 2
            ? Colors.amber
            : Theme.of(context).colorScheme.primary;
    return Chip(
      label: UIKText.small('$used/3 free extracts used', color: color),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}

// ---------------------------------------------------------------------------
// History tab
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return history(
      loading: () => const Center(child: CircularProgressIndicator()),
      empty: () => const _EmptyHistory(),
      failure: (msg) => Center(child: UIKText.body(msg)),
      success: (videos) => _HistoryList(videos: videos),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            UIKText.h5('No history yet'),
            const SizedBox(height: 8),
            UIKText.body(
              'Paste a YouTube Shorts URL in the Extract tab to get started.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.videos});

  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (historyController.isGuest) const _GuestBanner(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _HistoryCard(video: videos[i]),
          ),
        ),
      ],
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: UIKText.small(
              'Sign in to sync your history across devices and unlock unlimited extracts.',
            ),
          ),
          const SizedBox(width: 8),
          UIKButton.ghost.small(
            label: 'Sign in',
            fullWidth: false,
            onTap: () async => SignInSheet.show(
              context,
              title: 'Sync your history',
              subtitle:
                  'Sign in with Google to unlock unlimited extracts and sync your history across devices.',
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.video});

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
    final label = video.type == 'workout'
        ? 'Workout'
        : video.type == 'diet'
            ? 'Recipe'
            : 'Video';
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            video.thumbnailUrl,
            width: 64,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.play_circle_outline, size: 48),
          ),
        ),
        title: UIKText.body(label),
        subtitle: UIKText.small(video.url, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigate(context),
      ),
    );
  }
}
