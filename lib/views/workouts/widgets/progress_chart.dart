import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/_theme.dart';
import '../../../core/ui/text.dart';
import '../../../models/progress_model.dart';

class ProgressChart extends StatelessWidget {
  const ProgressChart(this.entries, {super.key});

  final List<ProgressModel> entries;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _dayLabel(DateTime dt) => _dayNames[dt.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final primary = DesignTokens.primary;
    final surface = Theme.of(context).surfaceColor;
    final onSurface = Theme.of(context).onSurfaceColor;
    final latest = entries.last;

    // Single entry: duplicate point to draw a visible flat line
    final spots = entries.length == 1
        ? [FlSpot(0, entries.first.value), FlSpot(1, entries.first.value)]
        : [for (int i = 0; i < entries.length; i++) FlSpot(i.toDouble(), entries[i].value)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UIKText.h5('My Progress'),
            UIKText.h5(
              '${latest.value % 1 == 0 ? latest.value.toInt() : latest.value}${latest.unit}',
              color: primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(DesignTokens.buttonBorderRadius),
            boxShadow: DesignTokens.defaultShadow,
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(fontSize: 10, color: onSurface.withAlpha(120)),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      // For single entry we show 2 spots — only label index 0
                      if (entries.length == 1 && value == 1) return const SizedBox.shrink();
                      final idx = value.round().clamp(0, entries.length - 1);
                      return Text(
                        _dayLabel(entries[idx].loggedAt),
                        style: TextStyle(fontSize: 10, color: onSurface.withAlpha(120)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: entries.length > 2,
                  color: primary,
                  barWidth: 2.5,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primary.withAlpha(100), primary.withAlpha(0)],
                    ),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 4,
                      color: primary,
                      strokeWidth: 2,
                      strokeColor: surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
