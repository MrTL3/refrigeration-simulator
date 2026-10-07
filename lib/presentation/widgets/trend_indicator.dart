import 'package:flutter/material.dart';
import '../../domain/models/transient_metrics.dart';
import '../theme/scada_colors.dart';

/// Indicador visual compacto de tendencia temporal con símbolo y variación.
class TrendIndicator extends StatelessWidget {
  final MetricTrend trend;
  final String formattedDelta;

  const TrendIndicator({
    super.key,
    required this.trend,
    required this.formattedDelta,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (trend.direction) {
      case TrendDirection.rising:
        color = ScadaColors.warningAmber;
      case TrendDirection.falling:
        color = ScadaColors.infoBlue;
      case TrendDirection.steady:
        color = ScadaColors.runningGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trend.direction.symbol,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            formattedDelta,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
