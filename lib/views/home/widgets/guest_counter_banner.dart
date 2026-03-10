import 'package:flutter/material.dart';

import '../../../core/ui/text.dart';

class GuestCounterBanner extends StatelessWidget {
  const GuestCounterBanner({super.key, required this.used});

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
