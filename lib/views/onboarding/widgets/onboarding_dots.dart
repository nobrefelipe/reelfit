import 'package:flutter/material.dart';
import 'package:reelfit/core/ui/_theme.dart';

class OnboardingDots extends StatelessWidget {
  const OnboardingDots({super.key, required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: isActive ? 16 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? DesignTokens.primary
                  : Theme.of(context).onSurfaceColor.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
