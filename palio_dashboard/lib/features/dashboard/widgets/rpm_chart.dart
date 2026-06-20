import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class RpmChart extends StatelessWidget {
  final List<FlSpot> spots;

  const RpmChart({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.length < 2) {
      return const Center(
        child: Text(
          'Coletando dados de RPM...',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    final minX = spots.first.x;
    final maxX = spots.last.x;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: 8000,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.accent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
