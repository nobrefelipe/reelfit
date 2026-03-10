import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/extract_controller.dart';
import '../../controllers/history_controller.dart';
import '../../core/atomic_state/result.dart';
import '../../core/global_atoms.dart';
import '../../core/ui/text.dart';
import '../../models/video_model.dart';
import '../auth/sign_in_sheet.dart';
import '../auth/widgets/profile_button.dart';
import '../auth/widgets/sign_in_button.dart';
import 'extract_sheet.dart';
import 'widgets/empty_state.dart';
import 'widgets/guest_counter_banner.dart';
import 'widgets/skeleton_list.dart';
import 'widgets/video_list.dart';

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
        context.go('/workout/${video.videoId}');
        extractController.reset();
      } else if (video.type == 'diet') {
        context.go('/diet/${video.videoId}');
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
          extractController.isGuest ? const SignInButton() : const ProfileButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (extractController.isGuest)
            guestBannerDismissed(
              (dismissed) => dismissed
                  ? const SizedBox.shrink()
                  : guestCount(
                      (count) => count > 0
                          ? GuestCounterBanner(
                              used: count,
                              onDismiss: () => guestBannerDismissed.emit(true),
                            )
                          : const SizedBox.shrink(),
                    ),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: history(
              loading: () => const SkeletonList(),
              empty: () => const EmptyState(),
              failure: (msg) => Center(child: UIKText.body(msg)),
              success: VideoList.new,
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
