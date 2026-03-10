import 'package:flutter/material.dart';

import '../../../core/ui/_theme.dart';
import '../../../core/ui/text.dart';

class MuscleChip extends StatelessWidget {
  const MuscleChip({super.key, required this.muscle});

  final String muscle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.primary.withAlpha(60)),
      ),
      child: UIKText.small(muscle, color: DesignTokens.primary),
    );
  }
}
