import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../shared/theme/app_theme.dart';

class LambdaGauge extends StatelessWidget {
  final double lambda;

  const LambdaGauge({super.key, required this.lambda});

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 2,
          interval: 0.5,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.15,
            thicknessUnit: GaugeSizeUnit.factor,
            color: AppTheme.gaugeIdle,
          ),
          majorTickStyle: const MajorTickStyle(color: Colors.white54),
          axisLabelStyle: const GaugeTextStyle(color: Colors.white70),
          pointers: [
            NeedlePointer(
              value: lambda.clamp(0, 2),
              needleColor: AppTheme.accent,
              knobStyle: const KnobStyle(color: AppTheme.accent),
              animationType: AnimationType.linear,
              enableAnimation: true,
              animationDuration: 100,
            ),
          ],
          annotations: [
            GaugeAnnotation(
              positionFactor: 0.6,
              angle: 90,
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lambda.toStringAsFixed(2),
                    style: AppTheme.digitalDisplay(fontSize: 24),
                  ),
                  const Text(
                    'λ',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
