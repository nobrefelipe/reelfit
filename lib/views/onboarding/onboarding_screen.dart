import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reelfit/core/atomic_state/atom.dart';
import 'package:reelfit/core/cache/local_cache.dart';
import 'package:reelfit/views/onboarding/widgets/onboarding_page.dart';

final _currentPage = Atom(0);

const _steps = [
  (
    svgAsset: 'assets/welcome.svg',
    title: 'Welcome to ReelFit',
    body: 'Turn any YouTube fitness Short into a structured, trackable workout',
  ),
  (
    svgAsset: 'assets/find.svg',
    title: 'Find a Short',
    body: 'Open YouTube, find any fitness Short, and copy its URL',
  ),
  (
    svgAsset: 'assets/extract.svg',
    title: 'We do the heavy lifting',
    body: "Paste the URL and we'll extract every exercise automatically",
  ),
  (
    svgAsset: 'assets/track.svg',
    title: 'Track your progress',
    body: 'Log your weights each session and watch your progress grow',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentPage.emit(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onNext(int index) async {
    final isLast = index == _steps.length - 1;
    if (isLast) {
      await AppCache().setHasSeenOnboarding(true);
      if (mounted) context.go('/');
      return;
    }
    _currentPage.emit(index + 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage((page) => PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _steps.length,
        itemBuilder: (_, index) {
          final step = _steps[index];
          return OnboardingPage(
            svgAsset: step.svgAsset,
            title: step.title,
            body: step.body,
            total: _steps.length,
            current: page,
            isLast: index == _steps.length - 1,
            onNext: () => _onNext(index),
          );
        },
      )),
    );
  }
}
