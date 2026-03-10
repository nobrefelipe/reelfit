import 'package:flutter/material.dart';

import '../../../core/ui/text.dart';

class GuestCounterBanner extends StatelessWidget {
  const GuestCounterBanner({super.key, required this.used, required this.onDismiss});

  final int used;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = used >= 3
        ? Colors.red
        : used >= 2
        ? Colors.amber.shade700
        : Theme.of(context).colorScheme.primary;
    return Container(
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: UIKText.small('$used/3 free extracts used', color: color)),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: color),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
