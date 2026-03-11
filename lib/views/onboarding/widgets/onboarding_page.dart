import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reelfit/core/ui/_theme.dart';
import 'package:reelfit/core/ui/buttons/ui_kit_button.dart';
import 'package:reelfit/core/ui/text.dart';
import 'package:reelfit/views/onboarding/widgets/onboarding_dots.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.svgAsset,
    required this.title,
    required this.body,
    required this.total,
    required this.current,
    required this.isLast,
    required this.onNext,
  });

  final String svgAsset;
  final String title;
  final String body;
  final int total;
  final int current;
  final bool isLast;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SvgPicture.asset(svgAsset, height: 260),
              ),
            ),
            UIKText.pageTitle(title, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            UIKText.body(
              body,
              textAlign: TextAlign.center,
              color: Theme.of(context).onSurfaceColor.withAlpha(150),
            ),
            const SizedBox(height: 32),
            OnboardingDots(total: total, current: current),
            const SizedBox(height: 32),
            UIKButton.primary(
              label: isLast ? 'Get Started' : 'Next',
              onTap: onNext,
              fullWidth: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
