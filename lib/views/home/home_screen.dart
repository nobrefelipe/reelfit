import 'package:flutter/material.dart';
import 'package:reelfit/core/extensions.dart';

import '../../controllers/extract_controller.dart';
import '../../controllers/history_controller.dart';
import '../../core/global_atoms.dart';
import '../../core/ui/text.dart';
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
    historyController.load();
  }

  @override
  void dispose() {
    authState.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => setState(() {});

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ExtractSheet.show(context),
        label: UIKText.body('Extract', color: Colors.black),
        icon: const Icon(Icons.add, color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (extractController.isGuest)
            _SignInBannerInline(
              onTap: () => SignInSheet.show(
                context,
                title: 'Sync & unlock unlimited extracts',
                subtitle: 'Sign in to save your history across devices and extract unlimited workouts.',
              ),
            ).marginOnly(bottom: 20),
          if (extractController.isGuest)
            guestCount(
              (count) => count > 0 ? GuestCounterBanner(used: count) : const SizedBox.shrink(),
            ),
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
    );
  }
}

class _SignInBannerInline extends StatelessWidget {
  const _SignInBannerInline({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.workspace_premium, color: primary, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UIKText.small(
                    'Sync & unlock unlimited extracts',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: 2),
                  UIKText.small(
                    'Sign in to save your history across devices and extract unlimited workouts.',
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
