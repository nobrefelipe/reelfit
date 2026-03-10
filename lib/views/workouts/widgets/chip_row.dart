import 'package:flutter/material.dart';

import '../../../core/ui/_theme.dart';
import '../../../core/ui/text.dart';

class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.items, this.color});

  final List<String> items;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).onSurfaceColor).withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (color ?? Theme.of(context).onSurfaceColor).withAlpha(60),
                ),
              ),
              child: UIKText.small(item, color: color),
            ),
          )
          .toList(),
    );
  }
}
